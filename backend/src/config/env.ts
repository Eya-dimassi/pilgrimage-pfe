import dotenv from 'dotenv';
dotenv.config();

export const env = {
  DATABASE_URL: process.env.DATABASE_URL!,
  JWT_SECRET: process.env.JWT_SECRET!,
  PORT: process.env.PORT || '3000',
  MAIL_HOST: process.env.MAIL_HOST!,
  MAIL_PORT: Number(process.env.MAIL_PORT) || 2525,
  MAIL_USER: process.env.MAIL_USER!,
  MAIL_PASS: process.env.MAIL_PASS!,
  MAIL_FROM: process.env.MAIL_FROM!,
  APP_URL: process.env.APP_URL || 'http://localhost:3000',
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || '',
  FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL || '',
  FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY || '',
  FIREBASE_SERVICE_ACCOUNT_JSON: process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '',
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
  GEMINI_TRANSLATION_API_KEY: process.env.GEMINI_TRANSLATION_API_KEY || '',
  TRANSLATION_ENABLED: process.env.TRANSLATION_ENABLED !== 'false',
  TRANSLATION_TIMEOUT_MS: Number(process.env.TRANSLATION_TIMEOUT_MS) || 4000,
  TRANSLATION_RETRY_COUNT: Number(process.env.TRANSLATION_RETRY_COUNT) || 1,
};
