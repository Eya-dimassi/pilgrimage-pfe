import prisma from '../../../config/prisma';
import { embedText } from './chat.provider';
import { RagChunk, RetrievalResult } from './chat.types';

interface RetrievalOptions {
  language?: 'ar' | 'fr' | 'en';
  audience?: 'pelerin' | 'famille';
  topK?: number;
}

export async function retrieveRelevantChunks(
  query: string,
  options: RetrievalOptions = {}
): Promise<RetrievalResult> {
  const { language, audience, topK = 5 } = options;

  const queryEmbedding = await embedText(query);
  const embeddingString = `[${queryEmbedding.join(',')}]`;

  const audienceFilter = audience ? `AND '${audience}' = ANY(audience)` : '';
  const languageFilter = language ? `AND language = '${language}'` : '';

  const results = await prisma.$queryRawUnsafe<RagChunk[]>(`
    SELECT
      id,
      text,
      source,
      section,
      audience,
      language,
      tags,
      1 - (embedding <=> '${embeddingString}'::vector) AS similarity
    FROM "RagChunk"
    WHERE 1=1
      ${audienceFilter}
      ${languageFilter}
    ORDER BY embedding <=> '${embeddingString}'::vector
    LIMIT ${topK}
  `);

  if (language && results.length < 2) {
    console.warn('Too few results with language filter, retrying without it');

    const fallbackResults = await prisma.$queryRawUnsafe<RagChunk[]>(`
      SELECT
        id,
        text,
        source,
        section,
        audience,
        language,
        tags,
        1 - (embedding <=> '${embeddingString}'::vector) AS similarity
      FROM "RagChunk"
      WHERE 1=1
        ${audienceFilter}
      ORDER BY embedding <=> '${embeddingString}'::vector
      LIMIT ${topK}
    `);

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
  if (chunks.length === 0) {
    return '';
  }

  return chunks
    .map((chunk, index) => {
      const source = chunk.source ?? 'source inconnue';
      const section = chunk.section ? ` - ${chunk.section}` : '';
      return `[${index + 1}] (${source}${section})\n${chunk.text}`;
    })
    .join('\n\n');
}
