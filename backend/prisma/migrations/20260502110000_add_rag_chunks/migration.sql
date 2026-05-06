CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE "RagChunk" (
    "id" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "section" TEXT,
    "audience" TEXT[] NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'fr',
    "tags" TEXT[] NOT NULL,
    "documentId" TEXT,
    "embedding" vector(768) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RagChunk_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "RagChunk_language_idx" ON "RagChunk"("language");
