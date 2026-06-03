
import { createHash } from 'crypto'
import { env } from '../config/env'
import prisma from '../config/prisma'

export type SupportedLanguage = 'fr' | 'en' | 'ar'

export type TranslationBatchItem = {
  key: string
  text: string | null | undefined
}

const GEMINI_TRANSLATION_MODEL = 'gemini-2.5-flash'
const TRANSLATION_PROVIDER = 'gemini'
const MEMORY_CACHE_TTL_MS = 24 * 60 * 60 * 1000
const MEMORY_CACHE_MAX_ITEMS = 1000

const translationMemoryCache = new Map<string, { value: string; expiresAt: number }>()

const LANGUAGE_LABELS: Record<SupportedLanguage, string> = {
  fr: 'French',
  en: 'English',
  ar: 'Arabic',
}

export function normalizeLanguage(value: unknown): SupportedLanguage {
  const raw = String(value ?? '').trim().toLowerCase()

  if (raw.startsWith('ar')) return 'ar'
  if (raw.startsWith('en')) return 'en'
  if (raw.startsWith('fr')) return 'fr'

  return 'fr'
}

function getTranslationApiKey() {
  return env.GEMINI_TRANSLATION_API_KEY
}

function getMemoryCacheKey(
  text: string,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  return `${sourceLang}:${targetLang}:${text}`
}

function getFromMemoryCache(
  text: string,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  const key = getMemoryCacheKey(text, sourceLang, targetLang)
  const cached = translationMemoryCache.get(key)

  if (!cached) return null

  if (Date.now() > cached.expiresAt) {
    translationMemoryCache.delete(key)
    return null
  }

  return cached.value
}

function saveToMemoryCache(
  text: string,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
  value: string,
) {
  if (translationMemoryCache.size >= MEMORY_CACHE_MAX_ITEMS) {
    const firstKey = translationMemoryCache.keys().next().value
    if (firstKey) translationMemoryCache.delete(firstKey)
  }

  translationMemoryCache.set(getMemoryCacheKey(text, sourceLang, targetLang), {
    value,
    expiresAt: Date.now() + MEMORY_CACHE_TTL_MS,
  })
}

function getSourceHash(text: string) {
  return createHash('sha256').update(text).digest('hex')
}

async function getFromDbCache(
  text: string,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  const sourceHash = getSourceHash(text)

  try {
    const cached = await prisma.translationCache.findUnique({
      where: {
        sourceLang_targetLang_sourceHash: {
          sourceLang,
          targetLang,
          sourceHash,
        },
      },
      select: {
        translatedText: true,
      },
    })

    if (!cached) return null

    await prisma.translationCache.update({
      where: {
        sourceLang_targetLang_sourceHash: {
          sourceLang,
          targetLang,
          sourceHash,
        },
      },
      data: {
        lastUsedAt: new Date(),
      },
    })

    return cached.translatedText
  } catch (error) {
    console.warn(`[translation] db_cache_read_failed lang=${targetLang}:`, error)
    return null
  }
}

async function getBatchFromDbCache(
  texts: string[],
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  const uniqueTextsByHash = new Map<string, string>()
  for (const text of texts) {
    uniqueTextsByHash.set(getSourceHash(text), text)
  }

  const sourceHashes = [...uniqueTextsByHash.keys()]
  if (!sourceHashes.length) return new Map<string, string>()

  try {
    const cachedRows = await prisma.translationCache.findMany({
      where: {
        sourceLang,
        targetLang,
        sourceHash: {
          in: sourceHashes,
        },
      },
      select: {
        sourceHash: true,
        translatedText: true,
      },
    })

    if (cachedRows.length) {
      await prisma.translationCache.updateMany({
        where: {
          sourceLang,
          targetLang,
          sourceHash: {
            in: cachedRows.map((row) => row.sourceHash),
          },
        },
        data: {
          lastUsedAt: new Date(),
        },
      })
    }

    return new Map(cachedRows.map((row) => [row.sourceHash, row.translatedText]))
  } catch (error) {
    console.warn(`[translation] batch_db_cache_read_failed lang=${targetLang}:`, error)
    return new Map<string, string>()
  }
}

async function saveToDbCache(
  text: string,
  translatedText: string,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  const sourceHash = getSourceHash(text)

  try {
    await prisma.translationCache.upsert({
      where: {
        sourceLang_targetLang_sourceHash: {
          sourceLang,
          targetLang,
          sourceHash,
        },
      },
      create: {
        sourceLang,
        targetLang,
        sourceHash,
        sourceText: text,
        translatedText,
        provider: TRANSLATION_PROVIDER,
      },
      update: {
        sourceText: text,
        translatedText,
        provider: TRANSLATION_PROVIDER,
        lastUsedAt: new Date(),
      },
    })
  } catch (error) {
    console.warn(`[translation] db_cache_write_failed lang=${targetLang}:`, error)
  }
}

