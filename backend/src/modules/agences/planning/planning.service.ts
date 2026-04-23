import { addDays, isWithinInterval, parseISO } from 'date-fns'
import prisma from '../../../config/prisma'
import { buildHajjPlan, buildUmrahPlan, type TemplateDay } from './planning.templates'
import { diffInASTDays, formatASTDateKey, isSameASTDay, startOfASTDay } from './date.utils'
import { sendPushToUsers } from '../../../utils/push-notifications.utils'

const PLANNING_WINDOW_MARGIN_DAYS = 1

const HIJRI_HAJJ_LABELS: Record<number, string> = {
  8: '8 Dhul Hijja',
  9: '9 Dhul Hijja',
  10: '10 Dhul Hijja',
  11: '11 Dhul Hijja',
  12: '12 Dhul Hijja',
  13: '13 Dhul Hijja',
}

type PlanningPayload = {
  date: string | Date
  titre?: string
}

type ShiftPlanningPayload = {
  offsetDays: number
}

type EventPayload = {
  type: 'PRIERE' | 'TRANSPORT' | 'VISITE' | 'REPAS' | 'RITE' | 'REPOS' | 'AUTRE'
  titre: string
  description?: string
  lieu?: string | string[]
  heureDebutPrevue?: string | Date
}

const GROUP_PLANNING_SELECT = {
  id: true,
  nom: true,
  typeVoyage: true,
  status: true,
  dateDepart: true,
  dateRetour: true,
  hajjStartDate: true,
  annee: true,
} as const

// Parses a date input coming from the API. 
// If no offset is provided, it assumes AST (+03:00).
function parseInputDate(value: string | Date, fieldName: string) {
  if (value instanceof Date) return value
  
  let str = value.trim()
  if (!str.includes('Z') && !/[+-]\d{2}:?\d{2}$/.test(str)) {
    if (/^\d{4}-\d{2}-\d{2}$/.test(str)) {
      str += 'T00:00:00'
    }
    str += '+03:00'
  }
  
  const date = parseISO(str)
  if (Number.isNaN(date.getTime())) throw new Error(`${fieldName} invalide`)
  return date
}

// Normalizes a date to the start of the AST day.
function normalizeDateOnly(value: string | Date) {
  return startOfASTDay(parseInputDate(value, 'date'))
}

// Normalizes a datetime value.
function normalizeDateTime(value: string | Date, fieldName: string) {
  return parseInputDate(value, fieldName)
}

function planningEventOrderBy() {
  return [
    { heureDebutPrevue: 'asc' as const },
    { createdAt: 'asc' as const },
  ]
}

// Converts one or many lieux values into the single DB string format used by events.
function normalizeLieu(value?: string | string[] | null) {
  const items = (Array.isArray(value) ? value : [value ?? ''])
    .map((item) => String(item).trim())
    .filter(Boolean)
  return items.length ? items.join(' • ') : null
}

function buildTemplateEventData(event: TemplateDay['events'][number]) {
  return {
    titre: event.titre,
    type: event.type,
    description: event.description ?? null,
    lieu: normalizeLieu(event.lieu),
    etape: event.etape ?? null, // ← new
  }
}

function getTripLength(groupe: Awaited<ReturnType<typeof getOwnedGroupe>>) {
  if (!groupe.dateDepart || !groupe.dateRetour) return 0
  return diffInASTDays(groupe.dateDepart, groupe.dateRetour) + 1
}

function getHajjFixedLabel(groupe: Awaited<ReturnType<typeof getOwnedGroupe>>, dayNumber: number) {
  if (groupe.typeVoyage !== 'HAJJ' || !groupe.hajjStartDate || !groupe.dateDepart) {
    return null
  }

  const anchorDayNumber = diffInASTDays(groupe.dateDepart, groupe.hajjStartDate) + 1
  const hijriDay = 8 + (dayNumber - anchorDayNumber)

  return HIJRI_HAJJ_LABELS[hijriDay] ?? null
}

