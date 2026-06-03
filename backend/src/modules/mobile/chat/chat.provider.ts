import { AIMessage, HumanMessage } from '@langchain/core/messages';
import { ChatPromptTemplate, MessagesPlaceholder } from '@langchain/core/prompts';
import { ChatGoogleGenerativeAI } from '@langchain/google-genai';
import { ChatOllama, OllamaEmbeddings } from '@langchain/ollama';
import { ChatMessage } from './chat.types';
import { ChatGroq } from '@langchain/groq';
export type ProviderName = 'gemini' | 'ollama' | 'groq';

interface ProviderConfig {
  primary: ProviderName;
  fallback?: ProviderName;
}

function toProviderName(value: string | undefined, fallback: ProviderName): ProviderName {
  return value === 'gemini' || value === 'ollama' || value === 'groq' ? value : fallback;
}

function toOptionalProviderName(value: string | undefined): ProviderName | undefined {
  return value === 'gemini' || value === 'ollama' || value === 'groq' ? value : undefined;
}

function toInt(value: string | undefined, fallback: number): number {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

const config: ProviderConfig = {
  primary: toProviderName(process.env.CHAT_PRIMARY_PROVIDER, 'groq'),
  fallback: toOptionalProviderName(process.env.CHAT_FALLBACK_PROVIDER ?? 'gemini'),
};

const ollamaBaseUrl = process.env.OLLAMA_BASE_URL || 'http://localhost:11434';
const ollamaModelName = process.env.OLLAMA_MODEL || 'qwen3:8b';
const embeddingModelName = process.env.OLLAMA_EMBEDDING_MODEL || 'mxbai-embed-large';
const geminiModelName = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const groqModelName = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';
const providerTimeoutMs = toInt(process.env.CHAT_PROVIDER_TIMEOUT_MS, 25000);
const useQwenNoThinkPrompt =
  process.env.OLLAMA_NO_THINK_PROMPT !== 'false' && /qwen/i.test(ollamaModelName);
const groqModel = new ChatGroq({
  apiKey: process.env.GROQ_API_KEY,
  model: groqModelName,
  temperature: 0.1, // Forces strict reliance on text chunks
});
const ollamaModel = new ChatOllama({
  baseUrl: ollamaBaseUrl,
  model: ollamaModelName,
  temperature: 0.1,
  numPredict: toInt(process.env.OLLAMA_NUM_PREDICT, 320),
  numCtx: toInt(process.env.OLLAMA_NUM_CTX, 4096),
  keepAlive: process.env.OLLAMA_KEEP_ALIVE ?? '10m',
  think: process.env.OLLAMA_THINK === 'true',
});

const geminiModel = new ChatGoogleGenerativeAI({
  apiKey: process.env.GEMINI_API_KEY,
  model: geminiModelName,
  temperature: 0.1,
});

const embeddingModel = new OllamaEmbeddings({
  baseUrl: ollamaBaseUrl,
  model: embeddingModelName,
});

function toText(content: unknown): string {
  if (typeof content === 'string') return content.trim();

  if (Array.isArray(content)) {
    return content
      .map((part) => {
        if (typeof part === 'string') return part;
        if (part && typeof part === 'object' && 'text' in part) {
          return String((part as { text?: unknown }).text ?? '');
        }
        return '';
      })
      .join('')
      .trim();
  }

  return String(content ?? '').trim();
}

function stripThinking(value: string): string {
  return value.replace(/<think>[\s\S]*?<\/think>/gi, '').trim();
}

function requiresArabic(systemPrompt: string): boolean {
  return systemPrompt.includes('reply in Arabic');
}

function hasEnoughArabic(value: string): boolean {
  const compact = value.replace(/\s/g, '');
  if (compact.length === 0) return false;

  const arabicChars = (compact.match(/[\u0600-\u06FF]/g) ?? []).length;
  return arabicChars / compact.length > 0.2;
}

function assertRequestedLanguage(systemPrompt: string, answer: string): void {
  if (requiresArabic(systemPrompt) && !hasEnoughArabic(answer)) {
    throw new Error('Provider ignored Arabic language instruction');
  }
}

function buildFinalUserMessage(systemPrompt: string, userMessage: string): string {
  const parts: string[] = [];

  if (useQwenNoThinkPrompt) {
    parts.push('/no_think');
  }

  if (requiresArabic(systemPrompt)) {
    parts.push(
      'أجب بالعربية فقط. اكتب الإجابة النهائية مباشرة دون شرح طريقة البحث أو تحليل السياق.'
    );
  }

  parts.push(userMessage);

  return parts.join('\n');
}

function toHistoryMessages(history: ChatMessage[]) {
  return history.map((message) =>
    message.role === 'assistant'
      ? new AIMessage(message.content)
      : new HumanMessage(message.content)
  );
}

async function buildMessages(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<Array<AIMessage | HumanMessage>> {
  const prompt = ChatPromptTemplate.fromMessages([
    ['system', '{systemPrompt}'],
    new MessagesPlaceholder('history'),
    ['human', '{userMessage}'],
  ]);

  return prompt.formatMessages({
    systemPrompt,
    history: toHistoryMessages(history),
    userMessage,
  }) as Promise<Array<AIMessage | HumanMessage>>;
}

export async function embedText(text: string): Promise<number[]> {
  return embeddingModel.embedQuery(text);
}

async function callOllama(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<string> {
  const finalUserMessage = buildFinalUserMessage(systemPrompt, userMessage);

  const response = await ollamaModel.invoke(
    await buildMessages(systemPrompt, history, finalUserMessage)
  );
  const answer = stripThinking(toText(response.content));

  if (!answer) {
    throw new Error('Ollama returned empty response');
  }

  assertRequestedLanguage(systemPrompt, answer);

  return answer;
}
async function callGroq(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<string> {
  const response = await groqModel.invoke(
    await buildMessages(systemPrompt, history, userMessage)
  );
  const answer = stripThinking(toText(response.content));

  if (!answer) {
    throw new Error('Groq returned empty response');
  }

  assertRequestedLanguage(systemPrompt, answer);

  return answer;
}

async function callGemini(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<string> {
  const response = await geminiModel.invoke(
    await buildMessages(systemPrompt, history, userMessage)
  );
  const answer = stripThinking(toText(response.content));

  if (!answer) {
    throw new Error('Gemini returned empty response');
  }

  assertRequestedLanguage(systemPrompt, answer);

  return answer;
}

async function withTimeout<T>(label: string, task: Promise<T>): Promise<T> {
  let timeout: NodeJS.Timeout | undefined;
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeout = setTimeout(
      () => reject(new Error(`${label} timed out after ${providerTimeoutMs}ms`)),
      providerTimeoutMs
    );
  });

  try {
    return await Promise.race([task, timeoutPromise]);
  } finally {
    if (timeout) clearTimeout(timeout);
  }
}

async function callProvider(
  provider: ProviderName,
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<string> {
  switch (provider) {
    case 'groq':
      return withTimeout('Groq', callGroq(systemPrompt, history, userMessage));
    case 'gemini':
      return withTimeout('Gemini', callGemini(systemPrompt, history, userMessage));
    case 'ollama':
      return withTimeout('Ollama', callOllama(systemPrompt, history, userMessage));
    default:
      throw new Error(`Unsupported provider: ${provider}`);
  }
}

export async function generateAnswer(
  systemPrompt: string,
  history: ChatMessage[],
  userMessage: string
): Promise<{ answer: string; usedFallback: boolean }> {
  try {
    const answer = await callProvider(config.primary, systemPrompt, history, userMessage);

    return { answer, usedFallback: false };
  } catch (err) {
    console.warn('Primary provider failed, trying fallback:', err);

    if (!config.fallback) {
      throw new Error('Primary provider failed and no fallback is configured');
    }

    try {
      const answer = await callProvider(config.fallback, systemPrompt, history, userMessage);

      return { answer, usedFallback: true };
    } catch (fallbackErr) {
      console.error('Fallback also failed:', fallbackErr);
      throw new Error('All providers failed');
    }
  }
}
