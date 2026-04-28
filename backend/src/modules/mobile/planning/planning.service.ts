import prisma from '../../../config/prisma'
import { Prisma } from '../../../../generated/prisma/client'
import { isSameASTDay, startOfASTDay } from '../../agences/planning/date.utils'

const MOBILE_GROUP_SELECT = {
  id: true,
  nom: true,
  annee: true,
  typeVoyage: true,
  dateDepart: true,
  dateRetour: true,
  status: true,
} as const

const MOBILE_GROUP_WITH_COUNT_SELECT = {
  ...MOBILE_GROUP_SELECT,
  _count: {
    select: {
      membres: {
        where: { actif: true },
      },
    },
  },
} as const

type EventValidationRow = {
  id: string
  estValide: boolean | null
  valideeAt: Date | null
  valideParGuideId: string | null
}

type OrderedGroupEventRow = {
  id: string
  titre: string
  estValide: boolean | null
  heureDebutPrevue: Date | null
  createdAt: Date
  planningDate: Date
}

// Resolves the currently authenticated mobile user into the active groups they can consult.
export async function getMobilePlanningGroups(userId: string, role: string) {
  if (role === 'GUIDE') {
    const relations = await prisma.groupeGuide.findMany({
      where: {
        actif: true,
        guide: { utilisateurId: userId },
      },
      orderBy: { dateDebut: 'desc' },
      select: {
        groupe: {
          select: MOBILE_GROUP_WITH_COUNT_SELECT,
        },
      },
    })

    return relations
      .map((relation) => {
        const groupe = relation.groupe
        if (!groupe) return null
        const { _count, ...rest } = groupe
        return {
          ...rest,
          nbPelerins: _count.membres,
        }
      })
      .filter((groupe): groupe is NonNullable<typeof groupe> => Boolean(groupe))
  }

  if (role === 'PELERIN') {
    const relations = await prisma.groupePelerin.findMany({
      where: {
        actif: true,
        pelerin: { utilisateurId: userId },
      },
      orderBy: { dateDebut: 'desc' },
      select: {
        groupe: {
          select: MOBILE_GROUP_SELECT,
        },
      },
    })

    return relations
      .map((relation) => relation.groupe)
      .filter((groupe): groupe is NonNullable<typeof groupe> => Boolean(groupe))
  }

  if (role === 'FAMILLE') {
    const relations = await prisma.famillePelerin.findMany({
      where: {
        actif: true,
        famille: { utilisateurId: userId },
      },
      orderBy: { createdAt: 'desc' },
      select: {
        pelerin: {
          select: {
            groupes: {
              where: { actif: true },
              orderBy: { dateDebut: 'desc' },
              take: 1,
              select: {
                groupe: {
                  select: MOBILE_GROUP_SELECT,
                },
              },
            },
          },
        },
      },
    })

    const groupes = relations
      .map((relation) => relation.pelerin?.groupes?.[0]?.groupe ?? null)
      .filter((groupe): groupe is NonNullable<typeof groupe> => Boolean(groupe))

    return Array.from(new Map(groupes.map((groupe) => [groupe.id, groupe])).values())
  }

  throw new Error('Role mobile non pris en charge')
}

// Verifies that the mobile user can access the requested group planning.
async function assertMobilePlanningAccess(userId: string, role: string, groupeId: string) {
  if (role === 'GUIDE') {
    const relation = await prisma.groupeGuide.findFirst({
      where: {
        groupeId,
        actif: true,
        guide: { utilisateurId: userId },
      },
      select: { id: true },
    })

    if (!relation) {
      throw new Error('Acces refuse a ce planning')
    }

    return
  }

  if (role === 'PELERIN') {
    const relation = await prisma.groupePelerin.findFirst({
      where: {
        groupeId,
        actif: true,
        pelerin: { utilisateurId: userId },
      },
      select: { id: true },
    })

    if (!relation) {
      throw new Error('Acces refuse a ce planning')
    }

    return
  }

  if (role === 'FAMILLE') {
    const relation = await prisma.famillePelerin.findFirst({
      where: {
        actif: true,
        famille: { utilisateurId: userId },
        pelerin: {
          groupes: {
            some: {
              groupeId,
              actif: true,
            },
          },
        },
      },
      select: { id: true },
    })

    if (!relation) {
      throw new Error('Acces refuse a ce planning')
    }

    return
  }

  throw new Error('Role mobile non pris en charge')
}

export async function validateMobilePlanningEvent(
  userId: string,
  role: string,
  groupeId: string,
  eventId: string,
) {
  if (role !== 'GUIDE') {
    throw new Error('Seul un guide peut valider un evenement')
  }

  await assertMobilePlanningAccess(userId, role, groupeId)

  const guide = await prisma.guide.findUnique({
    where: { utilisateurId: userId },
    select: { id: true },
  })

  if (!guide) {
    throw new Error('Profil guide introuvable')
  }

  const orderedEvents = await prisma.$queryRaw<OrderedGroupEventRow[]>`
    SELECT
      ep."id",
      ep."titre",
      ep."estValide",
      ep."heureDebutPrevue",
      ep."createdAt",
      pq."date" AS "planningDate"
    FROM "EvenementPlanning" ep
    INNER JOIN "PlanningQuotidien" pq ON pq."id" = ep."planningQuotidienId"
    WHERE pq."groupeId" = ${groupeId}
    ORDER BY
      pq."date" ASC,
      CASE WHEN ep."heureDebutPrevue" IS NULL THEN 1 ELSE 0 END ASC,
      ep."heureDebutPrevue" ASC,
      ep."createdAt" ASC,
      ep."id" ASC
  `

  const eventIndex = orderedEvents.findIndex((event) => event.id === eventId)

  if (eventIndex < 0) {
    throw new Error('Evenement introuvable dans ce groupe')
  }

  const targetEvent = orderedEvents[eventIndex]

  const existingValidation = await prisma.$queryRaw<EventValidationRow[]>`
    SELECT "id", "estValide", "valideeAt", "valideParGuideId"
    FROM "EvenementPlanning"
    WHERE "id" = ${targetEvent.id}
    LIMIT 1
  `

  if (targetEvent.estValide) {
    return {
      message: 'Evenement deja valide',
      evenement: existingValidation[0],
    }
  }

  let previousPendingEvent: OrderedGroupEventRow | null = null
  for (let index = eventIndex - 1; index >= 0; index -= 1) {
    if (!orderedEvents[index].estValide) {
      previousPendingEvent = orderedEvents[index]
      break
    }
  }

  if (previousPendingEvent) {
    throw new Error(
      `Validation refusee: validez d'abord l'evenement precedent (${previousPendingEvent.titre}).`,
    )
  }

  const updatedRows = await prisma.$queryRaw<EventValidationRow[]>`
    UPDATE "EvenementPlanning"
    SET
      "estValide" = TRUE,
      "valideParGuideId" = ${guide.id},
      "valideeAt" = NOW()
    WHERE "id" = ${targetEvent.id}
    RETURNING "id", "estValide", "valideeAt", "valideParGuideId"
  `

  if (!updatedRows.length) {
    throw new Error('Evenement introuvable dans ce groupe')
  }

  return {
    message: 'Evenement valide avec succes',
    evenement: updatedRows[0],
  }
}

export async function getMobileGroupPelerins(
  userId: string,
  role: string,
  groupeId: string,
) {
  if (role !== 'GUIDE') {
    throw new Error('Seul un guide peut consulter la liste des pelerins')
  }

  await assertMobilePlanningAccess(userId, role, groupeId)

  const groupe = await prisma.groupe.findUnique({
    where: { id: groupeId },
    select: {
      membres: {
        where: { actif: true },
        select: {
          pelerin: {
            select: {
              id: true,
              utilisateur: {
                select: {
                  nom: true,
                  prenom: true,
                  telephone: true,
                },
              },
            },
          },
        },
      },
    },
  })

  if (!groupe) {
    throw new Error('Groupe introuvable')
  }

  return groupe.membres
    .map((membre) => ({
      id: membre.pelerin.id,
      nom: membre.pelerin.utilisateur.nom,
      prenom: membre.pelerin.utilisateur.prenom,
      telephone: membre.pelerin.utilisateur.telephone,
    }))
    .sort((a, b) =>
      `${a.prenom} ${a.nom}`.localeCompare(`${b.prenom} ${b.nom}`, 'fr', {
        sensitivity: 'base',
      }),
    )
}

async function attachEventValidation<T extends { evenements: Array<{ id: string }> }>(
  plannings: T[],
) {
  const eventIds = plannings.flatMap((planning) => planning.evenements.map((event) => event.id))

  if (!eventIds.length) {
    return plannings
  }

  const rows = await prisma.$queryRaw<EventValidationRow[]>`
    SELECT "id", "estValide", "valideeAt", "valideParGuideId"
    FROM "EvenementPlanning"
    WHERE "id" IN (${Prisma.join(eventIds)})
  `
  const validationByEventId = new Map(rows.map((row) => [row.id, row]))

  return plannings.map((planning) => ({
    ...planning,
    evenements: planning.evenements.map((event) => {
      const validation = validationByEventId.get(event.id)
      return {
        ...event,
        estValide: Boolean(validation?.estValide),
        valideeAt: validation?.valideeAt ?? null,
        valideParGuideId: validation?.valideParGuideId ?? null,
      }
    }),
  }))
}

// Picks today's planning day for day-only mobile views.
function pickVisiblePlanningDay<T extends { date: Date }>(plannings: T[]): T | null {
  const today = startOfASTDay(new Date())
  return plannings.find((planning) => isSameASTDay(planning.date, today)) ?? null
}

function shiftASTDay(baseDay: Date, offsetDays: number): Date {
  const DAY_MS = 24 * 60 * 60 * 1000
  return new Date(baseDay.getTime() + offsetDays * DAY_MS)
}

// Picks a limited day window around today (for example yesterday/today/tomorrow).
function pickVisiblePlanningWindow<T extends { date: Date }>(
  plannings: T[],
  offsets: number[],
): T[] {
  const today = startOfASTDay(new Date())
  const targetDays = offsets.map((offset) => shiftASTDay(today, offset))

  return plannings.filter((planning) =>
    targetDays.some((targetDay) => isSameASTDay(planning.date, targetDay)),
  )
}

// Returns only the planning day relevant to a mobile day-only role.
async function getWindowedPlanningForGroup(
  userId: string,
  role: 'FAMILLE' | 'PELERIN',
  groupeId: string,
  dayOffsets: number[],
) {
  await assertMobilePlanningAccess(userId, role, groupeId)

  const groupe = await prisma.groupe.findUnique({
    where: { id: groupeId },
    select: MOBILE_GROUP_SELECT,
  })

  if (!groupe) {
    throw new Error('Groupe introuvable')
  }

  const plannings = await prisma.planningQuotidien.findMany({
    where: { groupeId },
    orderBy: { date: 'asc' },
    include: {
      evenements: {
        orderBy: [
          { heureDebutPrevue: 'asc' },
          { createdAt: 'asc' },
        ],
      },
    },
  })

  const visiblePlannings: any[] = dayOffsets.length === 1 && dayOffsets[0] === 0
    ? (() => {
        const selectedPlanning = pickVisiblePlanningDay(plannings)
        return selectedPlanning == null ? [] : [selectedPlanning]
      })()
    : pickVisiblePlanningWindow(plannings, dayOffsets)

  // For pelerin only: keep J-1 visible as an empty day when it is before trip start.
  if (role === 'PELERIN' && dayOffsets.includes(-1) && groupe.dateDepart) {
    const today = startOfASTDay(new Date())
    const yesterday = shiftASTDay(today, -1)
    const tripStart = startOfASTDay(groupe.dateDepart)
    const hasYesterdayPlanning = visiblePlannings.some((planning) =>
      isSameASTDay(planning.date, yesterday),
    )

    if (yesterday.getTime() < tripStart.getTime() && !hasYesterdayPlanning) {
      visiblePlannings.unshift({
        id: `virtual-pretrip-${groupeId}-${yesterday.toISOString()}`,
        date: yesterday,
        titre: null,
        evenements: [],
      })
    }
  }

  visiblePlannings.sort((left, right) => left.date.getTime() - right.date.getTime())
  const planningsWithValidation = await attachEventValidation(visiblePlannings)

  return {
    groupe,
    plannings: planningsWithValidation,
  }
}

// Returns the full read-only planning for one accessible group.
export async function getMobilePlanningForGroup(userId: string, role: string, groupeId: string) {
  if (role === 'FAMILLE') {
    return getWindowedPlanningForGroup(userId, role, groupeId, [0])
  }

  if (role === 'PELERIN') {
    return getWindowedPlanningForGroup(userId, role, groupeId, [-1, 0, 1])
  }

  await assertMobilePlanningAccess(userId, role, groupeId)

  const groupe = await prisma.groupe.findUnique({
    where: { id: groupeId },
    select: MOBILE_GROUP_SELECT,
  })

  if (!groupe) {
    throw new Error('Groupe introuvable')
  }

  const plannings = await prisma.planningQuotidien.findMany({
    where: { groupeId },
    orderBy: { date: 'asc' },
    include: {
      evenements: {
        orderBy: [
          { heureDebutPrevue: 'asc' },
          { createdAt: 'asc' },
        ],
      },
    },
  })
  const planningsWithValidation = await attachEventValidation(plannings)

  return {
    groupe,
    plannings: planningsWithValidation,
  }
}
