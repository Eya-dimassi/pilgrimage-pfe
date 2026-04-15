// AST (Arabia Standard Time) is UTC+3 and has no DST.
const AST_OFFSET_MS = 3 * 60 * 60 * 1000

export function toAST(date: Date): Date {
  return new Date(date.getTime() + AST_OFFSET_MS)
}

export function fromAST(date: Date): Date {
  return new Date(date.getTime() - AST_OFFSET_MS)
}

export function startOfASTDay(date: Date): Date {
  const d = toAST(date)
  d.setUTCHours(0, 0, 0, 0)
  return fromAST(d)
}

export function isSameASTDay(left: Date, right: Date): boolean {
  return startOfASTDay(left).getTime() === startOfASTDay(right).getTime()
}

export function diffInASTDays(left: Date, right: Date): number {
  const leftDay = startOfASTDay(left)
  const rightDay = startOfASTDay(right)
  return Math.round((rightDay.getTime() - leftDay.getTime()) / (24 * 60 * 60 * 1000))
}

export function formatASTDateKey(date: Date): string {
  const astDate = toAST(date)
  const year = astDate.getUTCFullYear()
  const month = String(astDate.getUTCMonth() + 1).padStart(2, '0')
  const day = String(astDate.getUTCDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function setASTTime(date: Date, hours: number, minutes: number): Date {
  const d = toAST(date)
  d.setUTCHours(hours, minutes, 0, 0)
  return fromAST(d)
}
