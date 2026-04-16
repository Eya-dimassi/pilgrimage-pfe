import prisma from '../../../config/prisma'
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
          select: MOBILE_GROUP_SELECT,
        },
      },
    })

    return relations
      .map((relation) => relation.groupe)
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

// Picks today's planning day for day-only mobile views.
function pickVisiblePlanningDay(plannings: Array<{ date: Date }>) {
  const today = startOfASTDay(new Date())
  return plannings.find((planning) => isSameASTDay(planning.date, today)) ?? null
}

// Returns only the planning day relevant to a mobile day-only role.
async function getDayOnlyPlanningForGroup(userId: string, role: 'FAMILLE' | 'PELERIN', groupeId: string) {
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

  const selectedPlanning = pickVisiblePlanningDay(plannings)

  return {
    groupe,
    plannings: selectedPlanning ? [selectedPlanning] : [],
  }
}

// Returns the full read-only planning for one accessible group.
export async function getMobilePlanningForGroup(userId: string, role: string, groupeId: string) {
  if (role === 'FAMILLE' || role === 'PELERIN') {
    return getDayOnlyPlanningForGroup(userId, role, groupeId)
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

  return {
    groupe,
    plannings,
  }
}
