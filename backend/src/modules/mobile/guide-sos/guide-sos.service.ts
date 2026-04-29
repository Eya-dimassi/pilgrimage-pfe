import prisma from '../../../config/prisma'
import { sendPushToUsers } from '../../../utils/push-notifications.utils'

async function getGuideByUser(utilisateurId: string) {
  const guide = await prisma.guide.findUnique({
    where: { utilisateurId },
    select: { id: true },
  })

  if (!guide) {
    throw new Error('Guide introuvable')
  }

  return guide
}

export async function getActiveGuideSosAlerts(utilisateurId: string) {
  const guide = await getGuideByUser(utilisateurId)

  const alerts = await prisma.alerteSOS.findMany({
    where: {
      statut: 'EN_COURS',
      pelerin: {
        groupes: {
          some: {
            actif: true,
            groupe: {
              status: {
                notIn: ['TERMINE', 'ANNULE'],
              },
              guides: {
                some: {
                  actif: true,
                  guideId: guide.id,
                },
              },
            },
          },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      latitude: true,
      longitude: true,
      message: true,
      createdAt: true,
      pelerin: {
        select: {
          id: true,
          utilisateur: {
            select: {
              prenom: true,
              nom: true,
            },
          },
          groupes: {
            where: {
              actif: true,
              groupe: {
                status: {
                  notIn: ['TERMINE', 'ANNULE'],
                },
                guides: {
                  some: {
                    actif: true,
                    guideId: guide.id,
                  },
                },
              },
            },
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
  })

  return alerts.map((alert) => ({
    id: alert.id,
    latitude: alert.latitude,
    longitude: alert.longitude,
    message: alert.message,
    createdAt: alert.createdAt,
    pelerinName: [alert.pelerin.utilisateur?.prenom, alert.pelerin.utilisateur?.nom]
      .filter(Boolean)
      .join(' ')
      .trim(),
    groupe: alert.pelerin.groupes[0]?.groupe
      ? {
          id: alert.pelerin.groupes[0].groupe.id,
          nom: alert.pelerin.groupes[0].groupe.nom,
        }
      : null,
  }))
}

export async function resolveGuideSosAlert(utilisateurId: string, sosId: string) {
  const guide = await getGuideByUser(utilisateurId)

  const alert = await prisma.alerteSOS.findFirst({
    where: {
      id: sosId,
      statut: 'EN_COURS',
      pelerin: {
        groupes: {
          some: {
            actif: true,
            groupe: {
              status: {
                notIn: ['TERMINE', 'ANNULE'],
              },
              guides: {
                some: {
                  actif: true,
                  guideId: guide.id,
                },
              },
            },
          },
        },
      },
    },
    select: {
      id: true,
      pelerinId: true,
      pelerin: {
        select: {
          utilisateur: {
            select: {
              prenom: true,
              nom: true,
            },
          },
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
          groupes: {
            where: {
              actif: true,
              groupe: {
                status: {
                  notIn: ['TERMINE', 'ANNULE'],
                },
                guides: {
                  some: {
                    actif: true,
                    guideId: guide.id,
                  },
                },
              },
            },
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
  })

  if (!alert) {
    throw new Error('Alerte SOS introuvable')
  }

  const resolvedAlert = await prisma.$transaction(async (tx) => {
    await tx.pelerin.update({
      where: { id: alert.pelerinId },
      data: {
        statut: 'PRESENT',
      },
    })

    return tx.alerteSOS.update({
      where: { id: alert.id },
      data: {
        statut: 'RESOLUE',
        resolueAt: new Date(),
        resolueParGuideId: guide.id,
      },
      select: {
        id: true,
        statut: true,
        resolueAt: true,
      },
    })
  })

  const familleUserIds = Array.from(
    new Set(
      alert.pelerin.familles
        .map((relation) => relation.famille?.utilisateurId)
        .filter((value): value is string => Boolean(value)),
    ),
  )

  if (familleUserIds.length) {
    const fullName = [alert.pelerin.utilisateur?.prenom, alert.pelerin.utilisateur?.nom]
      .filter(Boolean)
      .join(' ')
      .trim() || 'Votre proche'

    await sendPushToUsers({
      userIds: familleUserIds,
      role: 'FAMILLE',
      title: 'Alerte resolue',
      body: `${fullName} va bien. Le guide a pris en charge la situation.`,
      data: {
        type: 'sos_resolved',
        tab: 'alerts',
        groupeId: alert.pelerin.groupes[0]?.groupe?.id ?? '',
        sosId: alert.id,
      },
    })
  }

  const pelerinUserId = await prisma.pelerin.findUnique({
    where: { id: alert.pelerinId },
    select: { utilisateurId: true },
  })

  if (pelerinUserId?.utilisateurId) {
    await sendPushToUsers({
      userIds: [pelerinUserId.utilisateurId],
      role: 'PELERIN',
      title: 'Alerte prise en charge',
      body: 'Votre guide a pris en charge la situation. Vous pouvez reprendre le suivi normal.',
      data: {
        type: 'sos_resolved',
        tab: 'alerts',
        groupeId: alert.pelerin.groupes[0]?.groupe?.id ?? '',
        sosId: alert.id,
      },
    })
  }

  return resolvedAlert
}
