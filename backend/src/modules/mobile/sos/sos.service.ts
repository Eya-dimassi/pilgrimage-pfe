import prisma from '../../../config/prisma'
import { sendPushToUsers } from '../../../utils/push-notifications.utils'

type CreateSosPayload = {
  latitude: number
  longitude: number
  message?: string
}

function normalizeCoordinate(value: unknown, label: string) {
  const numericValue = Number(value)

  if (!Number.isFinite(numericValue)) {
    throw new Error(`${label} invalide`)
  }

  return numericValue
}

export async function getMyActiveSos(utilisateurId: string) {
  const pelerin = await prisma.pelerin.findUnique({
    where: { utilisateurId },
    select: { id: true },
  })

  if (!pelerin) {
    throw new Error('Pelerin introuvable')
  }

  const activeAlert = await prisma.alerteSOS.findFirst({
    where: {
      pelerinId: pelerin.id,
      statut: 'EN_COURS',
    },
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      latitude: true,
      longitude: true,
      statut: true,
      message: true,
      createdAt: true,
      resolueAt: true,
    },
  })

  return {
    activeAlert,
  }
}

export async function createSosAlert(utilisateurId: string, payload: CreateSosPayload) {
  const latitude = normalizeCoordinate(payload.latitude, 'Latitude')
  const longitude = normalizeCoordinate(payload.longitude, 'Longitude')
  const message = String(payload.message ?? '').trim() || null

  const pelerin = await prisma.pelerin.findUnique({
    where: { utilisateurId },
    select: {
      id: true,
      utilisateurId: true,
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
          },
        },
        orderBy: { dateDebut: 'desc' },
        take: 1,
        select: {
          groupeId: true,
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

  if (!pelerin) {
    throw new Error('Pelerin introuvable')
  }

  const activeGroupRelation = pelerin.groupes[0]
  if (!activeGroupRelation?.groupe) {
    throw new Error('Aucun groupe actif introuvable pour ce pelerin')
  }

  const existingActiveAlert = await prisma.alerteSOS.findFirst({
    where: {
      pelerinId: pelerin.id,
      statut: 'EN_COURS',
    },
    select: {
      id: true,
      latitude: true,
      longitude: true,
      statut: true,
      message: true,
      createdAt: true,
      resolueAt: true,
    },
  })

  if (existingActiveAlert) {
    return {
      created: false,
      alert: existingActiveAlert,
    }
  }

  const alert = await prisma.$transaction(async (tx) => {
    await tx.position.create({
      data: {
        pelerinId: pelerin.id,
        latitude,
        longitude,
      },
    })

    await tx.pelerin.update({
      where: { id: pelerin.id },
      data: {
        statut: 'SOS',
      },
    })

    return tx.alerteSOS.create({
      data: {
        pelerinId: pelerin.id,
        latitude,
        longitude,
        message,
        statut: 'EN_COURS',
      },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        statut: true,
        message: true,
        createdAt: true,
        resolueAt: true,
      },
    })
  })

  const fullName = [pelerin.utilisateur?.prenom, pelerin.utilisateur?.nom]
    .filter(Boolean)
    .join(' ')
    .trim() || 'Votre proche'

  const familleUserIds = Array.from(new Set(
    pelerin.familles
      .map((relation) => relation.famille?.utilisateurId)
      .filter((value): value is string => Boolean(value)),
  ))

  const guideUserIds = Array.from(new Set(
    activeGroupRelation.groupe.guides
      .map((relation) => relation.guide?.utilisateurId)
      .filter((value): value is string => Boolean(value)),
  ))

  if (familleUserIds.length) {
    await sendPushToUsers({
      userIds: familleUserIds,
      role: 'FAMILLE',
      title: 'Alerte SOS',
      body: `${fullName} a declenche une alerte SOS.`,
      data: {
        type: 'sos',
        tab: 'alerts',
        groupeId: activeGroupRelation.groupe.id,
        sosId: alert.id,
      },
    })
  }

  if (guideUserIds.length) {
    await sendPushToUsers({
      userIds: guideUserIds,
      role: 'GUIDE',
      title: 'SOS urgent',
      body: `${fullName} a besoin d aide dans le groupe ${activeGroupRelation.groupe.nom}.`,
      data: {
        type: 'sos',
        tab: 'alerts',
        groupeId: activeGroupRelation.groupe.id,
        sosId: alert.id,
      },
    })
  }

  return {
    created: true,
    alert,
  }
}
