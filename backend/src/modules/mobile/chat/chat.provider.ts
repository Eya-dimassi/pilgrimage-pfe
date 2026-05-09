import { ChatMessage } from './chat.types';

export type ProviderName = 'gemini' | 'ollama';

interface ProviderConfig {
  primary: ProviderName;
  fallback?: ProviderName;
}

const config: ProviderConfig = {
  primary: 'gemini',
  fallback: 'ollama',
};

const ollamaModel = process.env.OLLAMA_MODEL || 'gemma3:1b';

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function callGemini(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<string> {
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`;
  const maxAttempts = 5;


  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        system_instruction: {
          parts: [{ text: systemPrompt }],
        },
        contents: [
          ...history.map((message) => ({
            role: message.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: message.content }],
          })),
          {
            role: 'user',
            parts: [{ text: userMessage }],
          },
        ],
      }),
    });

    if (response.ok) {
      const data = await response.json();
      const answer = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';

      if (!answer.trim()) {
        throw new Error('Gemini returned empty response');
      }

      return answer;
    }

    if (response.status === 429 && attempt < maxAttempts) {
      const retryAfterHeader = response.headers.get('retry-after');
      const retryAfterSeconds = retryAfterHeader ? Number(retryAfterHeader) : NaN;
      const waitMs = Number.isFinite(retryAfterSeconds)
        ? retryAfterSeconds * 1000
        : attempt * 3000;

      console.warn(`Gemini generation rate-limited (attempt ${attempt}/${maxAttempts}). Waiting ${waitMs}ms...`);
      await delay(waitMs);
      continue;
    }

    throw new Error(`Gemini error: ${response.status}`);
  }

  throw new Error('Gemini error: exhausted retry attempts');
}

async function callOllama(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<string> {
  const messages = [
    { role: 'system', content: systemPrompt },
    ...history.map((message) => ({ role: message.role, content: message.content })),
    { role: 'user', content: userMessage },
  ];

  const response = await fetch('http://localhost:11434/api/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: ollamaModel,
      messages,
      stream: false,
    }),
  });

  if (!response.ok) {
    throw new Error(`Ollama error: ${response.status} for model ${ollamaModel}`);
  }

  const data = await response.json();
  const answer = data.message?.content ?? '';

  if (!answer.trim()) {
    throw new Error('Ollama returned empty response');
  }

  return answer;
}

export async function embedText(text: string): Promise<number[]> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=${process.env.GEMINI_API_KEY}`;
  const maxAttempts = 5;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        content: { parts: [{ text }] },
        taskType: 'RETRIEVAL_DOCUMENT',
        outputDimensionality: 768,
      }),
    });

    if (response.ok) {
      const raw = await response.json();
      return raw.embedding?.values ?? [];
    }

    if (response.status === 429 && attempt < maxAttempts) {
      const retryAfterHeader = response.headers.get('retry-after');
      const retryAfterSeconds = retryAfterHeader ? Number(retryAfterHeader) : NaN;
      const waitMs = Number.isFinite(retryAfterSeconds)
        ? retryAfterSeconds * 1000
        : attempt * 3000;

      console.warn(`Embedding rate-limited (attempt ${attempt}/${maxAttempts}). Waiting ${waitMs}ms...`);
      await delay(waitMs);
      continue;
    }

    throw new Error(`Embedding error: ${response.status}`);
  }

  throw new Error('Embedding error: exhausted retry attempts');
}


export async function generateAnswer(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<{ answer: string; usedFallback: boolean }> {
  try {
    const answer =
      config.primary === 'gemini'
        ? await callGemini(systemPrompt, history, userMessage)
        : await callOllama(systemPrompt, history, userMessage);

    return { answer, usedFallback: false };
  } catch (err) {
    console.warn('Primary provider failed, trying fallback:', err);

    if (!config.fallback) {
      throw new Error('Primary provider failed and no fallback is configured');
    }

    try {
      const answer =
        config.fallback === 'gemini'
          ? await callGemini(systemPrompt, history, userMessage)
          : await callOllama(systemPrompt, history, userMessage);

      return { answer, usedFallback: true };
    } catch (fallbackErr) {
      console.error('Fallback also failed:', fallbackErr);
      throw new Error('All providers failed');
    }
  }
}
