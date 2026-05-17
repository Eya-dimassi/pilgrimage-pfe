import fs from 'fs/promises';
import path from 'path';
import { randomUUID } from 'crypto';
const { PDFParse } = require('pdf-parse') as {
  PDFParse: new (options: { data: Uint8Array }) => { getText(): Promise<{ text: string; numpages: number }> }
};
import prisma from '../../../../config/prisma';
import { embedText } from '../chat.provider';
import { Prisma } from '../../../../../generated/prisma/client';

type Language = 'ar' | 'fr' | 'en';
type Audience = 'pelerin' | 'famille' | 'guide';

interface ChunkRecord {
  text: string;
  source: string;
  section?: string;
  audience: Audience[];
  language: Language;
  tags: string[];
  documentId?: string;
}

interface MarkdownMetadata {
  title?: string;
  language: Language;
  audience: Audience[];
  tags: string[];
}

interface FaqEntry {
  id?: string;
  language?: Language;
  audience?: Audience[];
  tags?: string[];
  question: string;
  answer: string;
}

const chatDir = path.resolve(__dirname, '..');
const rawDir = path.join(chatDir, 'data', 'raw');
const processedDir = path.join(chatDir, 'data', 'processed');
const processedChunksPath = path.join(processedDir, 'chunks.json');

// mxbai-embed-large hard limit is 512 tokens.
// Arabic is dense (~2 chars/token), so 800 chars ≈ 400 tokens — safe margin.
// French/English are lighter (~4 chars/token) so 800 chars ≈ 200 tokens — fine.
const MAX_CHARS = 350;
const OVERLAP_CHARS = 60;

function normalizeWhitespace(value: string): string {
  return value
    .replace(/\r\n/g, '\n')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function toLanguage(value: string | undefined, fallback: Language = 'fr'): Language {
  return value === 'ar' || value === 'en' || value === 'fr' ? value : fallback;
}

function getLanguageFromFilename(filePath: string, fallback: Language = 'fr'): Language {
  const langMatch = filePath.match(/-(ar|fr|en)\./i);
  return toLanguage(langMatch?.[1]?.toLowerCase(), fallback);
}

function toAudience(values: string[] | undefined): Audience[] {
  const allowed = new Set<Audience>(['pelerin', 'famille', 'guide']); // ✅ includes guide
  const cleaned = (values ?? []).filter((v): v is Audience => allowed.has(v as Audience));
  return cleaned.length > 0 ? cleaned : ['pelerin'];
}

// ✅ language-aware labels so Arabic FAQ entries don't get French headers
function getFaqLabels(language: Language): { q: string; a: string } {
  switch (language) {
    case 'ar': return { q: 'سؤال', a: 'جواب' };
    case 'en': return { q: 'Question', a: 'Answer' };
    default:   return { q: 'Question', a: 'Réponse' };
  }
}

function parseFrontmatter(content: string): { metadata: MarkdownMetadata; body: string } {
  const defaultMetadata: MarkdownMetadata = {
    language: 'fr',
    audience: ['pelerin'],
    tags: [],
  };

  if (!content.startsWith('---\n')) {
    return { metadata: defaultMetadata, body: normalizeWhitespace(content) };
  }

  const endIndex = content.indexOf('\n---\n', 4);
  if (endIndex === -1) {
    return { metadata: defaultMetadata, body: normalizeWhitespace(content) };
  }

  const rawFrontmatter = content.slice(4, endIndex);
  const body = content.slice(endIndex + 5);
  const lines = rawFrontmatter.split('\n');
  const metadata: MarkdownMetadata = { ...defaultMetadata };
  let currentListKey: 'audience' | 'tags' | null = null;

  for (const rawLine of lines) {
    const line = rawLine.trimEnd();
    if (!line.trim()) continue;

    const listMatch = line.match(/^\s*-\s+"?([^"]+)"?\s*$/);
    if (listMatch && currentListKey) {
      if (currentListKey === 'audience') {
        metadata.audience = [...metadata.audience, listMatch[1] as Audience];
      } else {
        metadata.tags = [...metadata.tags, listMatch[1]];
      }
      continue;
    }

    currentListKey = null;
    const keyValueMatch = line.match(/^([A-Za-z_]+):\s*(.*)$/);
    if (!keyValueMatch) continue;

    const [, key, rawValue] = keyValueMatch;
    const value = rawValue.trim().replace(/^"|"$/g, '');

    if (key === 'title') {
      metadata.title = value;
    } else if (key === 'language') {
      metadata.language = toLanguage(value);
    } else if (key === 'audience' && value === '') {
      metadata.audience = [];
      currentListKey = 'audience';
    } else if (key === 'tags' && value === '') {
      metadata.tags = [];
      currentListKey = 'tags';
    }
  }

  metadata.audience = toAudience(metadata.audience);
  metadata.tags = metadata.tags.filter(Boolean);

  return { metadata, body: normalizeWhitespace(body) };
}

