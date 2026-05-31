-- prisma/migrations/20260530000000_add_translation_cache/migration.sql

CREATE TABLE "TranslationCache" (
    "id" TEXT NOT NULL,
    "sourceLang" TEXT NOT NULL,
    "targetLang" TEXT NOT NULL,
    "sourceHash" TEXT NOT NULL,
    "sourceText" TEXT NOT NULL,
    "translatedText" TEXT NOT NULL,
    "provider" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "lastUsedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TranslationCache_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "TranslationCache_sourceLang_targetLang_sourceHash_key" 
    ON "TranslationCache"("sourceLang", "targetLang", "sourceHash");

CREATE INDEX "TranslationCache_targetLang_idx" ON "TranslationCache"("targetLang");
CREATE INDEX "TranslationCache_lastUsedAt_idx" ON "TranslationCache"("lastUsedAt");