import prisma from '../../../config/prisma'
import { sendPushToUsers } from '../../../utils/push-notifications.utils'

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
  const confirmation = await prisma.confirmationPresence.findFirst({
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

  return mapPresencePayload(confirmation)
}

export async function getPresenceCallForPelerin(userId: string, appelId: string) {
  const confirmation = await prisma.confirmationPresence.findFirst({
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

  return mapPresencePayload(confirmation)
}

export async function confirmPresenceAsPelerin(
  userId: string,
  confirmationId: string,
  note?: string,
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
      note: note?.trim() || null,
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
