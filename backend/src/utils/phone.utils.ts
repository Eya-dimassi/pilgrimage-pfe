import { parsePhoneNumberFromString } from 'libphonenumber-js'

export function normalizeInternationalPhone(value: string) {
  const normalized = value.trim()
  const phoneNumber = parsePhoneNumberFromString(normalized)

  if (!phoneNumber || !phoneNumber.isValid()) {
    throw new Error('Numero de telephone invalide. Utilisez un numero international valide.')
  }

  return phoneNumber.number
}
