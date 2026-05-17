import { ChatRequest, ChatResponse } from './chat.types';
import { retrieveRelevantChunks, formatChunksAsContext } from './chat.retrieval';
import { buildSystemPrompt } from './chat.prompts';
import { generateAnswer } from './chat.provider';

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

export async function handleChatMessage(
  request: ChatRequest
): Promise<ChatResponse> {
  const { message, userRole } = request;
  const language = request.language ?? detectLanguage(message);

  let stage = 'retrieval';

  try {
    const retrieval = await retrieveRelevantChunks(message, {
      language,
      audience: userRole,
      topK: 8,
    });

    console.debug(
      `[chat] retrieval: ${retrieval.totalFound} chunks for role=${userRole} lang=${language}`
    );

    stage = 'generation';

    const retrievedContext = formatChunksAsContext(retrieval.chunks);
    const systemPrompt = buildSystemPrompt(userRole, { retrievedContext, language });

    const { answer, usedFallback } = await generateAnswer(
      systemPrompt,
      [],   // no history — intentional for speed
      message
    );

    return { answer, usedFallback };

  } catch (err) {
    console.error(`[chat] error at stage=${stage} role=${userRole} lang=${language}:`, err);

    const fallbackAnswer =
      language === 'ar'
        ? 'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.'
        : language === 'fr'
        ? "Désolé, une erreur s'est produite. Veuillez réessayer."
        : 'Sorry, an error occurred. Please try again.';

    return { answer: fallbackAnswer, usedFallback: true };
  }
}