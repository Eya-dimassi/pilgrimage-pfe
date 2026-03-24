export const PASSWORD_MIN_LENGTH = 8

export function normalizeQueryToken(token) {
  return typeof token === 'string' ? token.trim() : ''
}

export function hasUppercase(value) {
  return /[A-Z]/.test(value)
}

export function hasDigit(value) {
  return /[0-9]/.test(value)
}

export function isStrongPassword(value) {
  return value.length >= PASSWORD_MIN_LENGTH && hasUppercase(value) && hasDigit(value)
}

export function getPasswordStrength(value) {
  let score = 0

  if (value.length >= PASSWORD_MIN_LENGTH) score += 25
  if (value.length >= 12) score += 25
  if (hasUppercase(value)) score += 25
  if (/[0-9!@#$%^&*]/.test(value)) score += 25

  return {
    pct: score,
    label: score <= 25 ? 'Faible' : score <= 50 ? 'Moyen' : score <= 75 ? 'Bon' : 'Fort',
    color: score <= 25 ? '#f87171' : score <= 50 ? '#fb923c' : score <= 75 ? '#c9a84c' : '#4ade80',
  }
}

export function validatePasswordConfirmation(password, confirm) {
  if (password.length < PASSWORD_MIN_LENGTH) {
    return `Le mot de passe doit contenir au moins ${PASSWORD_MIN_LENGTH} caracteres.`
  }

  if (!hasUppercase(password)) {
    return 'Le mot de passe doit contenir au moins une lettre majuscule.'
  }

  if (!hasDigit(password)) {
    return 'Le mot de passe doit contenir au moins un chiffre.'
  }

  if (password !== confirm) {
    return 'Les mots de passe ne correspondent pas.'
  }

  return ''
}