function splitMarkdownIntoSections(content: string): Array<{ section?: string; text: string }> {
  const lines = content.split('\n');
  const sections: Array<{ section?: string; text: string }> = [];
  let currentSection: string | undefined;
  let buffer: string[] = [];

  const pushBuffer = () => {
    const text = normalizeWhitespace(buffer.join('\n'));
    if (text) sections.push({ section: currentSection, text });
    buffer = [];
  };

  for (const line of lines) {
    if (line.startsWith('#')) {
      pushBuffer();
      currentSection = line.replace(/^#+\s*/, '').trim() || currentSection;
      continue;
    }
    buffer.push(line);
  }

  pushBuffer();
  return sections;
}

function splitLongText(text: string): string[] {
  if (text.length <= MAX_CHARS) return [text];

  const chunks: string[] = [];
  let start = 0;

  while (start < text.length) {
    let end = Math.min(start + MAX_CHARS, text.length);

    if (end < text.length) {
      // ✅ Arabic sentence boundaries added alongside ASCII ones
      const lastBreak = Math.max(
        text.lastIndexOf('\n\n', end),
        text.lastIndexOf('؟ ', end),  // Arabic question mark
        text.lastIndexOf('۔ ', end),  // Arabic full stop
        text.lastIndexOf('، ', end),  // Arabic comma (softer break)
        text.lastIndexOf('. ', end),
        text.lastIndexOf('! ', end),
        text.lastIndexOf('? ', end),
      );

      if (lastBreak > start + Math.floor(MAX_CHARS / 2)) {
        end = lastBreak + 1;
      }
    }

    const chunk = normalizeWhitespace(text.slice(start, end));
    if (chunk) chunks.push(chunk);

    if (end >= text.length) break;

    start = Math.max(end - OVERLAP_CHARS, start + 1);
  }

  return chunks;
}

async function collectRawFiles(dir: string): Promise<string[]> {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const files = await Promise.all(
    entries.map(async (entry) => {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) return collectRawFiles(fullPath);
      return [fullPath];
    })
  );
  return files.flat();
}

async function buildMarkdownChunks(filePath: string): Promise<ChunkRecord[]> {
  const content = await fs.readFile(filePath, 'utf8');
  const { metadata, body } = parseFrontmatter(content);
  const relativeSource = path.relative(rawDir, filePath).replace(/\\/g, '/');
  const documentId = relativeSource.replace(/\.[^.]+$/, '');
  const language = getLanguageFromFilename(filePath, metadata.language);

  return splitMarkdownIntoSections(body).flatMap((section, index) =>
    splitLongText(section.text).map((text, chunkIndex) => ({
      text,
      source: relativeSource,
      section: section.section ?? metadata.title ?? `section-${index + 1}`,
      audience: metadata.audience,
      language,
      tags: metadata.tags,
      documentId: `${documentId}-${index + 1}-${chunkIndex + 1}`,
    }))
  );
}

async function buildFaqChunks(filePath: string): Promise<ChunkRecord[]> {
  const raw = await fs.readFile(filePath, 'utf8');
  const entries = JSON.parse(raw) as FaqEntry[];
  const relativeSource = path.relative(rawDir, filePath).replace(/\\/g, '/');
  const fallbackLanguage = getLanguageFromFilename(filePath);

  return entries
    .filter((entry) => entry.question && entry.answer)
    .map((entry, index) => {
      const language = toLanguage(entry.language, fallbackLanguage);
      const { q, a } = getFaqLabels(language); // ✅ language-aware labels
      return {
        text: normalizeWhitespace(`${q}: ${entry.question}\n\n${a}: ${entry.answer}`),
        source: relativeSource,
        section: entry.question,
        audience: toAudience(entry.audience),
        language,
        tags: (entry.tags ?? []).filter(Boolean),
        documentId: entry.id ?? `${relativeSource.replace(/\.[^.]+$/, '')}-${index + 1}`,
      };
    });
}
function cleanPdfText(text: string): string {
  return text
    // Normalize Unicode — converts ligatures to proper sequences
    .normalize('NFKC')

    // Remove null bytes and other control characters (common in PDFs)
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')

    // Remove repeated dashes/underscores used as visual separators
    .replace(/[-_=]{3,}/g, '')

    // Remove standalone numbers on their own line (page numbers)
    .replace(/^\s*\d+\s*$/gm, '')

    // Remove lines that are pure punctuation/symbols with no real content
    .replace(/^[^\u0600-\u06FF\u0750-\u077F\u08A0-\u08FFa-zA-Z0-9]+$/gm, '')
    .replace(/(أركان الحج|شروط الحج|واجبات الحج|محظورات الإحرام|الركن الأول|الركن الثاني|الركن الثالث|الركن الرابع|تعريف|حكم الحج|أنواع الإحرام)/g, '\n\n$1')

    // Collapse excessive whitespace
    .replace(/[ \t]{2,}/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/\u0000/g, '')
    .replace(/[^\S\r\n]+/g, ' ')
    .trim();
}

