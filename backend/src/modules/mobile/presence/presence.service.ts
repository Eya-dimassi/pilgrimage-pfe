import prisma from '../../../config/prisma'
import { sendPushToUsers } from '../../../utils/push-notifications.utils'

const AUTO_CLOSE_DELAY_MS = 60 * 60 * 1000

function isAutoCloseDue(appelDate: Date) {
  return Date.now() - appelDate.getTime() >= AUTO_CLOSE_DELAY_MS
}

async function closeAppelById(appelId: string) {
  const closedAt = new Date()

  await prisma.$transaction(async (tx) => {
    await tx.confirmationPresence.updateMany({
      where: {
        appelPresenceId: appelId,
        statut: 'EN_ATTENTE',
      },
      data: {
        statut: 'ABSENT',
        confirmeMode: 'AUTOMATIQUE',
        confirmeAt: closedAt,
      },
    })

    await tx.appelPresence.update({
      where: { id: appelId },
      data: {
        statut: 'CLOTURE',
        clotureAt: closedAt,
      },
    })
  })
}

type PresenceCallPayload = {
  appel: {
    id: string
    date: Date
    statut: string
    clotureAt: Date | null
    groupe: {
      id: string
      nom: string
    }
    guide: {
      id: string
      nom: string
      prenom: string
    }
  }
  confirmation: {
    id: string
    statut: string
    confirmeAt: Date | null
    confirmeMode: string | null
    note: string | null
  }
  canConfirm: boolean
}

function mapPresencePayload(confirmation: {
  id: string
  statut: string
  confirmeAt: Date | null
  confirmeMode: string | null
  note: string | null
  appelPresence: {
    id: string
    date: Date
    statut: string
    clotureAt: Date | null
    groupe: {
      id: string
      nom: string
    }
    guide: {
      id: string
      utilisateur: {
        nom: string
        prenom: string
      }
    }
  }
}): PresenceCallPayload {
  const appel = confirmation.appelPresence
  const canConfirm = appel.statut === 'EN_COURS' && confirmation.statut === 'EN_ATTENTE'

  return {
    appel: {
      id: appel.id,
      date: appel.date,
      statut: appel.statut,
      clotureAt: appel.clotureAt,
      groupe: {
        id: appel.groupe.id,
        nom: appel.groupe.nom,
      },
      guide: {
        id: appel.guide.id,
        nom: appel.guide.utilisateur.nom,
        prenom: appel.guide.utilisateur.prenom,
      },
    },
    confirmation: {
      id: confirmation.id,
      statut: confirmation.statut,
      confirmeAt: confirmation.confirmeAt,
      confirmeMode: confirmation.confirmeMode,
      note: confirmation.note,
    },
    canConfirm,
  }
}

export async function getActivePresenceCallForPelerin(userId: string) {
  let confirmation = await prisma.confirmationPresence.findFirst({
    where: {
      pelerin: {
        utilisateurId: userId,
      },
      appelPresence: {
        statut: 'EN_COURS',
      },
    },
    include: {
      appelPresence: {
        include: {
          groupe: {
            select: {
              id: true,
              nom: true,
            },
          },
          guide: {
            include: {
              utilisateur: {
                select: {
                  nom: true,
                  prenom: true,
                },
              },
            },
          },
        },
      },
    },
    orderBy: {
      appelPresence: {
        date: 'desc',
      },
    },
  })

  if (!confirmation) {
    return null
  }

  if (confirmation.appelPresence.statut === 'EN_COURS' && isAutoCloseDue(confirmation.appelPresence.date)) {
    await closeAppelById(confirmation.appelPresence.id)
    confirmation = await prisma.confirmationPresence.findFirst({
      where: {
        pelerin: {
          utilisateurId: userId,
        },
        appelPresence: {
          statut: 'EN_COURS',
        },
      },
      include: {
        appelPresence: {
          include: {
            groupe: {
              select: {
                id: true,
                nom: true,
              },
            },
            guide: {
              include: {
                utilisateur: {
                  select: {
                    nom: true,
                    prenom: true,
                  },
                },
              },
            },
          },
        },
      },
      orderBy: {
        appelPresence: {
          date: 'desc',
        },
      },
    })
    if (!confirmation) {
      return null
    }
  }

  return mapPresencePayload(confirmation)
}

export async function getPresenceCallForPelerin(userId: string, appelId: string) {
  let confirmation = await prisma.confirmationPresence.findFirst({
    where: {
      pelerin: {
        utilisateurId: userId,
      },
      appelPresenceId: appelId,
    },
    include: {
      appelPresence: {
        include: {
          groupe: {
            select: {
              id: true,
              nom: true,
            },
          },
          guide: {
            include: {
              utilisateur: {
                select: {
                  nom: true,
                  prenom: true,
                },
              },
            },
          },
        },
      },
    },
  })

  if (!confirmation) {
    throw new Error('Appel de presence introuvable')
  }

  if (confirmation.appelPresence.statut === 'EN_COURS' && isAutoCloseDue(confirmation.appelPresence.date)) {
    await closeAppelById(confirmation.appelPresence.id)
    confirmation = await prisma.confirmationPresence.findFirst({
      where: {
        pelerin: {
          utilisateurId: userId,
        },
        appelPresenceId: appelId,
      },
      include: {
        appelPresence: {
          include: {
            groupe: {
              select: {
                id: true,
                nom: true,
              },
            },
            guide: {
              include: {
                utilisateur: {
                  select: {
                    nom: true,
                    prenom: true,
                  },
                },
              },
            },
          },
        },
      },
    })
    if (!confirmation) {
      throw new Error('Appel de presence introuvable')
    }
  }

  return mapPresencePayload(confirmation)
}

export async function confirmPresenceAsPelerin(
  userId: string,
  confirmationId: string,
) {
  const confirmation = await prisma.confirmationPresence.findFirst({
    where: {
      id: confirmationId,
      pelerin: {
        utilisateurId: userId,
      },
      appelPresence: {
        statut: 'EN_COURS',
      },
    },
    include: {
      pelerin: {
        include: {
          utilisateur: {
            select: {
              id: true,
              nom: true,
              prenom: true,
            },
          },
        },
      },
      appelPresence: {
        include: {
          groupe: {
            select: {
              id: true,
              nom: true,
              guides: {
                where: { actif: true },
                select: {
                  guide: {
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

  if (!confirmation) {
    throw new Error('Confirmation introuvable ou appel cloture')
  }

  if (isAutoCloseDue(confirmation.appelPresence.date)) {
    await closeAppelById(confirmation.appelPresence.id)
    throw new Error('Appel cloture automatiquement apres 1 heure')
  }

  if (confirmation.statut === 'PRESENT') {
    return {
      message: 'Presence deja confirmee',
      confirmation: {
        id: confirmation.id,
        statut: confirmation.statut,
        confirmeAt: confirmation.confirmeAt,
        confirmeMode: confirmation.confirmeMode,
        note: confirmation.note,
      },
    }
  }

  const updated = await prisma.confirmationPresence.update({
    where: { id: confirmationId },
    data: {
      statut: 'PRESENT',
      confirmeMode: 'MANUEL',
      confirmeAt: new Date(),
    },
  })

  const guideUserIds = Array.from(
    new Set(
      confirmation.appelPresence.groupe.guides
        .map((entry) => entry.guide.utilisateurId)
        .filter(Boolean),
    ),
  )

  if (guideUserIds.length > 0) {
    const fullName =
      `${confirmation.pelerin.utilisateur.prenom} ${confirmation.pelerin.utilisateur.nom}`.trim()

    await sendPushToUsers({
      userIds: guideUserIds,
      role: 'GUIDE',
      title: 'Presence confirmee',
      body: `${fullName} a confirme sa presence.`,
      data: {
        type: 'presence_update',
        tab: 'alerts',
        groupeId: confirmation.appelPresence.groupe.id,
        eventId: confirmation.appelPresence.id,
        etape: 'CONFIRMATION',
      },
    })
  }

  return {
    message: 'Presence confirmee',
    confirmation: updated,
  }
}

type FamilyPresenceStatusPayload = {
  pelerinId: string
  codeUnique: string
  fullName: string
  groupeId: string | null
  groupeNom: string | null
   statusForFamily: 'PRESENT' | 'ABSENT' | 'EXCUSE'
  source: 'default' | 'latest_call'
  activeAppelId: string | null
  confirmationId: string | null
  note: string | null
  rawStatus: string | null
  confirmeAt: Date | null
}

export async function getFamilyPresenceStatuses(
  userId: string,
): Promise<FamilyPresenceStatusPayload[]> {
  const links = await prisma.famillePelerin.findMany({
    where: {
      actif: true,
      famille: {
        utilisateurId: userId,
      },
    },
    include: {
      pelerin: {
        select: {
          id: true,
          codeUnique: true,
          utilisateur: {
            select: {
              nom: true,
              prenom: true,
            },
          },
          groupes: {
            where: { actif: true },
            orderBy: { dateDebut: 'desc' },
            take: 1,
            select: {
              groupe: {
                select: {
                  id: true,
                  nom: true,
                },
              },
            },
          },
        },
      },
    },
    orderBy: {
      createdAt: 'asc',
    },
  })

  if (links.length === 0) {
    return []
  }

  const pelerinIds = links.map((link) => link.pelerinId)

  const activeAppels = await prisma.appelPresence.findMany({
    where: {
      statut: 'EN_COURS',
      confirmations: {
        some: {
          pelerinId: { in: pelerinIds },
        },
      },
    },
    select: {
      id: true,
      date: true,
    },
  })

  const staleAppelIds = Array.from(
    new Set(
      activeAppels
        .filter((appel) => isAutoCloseDue(appel.date))
        .map((appel) => appel.id),
    ),
  )

  if (staleAppelIds.length > 0) {
    await Promise.all(staleAppelIds.map((appelId) => closeAppelById(appelId)))
  }

  const latestConfirmations = await prisma.confirmationPresence.findMany({
    where: {
      pelerinId: { in: pelerinIds },
    },
    include: {
      appelPresence: {
        select: {
          id: true,
          date: true,
          statut: true,
          groupe: {
            select: {
              id: true,
              nom: true,
            },
          },
        },
      },
    },
    orderBy: [
      {
        appelPresence: {
          date: 'desc',
        },
      },
      {
        createdAt: 'desc',
      },
    ],
  })

  const latestByPelerinId = new Map<string, (typeof latestConfirmations)[number]>()
  for (const confirmation of latestConfirmations) {
    if (!latestByPelerinId.has(confirmation.pelerinId)) {
      latestByPelerinId.set(confirmation.pelerinId, confirmation)
    }
  }

  return links.map((link) => {
    const confirmation = latestByPelerinId.get(link.pelerinId)
    const rawStatus = confirmation?.statut ?? null
    const statusForFamily =
      rawStatus === 'ABSENT' || rawStatus === 'EXCUSE' ? rawStatus : 'PRESENT'

    const fallbackGroup = link.pelerin.groupes[0]?.groupe
    const groupFromCall = confirmation?.appelPresence.groupe

    return {
      pelerinId: link.pelerinId,
      codeUnique: link.pelerin.codeUnique,
      fullName:
        `${link.pelerin.utilisateur.prenom} ${link.pelerin.utilisateur.nom}`.trim(),
      groupeId: groupFromCall?.id ?? fallbackGroup?.id ?? null,
      groupeNom: groupFromCall?.nom ?? fallbackGroup?.nom ?? null,
      statusForFamily,
      source:
        statusForFamily === 'ABSENT' || statusForFamily === 'EXCUSE'
          ? 'latest_call'
          : 'default',
      activeAppelId: confirmation?.appelPresenceId ?? null,
      confirmationId: confirmation?.id ?? null,
      note: statusForFamily === 'PRESENT' ? null : confirmation?.note ?? null,
      rawStatus,
      confirmeAt: confirmation?.confirmeAt ?? null,
    }
  })
}
