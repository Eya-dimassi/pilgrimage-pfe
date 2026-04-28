export function planningEventOrderBy() {
  return [
    { heureDebutPrevue: 'asc' as const },
    { createdAt: 'asc' as const },
  ]
}