async function buildPdfChunks(filePath: string): Promise<ChunkRecord[]> {
  const buffer = await fs.readFile(filePath);
  const parser = new PDFParse({ data: new Uint8Array(buffer) });
  const parsed = await parser.getText();
  const relativeSource = path.relative(rawDir, filePath).replace(/\\/g, '/');
  const documentId = relativeSource.replace(/\.[^.]+$/, '');
  const body = cleanPdfText(normalizeWhitespace(parsed.text));
  const language = getLanguageFromFilename(filePath);

  const paragraphs = body
    .split(/\n{2,}/)
    .map((p) => p.trim())
    .filter((p) => p.length > 80)
    .filter((p) => {
      const arabicAndLatin = (p.match(/[\u0600-\u06FFa-zA-Z]/g) ?? []).length;
      return arabicAndLatin / p.length > 0.3;
    });

  return paragraphs.flatMap((paragraph, index) =>
    splitLongText(paragraph).map((text, chunkIndex) => ({
      text,
      source: relativeSource,
      section: `section-${index + 1}`,
      audience: ['pelerin'] as Audience[],
      language,
      tags: [],
      documentId: `${documentId}-${index + 1}-${chunkIndex + 1}`,
    }))
  );
}
async function replaceChunks(chunks: ChunkRecord[]): Promise<void> {
  const uniqueSources = [...new Set(chunks.map((c) => c.source))];

  // Delete existing chunks for these sources in one safe query
  if (uniqueSources.length > 0) {
    await prisma.ragChunk.deleteMany({
      where: { source: { in: uniqueSources } },
    });
  }

  // Insert new chunks one by one — embeddings are float arrays, not user input,
  // but we still avoid raw SQL entirely for safety and maintainability
  for (const chunk of chunks) {
    const embedding = await embedText(chunk.text);

    // pgvector requires a raw vector literal — this is the one place we need
    // executeRaw, but the only interpolated value is our own float array
    await prisma.$executeRaw(
      Prisma.sql`
        INSERT INTO "RagChunk" (
          "id", "text", "source", "section",
          "audience", "language", "tags", "documentId", "embedding"
        ) VALUES (
          ${randomUUID()},
          ${chunk.text},
          ${chunk.source},
          ${chunk.section ?? null},
          ${chunk.audience}::text[],
          ${chunk.language},
          ${chunk.tags}::text[],
          ${chunk.documentId ?? null},
          ${Prisma.raw(`'[${embedding.join(',')}]'::vector`)}
        )
      `
    );
  }
}

async function writeProcessedPreview(chunks: ChunkRecord[]): Promise<void> {
  await fs.mkdir(processedDir, { recursive: true });
  await fs.writeFile(processedChunksPath, JSON.stringify(chunks, null, 2), 'utf8');
}

async function main(): Promise<void> {
  const rawFiles = await collectRawFiles(rawDir);
  const supportedFiles = rawFiles.filter((f) => /\.(md|json|pdf)$/i.test(f));

  if (supportedFiles.length === 0) {
    console.log('No supported files found in chat/data/raw. Add .md, .json, or .pdf files first.');
    return;
  }

  const allChunks: ChunkRecord[] = [];

  for (const filePath of supportedFiles) {
    if (filePath.endsWith('.md')) {
      allChunks.push(...(await buildMarkdownChunks(filePath)));
    } else if (filePath.endsWith('.json')) {
      allChunks.push(...(await buildFaqChunks(filePath)));
    } else if (filePath.endsWith('.pdf')) {
      allChunks.push(...(await buildPdfChunks(filePath)));
    }
  }

  if (allChunks.length === 0) {
    console.log('No chunks were generated from the selected files.');
    return;
  }

  console.log(`Generated ${allChunks.length} chunks. Saving preview...`);
  await writeProcessedPreview(allChunks);

  console.log('Embedding and inserting chunks...');
  await replaceChunks(allChunks);

  console.log(`✅ Ingestion complete. ${allChunks.length} chunks written to RagChunk.`);
  console.log(`Chunk preview saved to: ${processedChunksPath}`);
}

main()
  .catch((error) => {
    console.error('RAG ingestion failed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });