import prisma from '../../../config/prisma'
import { Prisma } from '../../../../generated/prisma/client'
import { isSameASTDay, startOfASTDay } from '../../agences/planning/date.utils'
import {
  sortGroupsByEffectiveStatus,
  syncEffectiveStatuses,
  withEffectiveGroupStatus,
} from '../../agences/groupes/group-status.utils'
import { sendPushToUsers } from '../../../utils/push-notifications.utils'
import { SupportedLanguage, translateBatch } from '../../../utils/translation.provider'

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
  status: MobileEventStatus | null
  estValide: boolean | null
  valideeAt: Date | null
  valideParGuideId: string | null
}

type MobileEventStatus = 'PLANIFIE' | 'EN_COURS' | 'TERMINE' | 'ANNULE'

type OrderedGroupEventRow = {
  id: string
  titre: string
  status: MobileEventStatus | null
  etape: string | null
  heureDebutPrevue: Date | null
  createdAt: Date
  planningDate: Date
}

type TranslatablePlanningEvent = {
  type?: string | null
  titre: string
  description?: string | null
  lieu?: string | null
  etape?: string | null
}

const EVENT_TYPE_LABELS_FR: Record<string, string> = {
  PRIERE: 'Prière',
  TRANSPORT: 'Transport',
  VISITE: 'Visite',
  REPAS: 'Repas',
  RITE: 'Rite',
  REPOS: 'Repos',
  AUTRE: 'Autre',
}

function getEventTypeLabel(type: string | null | undefined) {
  return EVENT_TYPE_LABELS_FR[String(type ?? '').trim().toUpperCase()] ?? EVENT_TYPE_LABELS_FR.AUTRE
}

function isResolvedEventStatus(status: MobileEventStatus | null | undefined) {
  return status === 'TERMINE' || status === 'ANNULE'
}

function isCompletedEventStatus(status: MobileEventStatus | null | undefined) {
  return status === 'TERMINE'
}

async function translatePlanningResponse<
  T extends { plannings: Array<{ evenements: TranslatablePlanningEvent[] }> },
>(payload: T, language: SupportedLanguage): Promise<T> {
  const fields = payload.plannings.flatMap((planning, planningIndex) =>
    planning.evenements.flatMap((event, eventIndex) => [
      {
        key: `event:${planningIndex}:${eventIndex}:typeLabel`,
        text: getEventTypeLabel(event.type),
      },
      {
        key: `event:${planningIndex}:${eventIndex}:titre`,
        text: event.titre,
      },
      {
        key: `event:${planningIndex}:${eventIndex}:description`,
        text: event.description,
      },
      {
        key: `event:${planningIndex}:${eventIndex}:lieu`,
        text: event.lieu,
      },
      {
        key: `event:${planningIndex}:${eventIndex}:etape`,
        text: event.etape,
      },
    ]),
  )
  const translatedByKey = new Map(
    language === 'fr'
      ? fields.map((item) => [item.key, item.text ?? null] as const)
      : (await translateBatch(fields, language)).map((item) => [item.key, item.text] as const),
  )

  const plannings = await Promise.all(
    payload.plannings.map(async (planning, planningIndex) => ({
      ...planning,
      evenements: planning.evenements.map((event, eventIndex) => ({
        ...event,
        typeLabel:
          translatedByKey.get(`event:${planningIndex}:${eventIndex}:typeLabel`) ??
          getEventTypeLabel(event.type),
        titre:
          translatedByKey.get(`event:${planningIndex}:${eventIndex}:titre`) ??
          event.titre,
        description: translatedByKey.get(
          `event:${planningIndex}:${eventIndex}:description`,
        ),
        lieu: translatedByKey.get(`event:${planningIndex}:${eventIndex}:lieu`),
        etape: translatedByKey.get(`event:${planningIndex}:${eventIndex}:etape`),
      })),
    })),
  )

  return {
    ...payload,
    plannings,
  }
}

function sortMobileGroups<T extends { status?: string | null; dateDepart?: Date | null; dateRetour?: Date | null; annee?: number | null }>(
  groups: T[],
) {
  return sortGroupsByEffectiveStatus(groups)
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

    const groups = relations
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

    return sortMobileGroups(await syncEffectiveStatuses(
      (id, currentStatus, nextStatus) =>
        prisma.groupe.updateMany({
          where: {
            id,
            ...(currentStatus ? { status: currentStatus as 'PLANIFIE' | 'EN_COURS' | 'TERMINE' | 'ANNULE' } : {}),
          },
          data: { status: nextStatus },
        }),
      groups,
    ))
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

    const groups = relations
      .map((relation) => relation.groupe)
      .filter((groupe): groupe is NonNullable<typeof groupe> => Boolean(groupe))

    return sortMobileGroups(await syncEffectiveStatuses(
      (id, currentStatus, nextStatus) =>
        prisma.groupe.updateMany({
          where: {
            id,
            ...(currentStatus ? { status: currentStatus as 'PLANIFIE' | 'EN_COURS' | 'TERMINE' | 'ANNULE' } : {}),
          },
          data: { status: nextStatus },
        }),
      groups,
    ))
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

    const selectedGroups = relations
      .map((relation) => {
        const candidateGroups = relation.pelerin?.groupes
          ?.map((membership) => membership.groupe)
          .filter((groupe): groupe is NonNullable<typeof groupe> => Boolean(groupe)) ?? []

        if (!candidateGroups.length) {
          return null
        }

        return sortMobileGroups(candidateGroups.map((groupe) => withEffectiveGroupStatus(groupe)))[0]
      })
      .filter((groupe): groupe is NonNullable<typeof groupe> => Boolean(groupe))

    const normalizedGroups = await syncEffectiveStatuses(
      (id, currentStatus, nextStatus) =>
        prisma.groupe.updateMany({
          where: {
            id,
            ...(currentStatus ? { status: currentStatus as 'PLANIFIE' | 'EN_COURS' | 'TERMINE' | 'ANNULE' } : {}),
          },
          data: { status: nextStatus },
        }),
      selectedGroups,
    )
    const dedupedGroups = Array.from(new Map(normalizedGroups.map((groupe) => [groupe.id, groupe])).values())

    return sortMobileGroups(dedupedGroups)
  }

  throw new Error('Role mobile non pris en charge')
}

// Returns all groups linked to a pelerin (active and past) for history screens.
export async function getMobilePelerinGroupHistory(userId: string, role: string) {
  if (role !== 'PELERIN') {
    throw new Error('Seul un pelerin peut consulter cet historique')
  }

  const relations = await prisma.groupePelerin.findMany({
    where: {
      pelerin: { utilisateurId: userId },
    },
    orderBy: [
      { actif: 'desc' },
      { dateDebut: 'desc' },
    ],
    select: {
      actif: true,
      dateDebut: true,
      groupe: {
        select: MOBILE_GROUP_SELECT,
      },
    },
  })

  // Keep one entry per group to avoid duplicates when assignment history has multiple rows.
  const uniqueByGroupId = new Map<
    string,
    {
      relationActive: boolean
      relationDateDebut: Date | null
      groupe: NonNullable<(typeof relations)[number]['groupe']>
    }
  >()

  for (const relation of relations) {
    const groupe = relation.groupe
    if (!groupe) continue
    if (uniqueByGroupId.has(groupe.id)) continue

    uniqueByGroupId.set(groupe.id, {
      relationActive: relation.actif,
      relationDateDebut: relation.dateDebut,
      groupe,
    })
  }

  return Array.from(uniqueByGroupId.values())
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
  return updateMobilePlanningEventStatus(userId, role, groupeId, eventId, 'TERMINE')
}

