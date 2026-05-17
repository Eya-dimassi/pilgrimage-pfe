// chat.types.ts

export type UserRole = 'pelerin' | 'famille' | 'guide';

export type MessageRole = 'user' | 'assistant';

export interface ChatMessage {
  role: MessageRole;
  content: string;
}

export interface ChatRequest {
  message: string;
  history: ChatMessage[];
  userRole: UserRole;
  language?: 'ar' | 'fr' | 'en';
}

export interface ChatResponse {
  answer: string;
  usedFallback?: boolean;
}

export interface RagChunk {
  id: string;
  text: string;
  source: string;
  section?: string;
  audience: string[];
  language: string;
  tags: string[];
  similarity?: number;
}

export interface RetrievalResult {
  chunks: RagChunk[];
  totalFound: number;
}