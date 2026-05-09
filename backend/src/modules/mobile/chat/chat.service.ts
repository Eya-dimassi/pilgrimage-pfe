import { ChatRequest, ChatResponse } from './chat.types';
import { retrieveRelevantChunks, formatChunksAsContext } from './chat.retrieval';
import { buildSystemPrompt } from './chat.prompts';
import { generateAnswer } from './chat.provider';

function trimHistory(history: ChatRequest['history'], maxMessages = 6) {
  return history.slice(-maxMessages);
}

export async function handleChatMessage(
  request: ChatRequest
): Promise<ChatResponse> {
  const { message, history, userRole, language } = request;

  try {
    const retrieval = await retrieveRelevantChunks(message, {
      language,
      audience: userRole,
      topK: 5,
    });

    const retrievedContext = formatChunksAsContext(retrieval.chunks);

    const systemPrompt = buildSystemPrompt(userRole, {
      retrievedContext,
      language,
    });

    const trimmedHistory = trimHistory(history);

    const { answer, usedFallback } = await generateAnswer(
      systemPrompt,
      trimmedHistory,
      message
    );

    return {
      answer,
      usedFallback,
    };
  } catch (err) {
    console.error('Chat service error:', err);

    const fallbackAnswer =
      language === 'ar'
        ? 'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.'
        : language === 'fr'
        ? "Désolé, une erreur s'est produite. Veuillez réessayer."
        : 'Sorry, an error occurred. Please try again.';

    return {
      answer: fallbackAnswer,
      usedFallback: true,
    };
  }
}