export async function updateMobilePlanningEventStatus(
  userId: string,
  role: string,
  groupeId: string,
  eventId: string,
  statusInput: string,
) {
  if (role !== 'GUIDE') {
    throw new Error('Seul un guide peut mettre a jour le statut d un evenement')
  }

  const status = statusInput as MobileEventStatus
  if (status !== 'TERMINE' && status !== 'ANNULE') {
    throw new Error('Statut evenement non pris en charge')
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
      ep."status",
      ep."etape",
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
    SELECT "id", "status", "estValide", "valideeAt", "valideParGuideId"
    FROM "EvenementPlanning"
    WHERE "id" = ${targetEvent.id}
    LIMIT 1
  `

  if (targetEvent.status === status) {
    return {
      message:
        status === 'ANNULE' ? 'Evenement deja annule' : 'Evenement deja termine',
      evenement: existingValidation[0],
    }
  }

  if (isResolvedEventStatus(targetEvent.status)) {
    throw new Error('Cet evenement a deja un statut final')
  }

  let previousPendingEvent: OrderedGroupEventRow | null = null
  for (let index = eventIndex - 1; index >= 0; index -= 1) {
    if (!isResolvedEventStatus(orderedEvents[index].status)) {
      previousPendingEvent = orderedEvents[index]
      break
    }
  }

  if (previousPendingEvent) {
    throw new Error(
      `Action refusee: terminez d abord l evenement precedent (${previousPendingEvent.titre}).`,
    )
  }

  const updatedRows = await prisma.$queryRaw<EventValidationRow[]>`
    UPDATE "EvenementPlanning"
    SET
      "status" = ${status}::"StatutEvenement",
      "estValide" = ${status === 'TERMINE'},
      "valideParGuideId" = ${status === 'TERMINE' ? guide.id : null},
      "valideeAt" = ${status === 'TERMINE' ? Prisma.sql`NOW()` : null}
    WHERE "id" = ${targetEvent.id}
    RETURNING "id", "status", "estValide", "valideeAt", "valideParGuideId"
  `

  if (!updatedRows.length) {
    throw new Error('Evenement introuvable dans ce groupe')
  }

  const groupeContext = await prisma.groupe.findUnique({
    where: { id: groupeId },
    select: {
      nom: true,
      membres: {
        where: { actif: true },
        select: {
          pelerin: {
            select: {
              utilisateurId: true,
              familles: {
                where: { actif: true },
                select: {
                  famille: {
                    select: {
                      utilisateurId: true,
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  })

  if (groupeContext) {
    const pelerinUserIds = Array.from(
      new Set(
        groupeContext.membres
          .map((membership) => membership.pelerin.utilisateurId)
          .filter(Boolean),
      ),
    )

    const familleUserIds = Array.from(
      new Set(
        groupeContext.membres
          .flatMap((membership) => membership.pelerin.familles)
          .map((association) => association.famille.utilisateurId)
          .filter(Boolean),
      ),
    )

    const etapeLabel = targetEvent.etape ?? targetEvent.titre
    const notificationData = {
      type: 'alert',
      tab: 'alerts',
      groupeId,
      eventId: targetEvent.id,
      etape: String(etapeLabel),
      status,
    }

    const pelerinTitle = status === 'ANNULE' ? 'Etape annulee' : 'Etape terminee'
    const familleTitle =
      status === 'ANNULE' ? 'Nouvelle etape annulee' : 'Nouvelle etape terminee'
    const pelerinBody =
      status === 'ANNULE'
        ? `Le groupe ${groupeContext.nom} a annule ${etapeLabel}.`
        : `Le groupe ${groupeContext.nom} est passe a ${etapeLabel}.`
    const familleBody =
      status === 'ANNULE'
        ? `${groupeContext.nom} a annule ${etapeLabel}.`
        : `${groupeContext.nom} est passe a ${etapeLabel}.`

    if (pelerinUserIds.length) {
      await sendPushToUsers({
        userIds: pelerinUserIds,
        role: 'PELERIN',
        title: pelerinTitle,
        body: pelerinBody,
        data: notificationData,
      })
    }

    if (familleUserIds.length) {
      await sendPushToUsers({
        userIds: familleUserIds,
        role: 'FAMILLE',
        title: familleTitle,
        body: familleBody,
        data: notificationData,
      })
    }
  }

  return {
    message:
      status === 'ANNULE'
        ? 'Evenement annule avec succes'
        : 'Evenement termine avec succes',
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
    SELECT "id", "status", "estValide", "valideeAt", "valideParGuideId"
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
        status: validation?.status ?? null,
        estValide: isCompletedEventStatus(validation?.status) || Boolean(validation?.estValide),
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

function keepFromTripStart<T extends { date: Date }>(
  plannings: T[],
  dateDepart: Date | null,
): T[] {
  if (!dateDepart) return plannings
  const tripStart = startOfASTDay(dateDepart)
  return plannings.filter((planning) =>
    startOfASTDay(planning.date).getTime() >= tripStart.getTime(),
  )
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
  language: SupportedLanguage,
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

  let visiblePlannings = dayOffsets.length === 1 && dayOffsets[0] === 0
    ? (() => {
        const selectedPlanning = pickVisiblePlanningDay(plannings)
        return selectedPlanning == null ? [] : [selectedPlanning]
      })()
    : pickVisiblePlanningWindow(plannings, dayOffsets)

  if (role === 'PELERIN') {
    visiblePlannings = keepFromTripStart(visiblePlannings, groupe.dateDepart)
  }

  visiblePlannings.sort((left, right) => left.date.getTime() - right.date.getTime())
  const planningsWithValidation = await attachEventValidation(visiblePlannings)

  return translatePlanningResponse({
    groupe: withEffectiveGroupStatus(groupe),
    plannings: planningsWithValidation,
  }, language)
}

// Returns the full read-only planning for one accessible group.
export async function getMobilePlanningForGroup(
  userId: string,
  role: string,
  groupeId: string,
  language: SupportedLanguage = 'fr',
) {
  if (role === 'FAMILLE') {
    return getWindowedPlanningForGroup(userId, role, groupeId, [0], language)
  }

  if (role === 'PELERIN') {
    return getWindowedPlanningForGroup(userId, role, groupeId, [-1, 0, 1], language)
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
  const visiblePlannings = keepFromTripStart(plannings, groupe.dateDepart)
  const planningsWithValidation = await attachEventValidation(visiblePlannings)

  return translatePlanningResponse({
    groupe: withEffectiveGroupStatus(groupe),
    plannings: planningsWithValidation,
  }, language)
}
