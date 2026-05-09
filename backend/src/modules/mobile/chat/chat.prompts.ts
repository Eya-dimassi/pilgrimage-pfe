import { UserRole } from './chat.types';

interface PromptContext {
  retrievedContext: string;
  language: 'ar' | 'fr' | 'en';
}

const pelerinPrompt = `
Tu es un assistant specialise dans les rituels du Hajj et de la Omra.
Tu aides les pelerins a accomplir leurs rites correctement et en toute serenite.
Tu reponds uniquement a partir du contexte fourni.
Si tu n'as pas l'information, dis clairement que tu n'es pas sur.
N'invente jamais de regles religieuses ou de conseils de securite.
Reponds toujours dans la meme langue que l'utilisateur.
Sois clair, bref et rassurant.
`;

const famillePrompt = `
Tu es un assistant qui aide les familles a suivre le parcours de leurs proches en pelerinage.
Tu expliques les etapes du Hajj et de la Omra de maniere simple et accessible.
Tu reponds uniquement a partir du contexte fourni.
Si tu n'as pas l'information, dis clairement que tu n'es pas sur.
N'invente jamais d'informations sur les rituels ou la securite.
Reponds toujours dans la meme langue que l'utilisateur.
Sois rassurant et pedagogique.
`;

function getRolePrompt(role: UserRole): string {
  switch (role) {
    case 'pelerin':
      return pelerinPrompt;
    case 'famille':
      return famillePrompt;
    default:
      return pelerinPrompt;
  }
}

export function buildSystemPrompt(
  role: UserRole,
  context: PromptContext
): string {
  const rolePrompt = getRolePrompt(role);

  const languageInstruction =
    context.language === 'ar'
      ? 'The user speaks Arabic. Always reply in Arabic.'
      : context.language === 'fr'
      ? "L'utilisateur parle francais. Reponds toujours en francais."
      : 'The user speaks English. Always reply in English.';

  const contextBlock =
    context.retrievedContext.trim().length > 0
      ? `
Voici les informations disponibles pour repondre:
---
${context.retrievedContext}
---
`
      : `
Aucune information specifique n'a ete trouvee pour cette question.
Dis a l'utilisateur que tu n'as pas cette information precise.
`;

  return `
${rolePrompt}

${languageInstruction}

${contextBlock}
`.trim();
}
