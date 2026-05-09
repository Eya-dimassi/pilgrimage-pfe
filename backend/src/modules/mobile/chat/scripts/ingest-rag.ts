import fs from 'fs/promises';
import path from 'path';
import { randomUUID } from 'crypto';
import { PDFParse } from 'pdf-parse';
import prisma from '../../../../config/prisma';
import { embedText } from '../chat.provider';

type Language = 'ar' | 'fr' | 'en';
type Audience = 'pelerin' | 'famille';

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

const MAX_CHARS = 1800;
const OVERLAP_CHARS = 250;
const EMBEDDING_DELAY_MS = 1200;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function normalizeWhitespace(value: string): string {
  return value.replace(/\r\n/g, '\n').replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim();
}

function toLanguage(value: string | undefined, fallback: Language = 'fr'): Language {
  return value === 'ar' || value === 'en' || value === 'fr' ? value : fallback;
}

function getLanguageFromFilename(filePath: string, fallback: Language = 'fr'): Language {
  const langMatch = filePath.match(/-(ar|fr|en)\./i);
  return toLanguage(langMatch?.[1]?.toLowerCase(), fallback);
}

function toAudience(values: string[] | undefined): Audience[] {
  const allowed = new Set<Audience>(['pelerin', 'famille']);
  const cleaned = (values ?? []).filter((value): value is Audience => allowed.has(value as Audience));
  return cleaned.length > 0 ? cleaned : ['pelerin'];
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
    if (!line.trim()) {
      continue;
    }

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
    if (!keyValueMatch) {
      continue;
    }

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

  return {
    metadata,
    body: normalizeWhitespace(body),
  };
}

function splitMarkdownIntoSections(content: string): Array<{ section?: string; text: string }> {
  const lines = content.split('\n');
  const sections: Array<{ section?: string; text: string }> = [];
  let currentSection: string | undefined;
  let buffer: string[] = [];

  const pushBuffer = () => {
    const text = normalizeWhitespace(buffer.join('\n'));
    if (text) {
      sections.push({ section: currentSection, text });
    }
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
  if (text.length <= MAX_CHARS) {
    return [text];
  }

  const chunks: string[] = [];
  let start = 0;

  while (start < text.length) {
    let end = Math.min(start + MAX_CHARS, text.length);
    if (end < text.length) {
      const lastBreak = Math.max(
        text.lastIndexOf('\n\n', end),
        text.lastIndexOf('. ', end),
        text.lastIndexOf('! ', end),
        text.lastIndexOf('? ', end)
      );
      if (lastBreak > start + Math.floor(MAX_CHARS / 2)) {
        end = lastBreak + 1;
      }
    }

    const chunk = normalizeWhitespace(text.slice(start, end));
    if (chunk) {
      chunks.push(chunk);
    }

    if (end >= text.length) {
      break;
    }

    start = Math.max(end - OVERLAP_CHARS, start + 1);
  }

  return chunks;
}

async function collectRawFiles(dir: string): Promise<string[]> {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const files = await Promise.all(
    entries.map(async (entry) => {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        return collectRawFiles(fullPath);
      }
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
    .map((entry, index) => ({
      text: normalizeWhitespace(`Question: ${entry.question}\n\nReponse: ${entry.answer}`),
      source: relativeSource,
      section: entry.question,
      audience: toAudience(entry.audience),
      language: toLanguage(entry.language, fallbackLanguage),
      tags: (entry.tags ?? []).filter(Boolean),
      documentId: entry.id ?? `${relativeSource.replace(/\.[^.]+$/, '')}-${index + 1}`,
    }));
}

async function buildPdfChunks(filePath: string): Promise<ChunkRecord[]> {
  const buffer = await fs.readFile(filePath);
  const parser = new PDFParse({ data: new Uint8Array(buffer) });
  const parsed = await parser.getText();
  const relativeSource = path.relative(rawDir, filePath).replace(/\\/g, '/');
  const documentId = relativeSource.replace(/\.[^.]+$/, '');
  const body = normalizeWhitespace(parsed.text);
  const language = getLanguageFromFilename(filePath);

  const paragraphs = body
    .split(/\n{2,}/)
    .map((paragraph) => paragraph.trim())
    .filter((paragraph) => paragraph.length > 80);

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

function escapeSqlLiteral(value: string): string {
  return value.replace(/'/g, "''");
}

function toSqlTextArray(values: string[]): string {
  const escaped = values.map((value) => `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`);
  return `{${escaped.join(',')}}`;
}

async function replaceChunks(chunks: ChunkRecord[]): Promise<void> {
  const uniqueSources = [...new Set(chunks.map((chunk) => chunk.source))];

  if (uniqueSources.length > 0) {
    const sourceList = uniqueSources.map((source) => `'${escapeSqlLiteral(source)}'`).join(', ');
    await prisma.$executeRawUnsafe(`DELETE FROM "RagChunk" WHERE source IN (${sourceList})`);
  }

  for (const chunk of chunks) {
    const embedding = await embedText(chunk.text);
    const embeddingLiteral = `[${embedding.join(',')}]`;
    const id = randomUUID();

    await prisma.$executeRawUnsafe(`
      INSERT INTO "RagChunk" (
        "id",
        "text",
        "source",
        "section",
        "audience",
        "language",
        "tags",
        "documentId",
        "embedding"
      ) VALUES (
        '${id}',
        '${escapeSqlLiteral(chunk.text)}',
        '${escapeSqlLiteral(chunk.source)}',
        ${chunk.section ? `'${escapeSqlLiteral(chunk.section)}'` : 'NULL'},
        '${escapeSqlLiteral(toSqlTextArray(chunk.audience))}'::text[],
        '${escapeSqlLiteral(chunk.language)}',
        '${escapeSqlLiteral(toSqlTextArray(chunk.tags))}'::text[],
        ${chunk.documentId ? `'${escapeSqlLiteral(chunk.documentId)}'` : 'NULL'},
        '${embeddingLiteral}'::vector
      )
    `);

    await delay(EMBEDDING_DELAY_MS);
  }
}

async function writeProcessedPreview(chunks: ChunkRecord[]): Promise<void> {
  await fs.mkdir(processedDir, { recursive: true });
  await fs.writeFile(processedChunksPath, JSON.stringify(chunks, null, 2), 'utf8');
}

async function main(): Promise<void> {
  const rawFiles = await collectRawFiles(rawDir);
  const supportedFiles = rawFiles.filter((filePath) => /\.(md|json|pdf)$/i.test(filePath));

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

  await writeProcessedPreview(allChunks);
  await replaceChunks(allChunks);

  console.log(`Ingestion complete. ${allChunks.length} chunks written to RagChunk.`);
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
