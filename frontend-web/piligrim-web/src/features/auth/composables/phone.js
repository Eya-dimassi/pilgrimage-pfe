import { parsePhoneNumberFromString } from 'libphonenumber-js'

export function parseInternationalPhone(value) {
  const normalized = String(value || '').trim()
  if (!normalized) return null

  const phoneNumber = parsePhoneNumberFromString(normalized)
  if (!phoneNumber || !phoneNumber.isValid()) {
    return null
  }

  return phoneNumber
}

export function isValidInternationalPhone(value) {
  return Boolean(parseInternationalPhone(value))
}

export function normalizeInternationalPhone(value) {
  return parseInternationalPhone(value)?.number ?? ''
}
