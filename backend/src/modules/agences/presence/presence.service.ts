import prisma from '../../../config/prisma'

type PresenceHistoryFilters = {
  groupeId?: string
  guideId?: string
  statut?: 'EN_COURS' | 'CLOTURE'
  dateFrom?: string
  dateTo?: string
}

function buildDateFilters(dateFrom?: string, dateTo?: string) {
  const dateFilter: { gte?: Date; lte?: Date } = {}

  if (dateFrom) {
    const parsed = new Date(dateFrom)
    if (!Number.isNaN(parsed.getTime())) {
      parsed.setHours(0, 0, 0, 0)
      dateFilter.gte = parsed
    }
  }

  if (dateTo) {
    const parsed = new Date(dateTo)
    if (!Number.isNaN(parsed.getTime())) {
      parsed.setHours(23, 59, 59, 999)
      dateFilter.lte = parsed
    }
  }

  return dateFilter
}

export async function getAgencePresenceHistory(
  agenceId: string,
  filters: PresenceHistoryFilters,
) {
  const dateFilter = buildDateFilters(filters.dateFrom, filters.dateTo)

  const where = {
    groupe: { agenceId },
    ...(filters.groupeId ? { groupeId: filters.groupeId } : {}),
    ...(filters.guideId ? { guideId: filters.guideId } : {}),
    ...(filters.statut ? { statut: filters.statut } : {}),
    ...(Object.keys(dateFilter).length > 0 ? { date: dateFilter } : {}),
  }

  const [appels, groupes, guides] = await Promise.all([
    prisma.appelPresence.findMany({
      where,
      include: {
        groupe: {
          select: {
            id: true,
            nom: true,
          },
        },
        guide: {
          select: {
            id: true,
            utilisateur: {
              select: {
                prenom: true,
                nom: true,
              },
            },
          },
        },
        confirmations: {
          select: {
            id: true,
            statut: true,
            pelerin: {
              select: {
                id: true,
                utilisateur: {
                  select: {
                    prenom: true,
                    nom: true,
                  },
                },
              },
            },
          },
          orderBy: {
            pelerin: {
              utilisateur: {
                nom: 'asc',
              },
            },
          },
        },
      },
      orderBy: {
        date: 'desc',
      },
    }),
    prisma.groupe.findMany({
      where: { agenceId },
      select: {
        id: true,
        nom: true,
      },
      orderBy: {
        nom: 'asc',
      },
    }),
    prisma.guide.findMany({
      where: { agenceId },
      select: {
        id: true,
        utilisateur: {
          select: {
            prenom: true,
            nom: true,
          },
        },
      },
      orderBy: {
        utilisateur: {
          nom: 'asc',
        },
      },
    }),
  ])

  const rows = appels.map((appel) => {
    const total = appel.confirmations.length
    const presents = appel.confirmations.filter((entry) => entry.statut === 'PRESENT').length
    const absents = appel.confirmations.filter((entry) => entry.statut === 'ABSENT').length
    const excuses = appel.confirmations.filter((entry) => entry.statut === 'EXCUSE').length
    const enAttente = appel.confirmations.filter((entry) => entry.statut === 'EN_ATTENTE').length

    return {
      id: appel.id,
      date: appel.date,
      statut: appel.statut,
      groupe: {
        id: appel.groupe.id,
        nom: appel.groupe.nom,
      },
      guide: {
        id: appel.guide.id,
        fullName: `${appel.guide.utilisateur.prenom} ${appel.guide.utilisateur.nom}`.trim(),
      },
      stats: {
        total,
        presents,
        absents,
        excuses,
        enAttente,
      },
      pelerins: appel.confirmations.map((entry) => ({
        id: entry.pelerin.id,
        fullName: `${entry.pelerin.utilisateur.prenom} ${entry.pelerin.utilisateur.nom}`.trim(),
        statut: entry.statut,
      })),
    }
  })

  const totalAppels = rows.length
  const appelsEnCours = rows.filter((row) => row.statut === 'EN_COURS').length
  const appelsClotures = rows.filter((row) => row.statut === 'CLOTURE').length
  const totalConfirmations = rows.reduce((sum, row) => sum + row.stats.total, 0)
  const totalPresents = rows.reduce((sum, row) => sum + row.stats.presents, 0)
  const tauxPresenceGlobal =
    totalConfirmations > 0 ? Math.round((totalPresents / totalConfirmations) * 100) : 0

  return {
    stats: {
      totalAppels,
      appelsEnCours,
      appelsClotures,
      tauxPresenceGlobal,
    },
    rows,
    filters: {
      groupes,
      guides: guides.map((guide) => ({
        id: guide.id,
        fullName: `${guide.utilisateur.prenom} ${guide.utilisateur.nom}`.trim(),
      })),
    },
  }
}
