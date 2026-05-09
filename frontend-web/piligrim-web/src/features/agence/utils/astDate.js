const AST_TIME_ZONE = 'Asia/Riyadh'

const AST_DATE_KEY_FORMATTER = new Intl.DateTimeFormat('en-US-u-nu-latn', {
  timeZone: AST_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
})

const AST_SHORT_DATE_FORMATTER = new Intl.DateTimeFormat('fr-FR', {
  timeZone: AST_TIME_ZONE,
  year: 'numeric',
  month: 'short',
  day: '2-digit',
})

const AST_DATETIME_FORMATTER = new Intl.DateTimeFormat('fr-FR', {
  timeZone: AST_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false,
})

export function parseAgencyDate(value) {
  if (value instanceof Date) return new Date(value.getTime())

  const raw = String(value ?? '').trim()
  if (!raw) return new Date('')

  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
    return new Date(`${raw}T00:00:00+03:00`)
  }

  return new Date(raw)
}

export function toASTDateKey(value) {
  const date = parseAgencyDate(value)
  if (Number.isNaN(date.getTime())) return ''

  const parts = AST_DATE_KEY_FORMATTER.formatToParts(date)
  const year = parts.find((part) => part.type === 'year')?.value ?? ''
  const month = parts.find((part) => part.type === 'month')?.value ?? ''
  const day = parts.find((part) => part.type === 'day')?.value ?? ''

  if (!year || !month || !day) return ''
  return `${year}-${month}-${day}`
}

export function formatASTShortDate(value) {
  const date = parseAgencyDate(value)
  if (Number.isNaN(date.getTime())) return ''
  return AST_SHORT_DATE_FORMATTER.format(date)
}

export function formatASTDateTime(value) {
  const date = parseAgencyDate(value)
  if (Number.isNaN(date.getTime())) return ''
  return AST_DATETIME_FORMATTER.format(date)
}

