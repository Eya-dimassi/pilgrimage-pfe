import { NextFunction, Request, Response } from 'express'
import { normalizeLanguage } from '../utils/translation.provider'

export function requestLanguageMiddleware(req: Request, _res: Response, next: NextFunction) {
  req.language = normalizeLanguage(req.headers['accept-language'])
  next()
}
