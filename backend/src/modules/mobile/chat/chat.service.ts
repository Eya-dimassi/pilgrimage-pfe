import { ChatRequest, ChatResponse } from './chat.types';
import { retrieveRelevantChunks, formatChunksAsContext } from './chat.retrieval';
import { buildSystemPrompt } from './chat.prompts';
import { generateAnswer } from './chat.provider';

const MAX_HISTORY_MESSAGES = 4;
const MAX_HISTORY_CHARS = 600;

const NO_CONTEXT_ANSWERS: Record<'ar' | 'fr' | 'en', string> = {
  ar: 'لا أملك معلومات كافية في قاعدة المعرفة للإجابة بدقة على هذا السؤال. من الأفضل التحقق من مصدر رسمي أو سؤال المرشد.',
  fr: "Je n'ai pas assez d'informations dans la base de connaissances pour répondre avec précision. Il vaut mieux vérifier une source officielle ou demander au guide.",
  en: 'I do not have enough information in the knowledge base to answer accurately. Please check an official source or ask the guide.',
};

function detectLanguage(text: string): 'ar' | 'fr' | 'en' {
  const arabicChars = (text.match(/[\u0600-\u06FF]/g) ?? []).length;
  const frenchChars = (text.match(/[àâäéèêëîïôùûüçœæ]/gi) ?? []).length;
  const totalChars = text.replace(/\s/g, '').length;

  if (totalChars === 0) return 'fr';
  if (arabicChars / totalChars > 0.2) return 'ar';
  if (frenchChars > 0) return 'fr';

  const frenchWords = /\b(je|tu|il|nous|vous|ils|le|la|les|de|du|des|est|et|en|un|une|pour|avec|dans|sur|que|qui|quoi|comment|quand|où|quel|quelle)\b/i;
  if (frenchWords.test(text)) return 'fr';

  return 'en';
}

function sanitizeHistory(history: ChatRequest['history']): ChatRequest['history'] {
  return history
    .filter(
      (message) =>
        (message.role === 'user' || message.role === 'assistant') &&
        typeof message.content === 'string' &&
        message.content.trim().length > 0
    )
    .slice(-MAX_HISTORY_MESSAGES)
    .map((message) => ({
      role: message.role,
      content: message.content.trim().slice(0, MAX_HISTORY_CHARS),
    }));
}
const ERROR_ANSWERS: Record<'ar' | 'fr' | 'en', string> = {
  ar: 'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.',
  fr: "Désolé, une erreur s'est produite. Veuillez réessayer.",
  en: 'Sorry, an error occurred. Please try again.',
};
export async function handleChatMessage(
  request: ChatRequest): Promise<ChatResponse> {
  const {message,userRole,history} = request;
  const language = request.language ?? detectLanguage(message);

  try {
    const retrieval = await retrieveRelevantChunks(message, {
      language,
      audience:userRole,
      topK:userRole ==='guide'?6:5,
    });

    if (retrieval.chunks.length === 0) {
      return { answer: NO_CONTEXT_ANSWERS[language], usedFallback: false };
    }

    const context =formatChunksAsContext(retrieval.chunks);
    const systemPrompt =buildSystemPrompt(userRole, 
      { retrievedContext:context
                         ,language });

    return await generateAnswer(systemPrompt,
       sanitizeHistory(history),
        message);

  }catch (err) {
    console.error(`[chat] failed for role=${userRole} lang=${language}:`, err);
    return { answer: ERROR_ANSWERS[language],usedFallback: true };
  }
}