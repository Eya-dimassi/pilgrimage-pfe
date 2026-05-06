import { startOfASTDay } from '../planning/date.utils'

export type EffectiveGroupStatus = 'PLANIFIE' | 'EN_COURS' | 'TERMINE' | 'ANNULE'

type GroupStatusInput = {
  status?: string | null
  dateDepart?: Date | null
  dateRetour?: Date | null
}

export function getEffectiveGroupStatus(
  group: GroupStatusInput,
  referenceDate: Date = new Date(),
): EffectiveGroupStatus {
  if (group.status === 'ANNULE') {
    return 'ANNULE'
  }

  if (!group.dateDepart && !group.dateRetour) {
    return (group.status as EffectiveGroupStatus | null) ?? 'PLANIFIE'
  }

  const today = startOfASTDay(referenceDate).getTime()
  const tripStart = startOfASTDay(group.dateDepart ?? group.dateRetour ?? referenceDate).getTime()
  const tripEnd = startOfASTDay(group.dateRetour ?? group.dateDepart ?? referenceDate).getTime()

  if (today < tripStart) {
    return 'PLANIFIE'
  }

  if (today > tripEnd) {
    return 'TERMINE'
  }

  return 'EN_COURS'
}

export function withEffectiveGroupStatus<
  T extends {
    status?: string | null
    dateDepart?: Date | null
    dateRetour?: Date | null
  },
>(group: T, referenceDate: Date = new Date()): Omit<T, 'status'> & { status: EffectiveGroupStatus } {
  return {
    ...group,
    status: getEffectiveGroupStatus(group, referenceDate),
  }
}

export function sortGroupsByEffectiveStatus<
  T extends {
    status?: string | null
    dateDepart?: Date | null
    dateRetour?: Date | null
    annee?: number | null
  },
>(groups: T[], referenceDate: Date = new Date()): T[] {
  const priority = (group: T) => {
    switch (getEffectiveGroupStatus(group, referenceDate)) {
      case 'EN_COURS':
        return 0
      case 'PLANIFIE':
        return 1
      case 'TERMINE':
        return 2
      case 'ANNULE':
        return 3
      default:
        return 4
    }
  }

  return [...groups].sort((left, right) => {
    const priorityDiff = priority(left) - priority(right)
    if (priorityDiff !== 0) return priorityDiff

    const leftStart = left.dateDepart?.getTime() ?? 0
    const rightStart = right.dateDepart?.getTime() ?? 0
    if (leftStart !== rightStart) return rightStart - leftStart

    const leftEnd = left.dateRetour?.getTime() ?? 0
    const rightEnd = right.dateRetour?.getTime() ?? 0
    if (leftEnd !== rightEnd) return rightEnd - leftEnd

    return (right.annee ?? 0) - (left.annee ?? 0)
  })
}

export async function syncEffectiveStatuses<T extends {
    id: string
    status?: string | null
    dateDepart?: Date | null
    dateRetour?: Date | null
  },
>(
  updateStatus: (id: string, currentStatus: string | null | undefined, nextStatus: EffectiveGroupStatus) => Promise<unknown>,
  groups: T[],
  referenceDate: Date = new Date(),
) {
  const normalized = groups.map((group) => withEffectiveGroupStatus(group, referenceDate))

  const updates = normalized
  .map((group, index) => ({ group, original: groups[index] }))
  .filter(({ group, original }) => group.status !== (original.status ?? null))
  .map(({ group, original }) => updateStatus(group.id, original.status, group.status))

  if (updates.length) {
    await Promise.all(updates)
  }

  return normalized
}