async function saveBatchToDbCache(
  items: Array<{ text: string; translatedText: string }>,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  await Promise.all(
    items.map((item) =>
      saveToDbCache(item.text, item.translatedText, sourceLang, targetLang),
    ),
  )
}

function withTimeout(ms: number) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), ms)

  return {
    signal: controller.signal,
    clear: () => clearTimeout(timeout),
  }
}

function cleanGeminiText(value: string) {
  return value
    .replace(/^```(?:text)?/i, '')
    .replace(/```$/i, '')
    .trim()
    .replace(/^["']([\s\S]*)["']$/m, '$1')
    .trim()
}

function cleanGeminiJson(value: string) {
  return value
    .trim()
    .replace(/^```(?:json)?/i, '')
    .replace(/```$/i, '')
    .trim()
}

function getTranslationErrorMessage(error: unknown) {
  if (error instanceof Error) {
    return error.message
  }

  return String(error)
}

async function callGeminiTranslation(
  text: string,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  const apiKey = getTranslationApiKey()
  if (!apiKey) {
    throw new Error('Missing Gemini translation API key')
  }

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_TRANSLATION_MODEL}:generateContent?key=${apiKey}`
  const timeout = withTimeout(env.TRANSLATION_TIMEOUT_MS)

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: timeout.signal,
      body: JSON.stringify({
        system_instruction: {
          parts: [
            {
              text: [
                'You are a strict translation engine.',
                `Translate from ${LANGUAGE_LABELS[sourceLang]} to ${LANGUAGE_LABELS[targetLang]}.`,
                'Preserve names, dates, times, numbers, punctuation, and line breaks.',
                'Do not explain, summarize, transliterate unless necessary, or add any extra text.',
                'Return only the translated text.',
              ].join(' '),
            },
          ],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text }],
          },
        ],
        generationConfig: {
          temperature: 0,
        },
      }),
    })

    if (!response.ok) {
      throw new Error(`Gemini translation error: ${response.status}`)
    }

    const data = await response.json()
    const translated = cleanGeminiText(data.candidates?.[0]?.content?.parts?.[0]?.text ?? '')

    if (!translated) {
      throw new Error('Gemini translation returned empty response')
    }

    return translated
  } finally {
    timeout.clear()
  }
}

async function callGeminiBatchTranslation(
  items: Array<{ key: string; text: string }>,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage,
) {
  const apiKey = getTranslationApiKey()
  if (!apiKey) {
    throw new Error('Missing Gemini translation API key')
  }

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_TRANSLATION_MODEL}:generateContent?key=${apiKey}`
  const timeout = withTimeout(env.TRANSLATION_TIMEOUT_MS)

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: timeout.signal,
      body: JSON.stringify({
        system_instruction: {
          parts: [
            {
              text: [
                'You are a strict JSON translation engine.',
                `Translate every array item from ${LANGUAGE_LABELS[sourceLang]} to ${LANGUAGE_LABELS[targetLang]}.`,
                'Return only valid JSON, no markdown, no explanation.',
                'The output must be an array of strings with the same length and order as the input.',
                'Preserve names, dates, times, numbers, punctuation, and line breaks.',
              ].join(' '),
            },
          ],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: JSON.stringify(items.map((item) => item.text)) }],
          },
        ],
        generationConfig: {
          temperature: 0,
          responseMimeType: 'application/json',
        },
      }),
    })

    if (!response.ok) {
      throw new Error(`Gemini batch translation error: ${response.status}`)
    }

    const data = await response.json()
    const raw = cleanGeminiJson(data.candidates?.[0]?.content?.parts?.[0]?.text ?? '')
    const parsed = JSON.parse(raw)

    if (!Array.isArray(parsed) || parsed.length !== items.length) {
      throw new Error('Gemini batch translation returned invalid array shape')
    }

    return parsed.map((item, index) => {
      if (typeof item !== 'string') {
        throw new Error('Gemini batch translation returned invalid item shape')
      }

      return {
        key: items[index].key,
        text: item,
      }
    })
  } finally {
    timeout.clear()
  }
}

