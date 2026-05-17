import { Prisma } from '../../../../generated/prisma/client';
import prisma from '../../../config/prisma';
import { embedText } from './chat.provider';
import { RagChunk, RetrievalResult } from './chat.types';

const SIMILARITY_THRESHOLD = 0.45;

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

async function queryChunks(
  embeddingLiteral: Prisma.Sql,
  audienceFilter: Prisma.Sql,
  languageFilter: Prisma.Sql,
  topK: number
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
      WHERE similarity > ${SIMILARITY_THRESHOLD}
      ORDER BY similarity DESC
      LIMIT ${topK}
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
    topK
  );

  // Fallback: drop language filter if too few results
  if (language && results.length < 2) {
    console.warn(
      `Too few results with language='${language}' (got ${results.length}), retrying without it`
    );

    const fallbackResults = await queryChunks(
      embeddingLiteral,
      audienceFilter,
      Prisma.empty,  // no language filter
      topK
    );

    return {
      chunks: fallbackResults,
      totalFound: fallbackResults.length,
    };
  }

  return {
    chunks: results,
    totalFound: results.length,
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