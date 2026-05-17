import { UserRole } from './chat.types';

interface PromptContext {
  retrievedContext: string;
  language: 'ar' | 'fr' | 'en';
}



const pelerinPrompt = `
You are a specialized assistant for Hajj and Umrah pilgrims.
Your role is to help pilgrims perform their rituals correctly and with peace of mind.
You answer only based on the provided context.
If the information is not in the context, clearly say you are not certain — never invent religious rules or safety advice.
Keep your answers clear, concise, and reassuring.
`.trim();

const famillePrompt = `
You are an assistant that helps families follow the journey of their loved ones on pilgrimage.
You explain the stages of Hajj and Umrah in simple, accessible terms.
You answer only based on the provided context.
If the information is not in the context, clearly say you are not certain — never invent information about rituals or safety.
Be reassuring and educational in tone.
`.trim();

const guidePrompt = `
You are an assistant for religious guides accompanying groups of pilgrims.
You provide detailed and precise information about Hajj and Umrah rituals.
You help the guide answer questions from their group and handle situations that arise.
You answer only based on the provided context.
If the information is not in the context, clearly say you are not certain — never invent religious rules or safety advice.
Be thorough, accurate, and professional.
`.trim();

const ROLE_PROMPTS: Record<UserRole, string> = {
  pelerin: pelerinPrompt,
  famille: famillePrompt,
  guide: guidePrompt,
};

// Language instruction is explicit and firm — no ambiguity about output language.
// Placed after the role prompt so it takes precedence if there's any conflict.
const LANGUAGE_INSTRUCTIONS: Record<string, string> = {
  ar: 'You MUST reply in Arabic (العربية) regardless of the language of the context or instructions.',
  fr: 'You MUST reply in French (français) regardless of the language of the context or instructions.',
  en: 'You MUST reply in English regardless of the language of the context or instructions.',
};

// No-context fallback is language-aware so the model doesn't respond in French
// to an Arabic user just because the fallback instruction was written in French.
const NO_CONTEXT_INSTRUCTIONS: Record<string, string> = {
  ar: 'لم يتم العثور على معلومات محددة لهذا السؤال. أخبر المستخدم بوضوح أنك لا تملك هذه المعلومات.',
  fr: "Aucune information spécifique n'a été trouvée pour cette question. Dis à l'utilisateur que tu n'as pas cette information.",
  en: 'No specific information was found for this question. Tell the user clearly that you do not have this information.',
};

export function buildSystemPrompt(
  role: UserRole,
  context: PromptContext
): string {
  const rolePrompt = ROLE_PROMPTS[role] ?? ROLE_PROMPTS.pelerin;
  const languageInstruction = LANGUAGE_INSTRUCTIONS[context.language] ?? LANGUAGE_INSTRUCTIONS.fr;

  const contextBlock = context.retrievedContext.trim().length > 0
    ? `<context>\n${context.retrievedContext}\n</context>`
    : `<context>\n${NO_CONTEXT_INSTRUCTIONS[context.language] ?? NO_CONTEXT_INSTRUCTIONS.fr}\n</context>`;

  return [
    rolePrompt,
    languageInstruction,
    contextBlock,
  ].join('\n\n');
}