export async function translateText(
  text: string | null | undefined,
  targetLang: SupportedLanguage,
  sourceLang: SupportedLanguage = 'fr',
) {
  const sourceText = String(text ?? '').trim()
  if (!sourceText || sourceLang === targetLang || !env.TRANSLATION_ENABLED) {
    return text ?? null
  }

  const cached = getFromMemoryCache(sourceText, sourceLang, targetLang)
  if (cached != null) {
    return cached
  }

  const dbCached = await getFromDbCache(sourceText, sourceLang, targetLang)
  if (dbCached != null) {
    saveToMemoryCache(sourceText, sourceLang, targetLang, dbCached)
    return dbCached
  }

  const maxAttempts = Math.max(1, env.TRANSLATION_RETRY_COUNT + 1)

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      const translated = await callGeminiTranslation(sourceText, sourceLang, targetLang)
      saveToMemoryCache(sourceText, sourceLang, targetLang, translated)
      await saveToDbCache(sourceText, translated, sourceLang, targetLang)
      return translated
    } catch (error) {
      console.warn(
        `[translation] fallback_fr lang=${targetLang} attempt=${attempt}/${maxAttempts}: ${getTranslationErrorMessage(error)}`,
      )
    }
  }

  return text ?? null
}

export async function translateBatch(
  items: TranslationBatchItem[],
  targetLang: SupportedLanguage,
  sourceLang: SupportedLanguage = 'fr',
) {
  const fallback = items.map((item) => ({
    key: item.key,
    text: item.text ?? null,
  }))

  const translatableItems = items
    .map((item, index) => ({
      index,
      key: item.key,
      text: String(item.text ?? '').trim(),
    }))
    .filter((item) => item.text.length > 0)

  if (
    !translatableItems.length ||
    sourceLang === targetLang ||
    !env.TRANSLATION_ENABLED
  ) {
    return fallback
  }

  const cachedByKey = new Map<string, string>()
  const memoryMissingItems = translatableItems.filter((item) => {
    const cached = getFromMemoryCache(item.text, sourceLang, targetLang)
    if (cached != null) {
      cachedByKey.set(item.key, cached)
      return false
    }

    return true
  })

  if (!memoryMissingItems.length) {
    return fallback.map((item) => ({
      key: item.key,
      text: cachedByKey.get(item.key) ?? item.text,
    }))
  }

  const dbCachedByHash = await getBatchFromDbCache(
    memoryMissingItems.map((item) => item.text),
    sourceLang,
    targetLang,
  )
  const providerMissingItems = memoryMissingItems.filter((item) => {
    const sourceHash = getSourceHash(item.text)
    const cached = dbCachedByHash.get(sourceHash)
    if (cached != null) {
      cachedByKey.set(item.key, cached)
      saveToMemoryCache(item.text, sourceLang, targetLang, cached)
      return false
    }

    return true
  })

  if (!providerMissingItems.length) {
    return fallback.map((item) => ({
      key: item.key,
      text: cachedByKey.get(item.key) ?? item.text,
    }))
  }

  const uniqueProviderItemsByHash = new Map<string, { key: string; text: string }>()
  for (const item of providerMissingItems) {
    const sourceHash = getSourceHash(item.text)
    if (!uniqueProviderItemsByHash.has(sourceHash)) {
      uniqueProviderItemsByHash.set(sourceHash, {
        key: sourceHash,
        text: item.text,
      })
    }
  }
  const uniqueProviderItems = [...uniqueProviderItemsByHash.values()]

  const maxAttempts = Math.max(1, env.TRANSLATION_RETRY_COUNT + 1)

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      const translated = await callGeminiBatchTranslation(
        uniqueProviderItems,
        sourceLang,
        targetLang,
      )
      const translatedByHash = new Map(translated.map((item) => [item.key, item.text]))
      const dbItemsToSave: Array<{ text: string; translatedText: string }> = []

      for (const [sourceHash, sourceItem] of uniqueProviderItemsByHash.entries()) {
        const translatedText = translatedByHash.get(sourceHash)
        if (translatedText) {
          saveToMemoryCache(sourceItem.text, sourceLang, targetLang, translatedText)
          dbItemsToSave.push({ text: sourceItem.text, translatedText })
        }
      }

      await saveBatchToDbCache(dbItemsToSave, sourceLang, targetLang)

      for (const sourceItem of providerMissingItems) {
        const translatedText = translatedByHash.get(getSourceHash(sourceItem.text))
        if (sourceItem) {
          cachedByKey.set(sourceItem.key, translatedText ?? sourceItem.text)
        }
      }

      return fallback.map((item) => ({
        key: item.key,
        text: cachedByKey.get(item.key) ?? item.text,
      }))
    } catch (error) {
      console.warn(
        `[translation] batch_fallback_fr lang=${targetLang} attempt=${attempt}/${maxAttempts}: ${getTranslationErrorMessage(error)}`,
      )
    }
  }

  return fallback
}
