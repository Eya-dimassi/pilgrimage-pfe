import type { SupportedLanguage } from '../utils/translation.provider'

declare global {
  namespace Express {
    interface Request {
      language?: SupportedLanguage
    }
  }
}

export {}