function buildTripDays(groupe: Awaited<ReturnType<typeof getOwnedGroupe>>) {
  if (!groupe.dateDepart || !groupe.dateRetour) return []

  const totalDays = getTripLength(groupe)

  return Array.from({ length: totalDays }, (_, index) => {
    const dayNumber = index + 1
    const currentDate = addDays(startOfASTDay(groupe.dateDepart!), index)
    const primaryDayLabel = getHajjFixedLabel(groupe, dayNumber) ?? `Jour ${dayNumber}`
    const secondaryDayLabel = primaryDayLabel.startsWith('Jour ')
      ? ''
      : `Jour ${dayNumber} du voyage`

    return {
  dateKey: formatASTDateKey(currentDate),
  dayNumber,
  date: currentDate,
  primaryDayLabel,
  secondaryDayLabel,
  label: currentDate.toLocaleDateString('fr-FR', { weekday: 'long', day: '2-digit', month: 'long' }),
  calendarDay: String(currentDate.getUTCDate()).padStart(2, '0'),
  monthShort: currentDate.toLocaleDateString('fr-FR', { month: 'short' }),
  locationLabel: '',
}
  })
}

// Resolves a scoped Prisma lookup and throws a consistent not-found error when needed.
async function findOrThrow<T>(query: Promise<T | null>, label: string): Promise<T> {
  const result = await query
  if (!result) throw new Error(`${label} introuvable`)
  return result
}

// Loads one group owned by the current agence and exposes only planning-relevant fields.
async function getOwnedGroupe(agenceId: string, groupeId: string) {
  return findOrThrow(
    prisma.groupe.findFirst({
      where: { id: groupeId, agenceId },
      select: GROUP_PLANNING_SELECT,
    }),
    'Groupe',
  )
}

// Loads one planning day owned by the current agence, with its group and events.
async function getOwnedPlanning(agenceId: string, planningId: string) {
  return findOrThrow(
    prisma.planningQuotidien.findFirst({
      where: {
        id: planningId,
        groupe: { agenceId },
      },
      include: {
        groupe: {
          select: GROUP_PLANNING_SELECT,
        },
        evenements: {
          orderBy: planningEventOrderBy(),
        },
      },
    }),
    'Planning',
  )
}

// Loads one planning event owned by the current agence, with its parent planning context.
async function getOwnedEvent(agenceId: string, eventId: string) {
  return findOrThrow(
    prisma.evenementPlanning.findFirst({
      where: {
        id: eventId,
        planningQuotidien: {
          groupe: { agenceId },
        },
      },
      include: {
        planningQuotidien: {
          include: {
            groupe: {
              select: GROUP_PLANNING_SELECT,
            },
          },
        },
      },
    }),
    'Evenement',
  )
}

// Ensures a planning day stays inside the configured travel window of its group.
function validatePlanningWindow(groupe: Awaited<ReturnType<typeof getOwnedGroupe>>, targetDate: Date) {
  if (!groupe.dateDepart || !groupe.dateRetour) {
    throw new Error("Definissez d'abord les dates de depart et de retour du groupe")
  }

  const start = addDays(startOfASTDay(groupe.dateDepart), -PLANNING_WINDOW_MARGIN_DAYS)
  const end = addDays(startOfASTDay(groupe.dateRetour), PLANNING_WINDOW_MARGIN_DAYS)

  if (!isWithinInterval(targetDate, { start, end })) {
    throw new Error('La date du planning doit etre comprise dans la duree du voyage')
  }
}

function buildTemplateDayCreateOperation(groupeId: string, templateDay: TemplateDay, currentDate: Date) {
  const resolvedEvents = templateDay.events.map((event) => buildTemplateEventData(event))

  return prisma.planningQuotidien.create({
    data: {
      groupeId,
      date: currentDate,
      titre: templateDay.title,
      evenements: resolvedEvents.length
        ? {
            create: resolvedEvents.map((event) => ({
              type: event.type,
              titre: event.titre,
              description: event.description,
              lieu: event.lieu,
              heureDebutPrevue: null,
              etape: event.etape ?? null,
            })),
          }
        : undefined,
    },
  })
}

function normalizeShiftOffset(value: number) {
  if (!Number.isInteger(value) || value === 0) {
    throw new Error('offsetDays doit etre un entier non nul')
  }

  if (Math.abs(value) > 14) {
    throw new Error('offsetDays est trop eleve')
  }

  return value
}

// Returns the selected group's planning days with their events for the planning workspace.
export async function getPlanningVoyage(agenceId: string, groupeId: string) {
  const groupe = await getOwnedGroupe(agenceId, groupeId)

  const plannings = await prisma.planningQuotidien.findMany({
    where: { groupeId },
    include: {
      evenements: {
        orderBy: planningEventOrderBy(),
      },
    },
    orderBy: { date: 'asc' },
  })

  return {
    groupe,
    plannings,
    tripDays: buildTripDays(groupe),
  }
}

// Creates one planning day manually for a group on a specific date.
export async function createPlanningDay(agenceId: string, groupeId: string, data: PlanningPayload) {
  const groupe = await getOwnedGroupe(agenceId, groupeId)
  const planningDate = normalizeDateOnly(data.date)

  validatePlanningWindow(groupe, planningDate)

  const existing = await prisma.planningQuotidien.findFirst({
    where: {
      groupeId,
      date: planningDate,
    },
    include: {
      evenements: {
        orderBy: planningEventOrderBy(),
      },
    },
  })

  if (existing) {
    throw new Error('Un planning existe deja pour cette date')
  }

  return prisma.planningQuotidien.create({
    data: {
      groupeId,
      date: planningDate,
      titre: data.titre?.trim() || null,
    },
    include: {
      evenements: {
        orderBy: planningEventOrderBy(),
      },
    },
  })
}

// Updates the date or title of an existing planning day.
export async function updatePlanningDay(
  agenceId: string,
  planningId: string,
  data: Partial<PlanningPayload>,
) {
  const planning = await getOwnedPlanning(agenceId, planningId)

  let nextDate: Date | undefined
  if (data.date !== undefined) {
    nextDate = normalizeDateOnly(data.date)
    validatePlanningWindow(planning.groupe, nextDate)

    const conflict = await prisma.planningQuotidien.findFirst({
      where: {
        id: { not: planningId },
        groupeId: planning.groupeId,
        date: nextDate,
      },
      select: { id: true },
    })

    if (conflict) {
      throw new Error('Un autre planning existe deja pour cette date')
    }
  }

  return prisma.planningQuotidien.update({
    where: { id: planningId },
    data: {
      ...(nextDate && { date: nextDate }),
      ...(data.titre !== undefined && { titre: data.titre?.trim() || null }),
    },
    include: {
      evenements: {
        orderBy: planningEventOrderBy(),
      },
    },
  })
}

// Deletes a planning day and all its related events through cascade rules.
export async function deletePlanningDay(agenceId: string, planningId: string) {
  await getOwnedPlanning(agenceId, planningId)
  await prisma.planningQuotidien.delete({ where: { id: planningId } })
  return { message: 'Planning supprime avec succes', planningId }
}

// Deletes the entire planning of one group by removing all of its planning days.
export async function deletePlanningVoyage(agenceId: string, groupeId: string) {
  await getOwnedGroupe(agenceId, groupeId)

  const result = await prisma.planningQuotidien.deleteMany({
    where: { groupeId },
  })

  return {
    message: 'Planning du groupe supprime avec succes',
    groupeId,
    deletedDays: result.count,
  }
}

export async function shiftPlanningVoyage(agenceId: string, groupeId: string, data: ShiftPlanningPayload) {
  const groupe = await getOwnedGroupe(agenceId, groupeId)
  const offsetDays = normalizeShiftOffset(data.offsetDays)

  const plannings = await prisma.planningQuotidien.findMany({
    where: { groupeId },
    orderBy: { date: 'asc' },
    select: {
      id: true,
      date: true,
    },
  })

  if (!plannings.length) {
    return {
      message: 'Aucune journee a deplacer',
      groupeId,
      offsetDays,
      shiftedDays: 0,
    }
  }

  const shiftedDates = plannings.map((planning) => ({
    id: planning.id,
    nextDate: addDays(startOfASTDay(planning.date), offsetDays),
  }))

  shiftedDates.forEach((planning) => validatePlanningWindow(groupe, planning.nextDate))

  const shiftedDateDepart = groupe.dateDepart
    ? addDays(startOfASTDay(groupe.dateDepart), offsetDays)
    : null
  const shiftedDateRetour = groupe.dateRetour
    ? addDays(startOfASTDay(groupe.dateRetour), offsetDays)
    : null
  const shiftedHajjStartDate = groupe.hajjStartDate
    ? addDays(startOfASTDay(groupe.hajjStartDate), offsetDays)
    : null

  await prisma.$transaction(
    [
      ...shiftedDates.map((planning) =>
        prisma.planningQuotidien.update({
          where: { id: planning.id },
          data: { date: planning.nextDate },
        }),
      ),
      prisma.groupe.update({
        where: { id: groupeId },
        data: {
          ...(shiftedDateDepart && { dateDepart: shiftedDateDepart }),
          ...(shiftedDateRetour && { dateRetour: shiftedDateRetour }),
          ...(groupe.typeVoyage === 'HAJJ' && { hajjStartDate: shiftedHajjStartDate }),
        },
      }),
    ],
  )

  return {
    message: 'Planning deplace avec succes',
    groupeId,
    offsetDays,
    shiftedDays: shiftedDates.length,
  }
}

// Creates one event inside a planning day using only the rendez-vous time.
export async function createPlanningEvent(agenceId: string, planningId: string, data: EventPayload) {
  const planning = await getOwnedPlanning(agenceId, planningId)

  if (!data.type || !data.titre || !data.heureDebutPrevue) {
    throw new Error('Type, titre et heureDebutPrevue sont requis')
  }

  const heureDebutPrevue = normalizeDateTime(data.heureDebutPrevue, 'heureDebutPrevue')
  validatePlanningWindow(planning.groupe, normalizeDateOnly(planning.date))

  if (!isSameASTDay(heureDebutPrevue, planning.date)) {
    throw new Error("heureDebutPrevue doit correspondre a la date de la journee")
  }

  return prisma.evenementPlanning.create({
    data: {
      planningQuotidienId: planningId,
      type: data.type,
      titre: data.titre.trim(),
      description: data.description?.trim() || null,
      lieu: normalizeLieu(data.lieu),
      heureDebutPrevue,
    },
  })
}

// Updates one planning event while preserving date-window and overlap rules.
export async function updatePlanningEvent(
  agenceId: string,
  eventId: string,
  data: Partial<EventPayload>,
) {
  const evenement = await getOwnedEvent(agenceId, eventId)

  const heureDebutPrevue = data.heureDebutPrevue
    ? normalizeDateTime(data.heureDebutPrevue, 'heureDebutPrevue')
    : undefined
  const nextStart = heureDebutPrevue ?? evenement.heureDebutPrevue

  if (!nextStart) {
    throw new Error("heureDebutPrevue doit etre definie pour cet evenement")
  }

  if (!isSameASTDay(nextStart, evenement.planningQuotidien.date)) {
    throw new Error("heureDebutPrevue doit correspondre a la date de la journee")
  }

  return prisma.evenementPlanning.update({
    where: { id: eventId },
    data: {
      ...(data.type !== undefined && { type: data.type }),
      ...(data.titre !== undefined && { titre: data.titre.trim() }),
      ...(data.description !== undefined && { description: data.description?.trim() || null }),
      ...(data.lieu !== undefined && { lieu: normalizeLieu(data.lieu) }),
      ...(heureDebutPrevue !== undefined && { heureDebutPrevue }),
    },
  })
}

// Deletes one event from a planning day.
export async function deletePlanningEvent(agenceId: string, eventId: string) {
  await getOwnedEvent(agenceId, eventId)
  await prisma.evenementPlanning.delete({ where: { id: eventId } })
  return { message: 'Evenement supprime avec succes', eventId }
}

// Generates the default planning model for a group based on its type of voyage.
export async function generatePlanningTemplate(agenceId: string, groupeId: string) {
  const groupe = await getOwnedGroupe(agenceId, groupeId)

  if (!groupe.dateDepart || !groupe.dateRetour) {
    throw new Error("Definissez d'abord les dates de depart et de retour du groupe")
  }

  const startDate = startOfASTDay(groupe.dateDepart)
  const endDate = startOfASTDay(groupe.dateRetour)
  const totalDays = diffInASTDays(startDate, endDate) + 1

  let templateDays: TemplateDay[] = []
  let resolveTemplateDate: (templateDay: TemplateDay, index: number) => Date

  if (groupe.typeVoyage === 'UMRAH') {
    templateDays = buildUmrahPlan(totalDays)
    resolveTemplateDate = (_templateDay, index) => {
      if (templateDays.length === 1) {
        return startDate
      }

      if (templateDays.length === 2) {
        return index === 0 ? startDate : endDate
      }

      if (index === 0) return startDate
      if (index === templateDays.length - 1) return endDate

      return addDays(startDate, index)
    }
  } else {
    if (!groupe.hajjStartDate) {
      throw new Error('Renseignez la date du 8 Dhul Hijja pour generer le planning Hajj')
    }

    const hajjStartDate = startOfASTDay(groupe.hajjStartDate)
    const fixedEndDate = addDays(hajjStartDate, 5)

    if (startDate > hajjStartDate) {
      throw new Error('La date de depart du groupe doit etre avant ou au 8 Dhul Hijja')
    }

    if (endDate < fixedEndDate) {
      throw new Error('Le voyage Hajj doit couvrir du 8 au 13 Dhul Hijja')
    }

    templateDays = buildHajjPlan()
    resolveTemplateDate = (templateDay) => addDays(hajjStartDate, (templateDay.hijriDay ?? 8) - 8)
  }

  const existingPlannings = await prisma.planningQuotidien.findMany({
    where: { groupeId },
    include: {
      evenements: true,
    },
  })

  const existingByDate = new Map(existingPlannings.map((planning) => [startOfASTDay(planning.date).getTime(), planning]))

  const operations = []
  let createdDays = 0
  let skippedDays = 0
  let createdEvents = 0

  for (let index = 0; index < templateDays.length; index += 1) {
    const templateDay = templateDays[index]
    const currentDate = resolveTemplateDate(templateDay, index)
    const dateKey = currentDate.getTime()

    const existing = existingByDate.get(dateKey)
    if (existing) {
      skippedDays += 1
      continue
    }

    operations.push(buildTemplateDayCreateOperation(groupeId, templateDay, currentDate))
    createdDays += 1
    createdEvents += templateDay.events.length
  }

  const shouldMarkInProgress = groupe.status === 'PLANIFIE'

  if (operations.length || shouldMarkInProgress) {
    await prisma.$transaction([
      ...operations,
      ...(shouldMarkInProgress
          ? [
              prisma.groupe.update({
                where: { id: groupeId },
                data: { status: 'EN_COURS' },
              }),
            ]
          : []),
    ])
  }

  return {
    message: 'Modele de planning genere',
    templateType: groupe.typeVoyage,
    createdDays,
    skippedDays,
    createdEvents,
  }
}
// Validates one event as a guide. Only assigned active guides can validate.
// Prayers are never validated.
export async function validerEvenement(utilisateurId: string, eventId: string) {
  const guide = await prisma.guide.findUnique({
    where: { utilisateurId },
    select: { id: true },
  })

  if (!guide) throw new Error('Guide introuvable')

  const evenement = await prisma.evenementPlanning.findFirst({
    where: {
      id: eventId,
      planningQuotidien: {
        groupe: {
          guides: { some: { guideId: guide.id, actif: true } },
        },
      },
    },
    select: {
      id: true,
      type: true,
      titre: true,
      etape: true,
      estValide: true,
      planningQuotidien: {
        select: {
          groupeId: true,
          groupe: {
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
          },
        },
      },
    },
  })

  if (!evenement) throw new Error('Evenement introuvable ou acces non autorise')
  if (evenement.type === 'PRIERE') throw new Error('Les prieres ne sont pas soumises a validation')
  if (evenement.estValide) return evenement

  const updatedEvent = await prisma.evenementPlanning.update({
    where: { id: eventId },
    data: {
      estValide: true,
      valideeAt: new Date(),
      valideParGuideId: guide.id,
    },
  })

  const familleUserIds = Array.from(
    new Set(
      evenement.planningQuotidien.groupe.membres
        .flatMap((membership) => membership.pelerin.familles)
        .map((association) => association.famille.utilisateurId)
        .filter(Boolean),
    ),
  )

  if (familleUserIds.length) {
    const etapeLabel = evenement.etape ?? evenement.titre
    await sendPushToUsers({
      userIds: familleUserIds,
      role: 'FAMILLE',
      title: 'Nouvelle étape validée',
      body: `${evenement.planningQuotidien.groupe.nom} est passé à ${etapeLabel}.`,
      data: {
        type: 'alert',
        tab: 'alerts',
        groupeId: evenement.planningQuotidien.groupeId,
        eventId: evenement.id,
        etape: String(etapeLabel),
      },
    })
  }

  return updatedEvent
}
// ======================================================
// PROGRESSION RITUELS
// ======================================================

// Returns ritual milestone progress for a group based on etape-tagged events.
export async function getProgressionRituels(agenceId: string, groupeId: string) {
  await getOwnedGroupe(agenceId, groupeId)

  const evenements = await prisma.evenementPlanning.findMany({
    where: {
      planningQuotidien: { groupeId },
      etape: { not: null },
    },
    select: {
      etape: true,
      estValide: true,
      valideeAt: true,
    },
    orderBy: [
      { planningQuotidien: { date: 'asc' } },
      { heureDebutPrevue: 'asc' },
    ],
  })

  const total = evenements.length
  const valides = evenements.filter((e) => e.estValide).length

  return {
    total,
    valides,
    pourcentage: total === 0 ? 0 : Math.round((valides / total) * 100),
    etapes: evenements.map((e) => ({
      etape: e.etape,
      estValide: e.estValide,
      valideeAt: e.valideeAt,
    })),
  }
}
