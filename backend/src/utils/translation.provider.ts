import { env } from '../config/env'

export type SupportedLanguage = 'fr' | 'en' | 'ar'

export type TranslationBatchItem = {
  key: string
  text: string | null | undefined
}

const GEMINI_TRANSLATION_MODEL = 'gemini-2.5-flash'
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
                `Translate every "text" value from ${LANGUAGE_LABELS[sourceLang]} to ${LANGUAGE_LABELS[targetLang]}.`,
                'Preserve every "key" exactly.',
                'Return only valid JSON, no markdown, no explanation.',
                'The output must be an array with the same length and order as the input.',
                'Each output item must have exactly: {"key": string, "text": string}.',
                'Preserve names, dates, times, numbers, punctuation, and line breaks.',
              ].join(' '),
            },
          ],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: JSON.stringify(items) }],
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
      if (
        !item ||
        item.key !== items[index].key ||
        typeof item.text !== 'string'
      ) {
        throw new Error('Gemini batch translation returned invalid item shape')
      }

      return {
        key: item.key as string,
        text: item.text as string,
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

  const maxAttempts = Math.max(1, env.TRANSLATION_RETRY_COUNT + 1)

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      const translated = await callGeminiTranslation(sourceText, sourceLang, targetLang)
      saveToMemoryCache(sourceText, sourceLang, targetLang, translated)
      return translated
    } catch (error) {
      console.warn(
        `[translation] fallback_fr lang=${targetLang} attempt=${attempt}/${maxAttempts}:`,
        error,
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
  const missingItems = translatableItems.filter((item) => {
    const cached = getFromMemoryCache(item.text, sourceLang, targetLang)
    if (cached != null) {
      cachedByKey.set(item.key, cached)
      return false
    }

    return true
  })

  if (!missingItems.length) {
    return fallback.map((item) => ({
      key: item.key,
      text: cachedByKey.get(item.key) ?? item.text,
    }))
  }

  const maxAttempts = Math.max(1, env.TRANSLATION_RETRY_COUNT + 1)

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      const translated = await callGeminiBatchTranslation(
        missingItems.map(({ key, text }) => ({ key, text })),
        sourceLang,
        targetLang,
      )
      for (const translatedItem of translated) {
        const sourceItem = missingItems.find((item) => item.key === translatedItem.key)
        if (sourceItem) {
          saveToMemoryCache(sourceItem.text, sourceLang, targetLang, translatedItem.text)
        }
      }
      const translatedByKey = new Map(translated.map((item) => [item.key, item.text]))

      return fallback.map((item) => ({
        key: item.key,
        text: cachedByKey.get(item.key) ?? translatedByKey.get(item.key) ?? item.text,
      }))
    } catch (error) {
      console.warn(
        `[translation] batch_fallback_fr lang=${targetLang} attempt=${attempt}/${maxAttempts}:`,
        error,
      )
    }
  }

  return fallback
}
