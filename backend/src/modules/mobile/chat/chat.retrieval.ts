import { Prisma } from '../../../../generated/prisma/client';
import prisma from '../../../config/prisma';
import { embedText } from './chat.provider';
import { RagChunk, RetrievalResult } from './chat.types';

const SIMILARITY_THRESHOLD = 0.42;
const RELAXED_SIMILARITY_THRESHOLD = 0.32;
const MIN_USEFUL_RESULTS = 3;
const KEYWORD_TOP_K = 4;

interface RetrievalOptions {
  language?: 'ar' | 'fr' | 'en';
  audience?: 'pelerin' | 'famille' | 'guide';
  topK?: number;
}

function buildEmbeddingLiteral(embedding: number[]): Prisma.Sql {
  // Prisma.raw bypasses parameterization — safe here because this value
  // comes from our own embedding model, never from user input
  return Prisma.raw(`'[${embedding.join(',')}]'::vector`);
}

function buildAudienceFilter(audience?: string): Prisma.Sql {
  if (!audience) return Prisma.empty;

  // Guides see guide-tagged AND pelerin-tagged chunks
  const targets = audience === 'guide' ? ['guide', 'pelerin'] : [audience];
  const arrayLiteral = `{${targets.join(',')}}`;

  // audience && ARRAY[...] = overlap operator (any match)
  return Prisma.sql`AND audience && ${arrayLiteral}::text[]`;
}

function getKeywordTerms(query: string): string[] {
  const stopWords = new Set([
    'ما',
    'هي',
    'هو',
    'في',
    'من',
    'عن',
    'على',
    'the',
    'and',
    'for',
    'what',
    'are',
    'is',
    'les',
    'des',
    'une',
    'dans',
    'pour',
    'quelles',
  ]);

  return [...new Set(
    query
      .toLowerCase()
      .match(/[\p{L}\p{N}]{3,}/gu)
      ?.filter((term) => !stopWords.has(term)) ?? []
  )].slice(0, 5);
}

function mergeChunks(primary: RagChunk[], secondary: RagChunk[], topK: number): RagChunk[] {
  const seen = new Set<string>();
  const merged: RagChunk[] = [];

  for (const chunk of [...secondary, ...primary]) {
    if (seen.has(chunk.id)) continue;
    seen.add(chunk.id);
    merged.push(chunk);
    if (merged.length >= topK) break;
  }

  return merged;
}

async function queryChunks(
  embeddingLiteral: Prisma.Sql,
  audienceFilter: Prisma.Sql,
  languageFilter: Prisma.Sql,
  topK: number,
  similarityThreshold: number
): Promise<RagChunk[]> {
  return prisma.$queryRaw<RagChunk[]>(
    Prisma.sql`
      SELECT *
      FROM (
        SELECT
          id, text, source, section, audience, language, tags,
          1 - (embedding <=> ${embeddingLiteral}) AS similarity
        FROM "RagChunk"
        WHERE 1=1
          ${audienceFilter}
          ${languageFilter}
      ) ranked
      WHERE similarity > ${similarityThreshold}
      ORDER BY similarity DESC
      LIMIT ${topK}
    `
  );
}

async function queryKeywordChunks(
  query: string,
  audienceFilter: Prisma.Sql,
  languageFilter: Prisma.Sql,
  topK: number
): Promise<RagChunk[]> {
  const terms = getKeywordTerms(query);
  if (terms.length === 0) return [];

  const keywordConditions = terms.map((term) =>
    Prisma.sql`(text ILIKE ${`%${term}%`} OR section ILIKE ${`%${term}%`})`
  );

  return prisma.$queryRaw<RagChunk[]>(
    Prisma.sql`
      SELECT
        id, text, source, section, audience, language, tags,
        1::float AS similarity
      FROM "RagChunk"
      WHERE 1=1
        ${audienceFilter}
        ${languageFilter}
        AND (${Prisma.join(keywordConditions, ' OR ')})
      ORDER BY
        CASE WHEN section ILIKE ${`%${terms.join('%')}%`} THEN 0 ELSE 1 END,
        length(text) ASC
      LIMIT ${Math.min(topK, KEYWORD_TOP_K)}
    `
  );
}

export async function retrieveRelevantChunks(
  query: string,
  options: RetrievalOptions = {}
): Promise<RetrievalResult> {
  const { language, audience, topK = 5 } = options;

  const queryEmbedding = await embedText(query);
  const embeddingLiteral = buildEmbeddingLiteral(queryEmbedding);
  const audienceFilter = buildAudienceFilter(audience);
  const languageFilter = language
    ? Prisma.sql`AND language = ${language}`
    : Prisma.empty;

  const results = await queryChunks(
    embeddingLiteral,
    audienceFilter,
    languageFilter,
    topK,
    SIMILARITY_THRESHOLD
  );
  const keywordResults = await queryKeywordChunks(
    query,
    audienceFilter,
    languageFilter,
    topK
  );
  const initialResults = mergeChunks(results, keywordResults, topK);

  if (initialResults.length >= MIN_USEFUL_RESULTS) {
    return {
      chunks: initialResults,
      totalFound: initialResults.length,
    };
  }

  const relaxedResults = await queryChunks(
    embeddingLiteral,
    audienceFilter,
    languageFilter,
    topK,
    RELAXED_SIMILARITY_THRESHOLD
  );

  const relaxedMergedResults = mergeChunks(relaxedResults, keywordResults, topK);

  if (relaxedMergedResults.length >= MIN_USEFUL_RESULTS) {
    return {
      chunks: relaxedMergedResults,
      totalFound: relaxedMergedResults.length,
    };
  }

  // Fallback: drop language filter if too few results. This helps Arabic or
  // English questions find French source chunks when translated equivalents
  // are not available in the knowledge base.
  if (language && initialResults.length < MIN_USEFUL_RESULTS) {
    console.warn(
      `Too few results with language='${language}' (got ${results.length}), retrying without it`
    );

    const fallbackResults = await queryChunks(
      embeddingLiteral,
      audienceFilter,
      Prisma.empty,  // no language filter
      topK,
      RELAXED_SIMILARITY_THRESHOLD
    );
    const fallbackKeywordResults = await queryKeywordChunks(
      query,
      audienceFilter,
      Prisma.empty,
      topK
    );
    const fallbackMergedResults = mergeChunks(
      fallbackResults,
      fallbackKeywordResults,
      topK
    );

    const bestResults =
      fallbackMergedResults.length > relaxedMergedResults.length
        ? fallbackMergedResults
        : relaxedMergedResults;

    return {
      chunks: bestResults,
      totalFound: bestResults.length,
    };
  }

  return {
    chunks: relaxedMergedResults.length > initialResults.length
      ? relaxedMergedResults
      : initialResults,
    totalFound: Math.max(relaxedMergedResults.length, initialResults.length),
  };
}

export function formatChunksAsContext(chunks: RagChunk[]): string {
  if (chunks.length === 0) return '';

  // Similarity scores are logged here for debugging but intentionally
  // excluded from the returned string — they add noise to the LLM prompt
  chunks.forEach((chunk, i) => {
    const score = chunk.similarity?.toFixed(3) ?? 'n/a';
    console.debug(`[RAG] chunk ${i + 1} score=${score} source=${chunk.source}`);
  });

  return chunks
    .map((chunk, index) => {
      const source = chunk.source ?? 'source inconnue';
      const section = chunk.section ? ` - ${chunk.section}` : '';
      return `[${index + 1}] (${source}${section})\n${chunk.text}`;
    })
    .join('\n\n');
}
