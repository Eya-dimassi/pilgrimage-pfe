import prisma from '../../../config/prisma'
import { sendPushToUsers } from '../../../utils/push-notifications.utils'

type CreateSosPayload = {
  latitude: number
  longitude: number
  type?: string
  message?: string
}

const SOS_INCIDENT_TYPES = ['MALADIE', 'PERTE', 'LOGISTIQUE', 'AUTRE'] as const

type SosIncidentType = (typeof SOS_INCIDENT_TYPES)[number]

function normalizeCoordinate(value: unknown, label: string) {
  const numericValue = Number(value)

  if (!Number.isFinite(numericValue)) {
    throw new Error(`${label} invalide`)
  }

  return numericValue
}

function normalizeIncidentType(value: unknown): SosIncidentType {
  const normalizedValue = String(value ?? '')
    .trim()
    .toUpperCase()

  if (SOS_INCIDENT_TYPES.includes(normalizedValue as SosIncidentType)) {
    return normalizedValue as SosIncidentType
  }

  throw new Error('Type de demande SOS invalide')
}

function defaultIncidentDescription(type: SosIncidentType) {
  switch (type) {
    case 'MALADIE':
      return 'Probleme de sante signale par le pelerin.'
    case 'PERTE':
      return 'Le pelerin signale qu il est perdu.'
    case 'LOGISTIQUE':
      return 'Le pelerin a besoin d aide logistique.'
    case 'AUTRE':
      return 'Demande d assistance generale.'
  }
}

function notificationCopyForType(type: SosIncidentType, fullName: string, groupeNom: string) {
  switch (type) {
    case 'MALADIE':
      return {
        familyTitle: 'Alerte sante',
        familyBody: `${fullName} a signale un probleme de sante.`,
        guideTitle: 'Alerte maladie',
        guideBody: `${fullName} a besoin d aide medicale dans le groupe ${groupeNom}.`,
      }
    case 'PERTE':
      return {
        familyTitle: 'Alerte localisation',
        familyBody: `${fullName} a signale qu il est perdu.`,
        guideTitle: 'Pelerin perdu',
        guideBody: `${fullName} signale qu il est perdu dans le groupe ${groupeNom}.`,
      }
    case 'LOGISTIQUE':
      return {
        familyTitle: 'Alerte logistique',
        familyBody: `${fullName} a demande une aide logistique.`,
        guideTitle: 'Aide logistique',
        guideBody: `${fullName} a besoin d aide logistique dans le groupe ${groupeNom}.`,
      }
    case 'AUTRE':
      return {
        familyTitle: 'Demande d assistance',
        familyBody: `${fullName} a envoye une demande d assistance generale.`,
        guideTitle: 'Assistance generale',
        guideBody: `${fullName} a besoin d assistance dans le groupe ${groupeNom}.`,
      }
  }
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
      type: true,
      description: true,
      statut: true,
      message: true,
      createdAt: true,
      resolueAt: true,
    },
  })

  return {
    activeAlert: activeAlert ?? null,
  }
}

export async function createSosAlert(utilisateurId: string, payload: CreateSosPayload) {
  const latitude = normalizeCoordinate(payload.latitude, 'Latitude')
  const longitude = normalizeCoordinate(payload.longitude, 'Longitude')
  const type = normalizeIncidentType(payload.type)
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
      type: true,
      description: true,
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

  const incidentDescription = message || defaultIncidentDescription(type)

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

    const createdAlert = await tx.alerteSOS.create({
      data: {
        pelerinId: pelerin.id,
        groupeId: activeGroupRelation.groupe.id,
        latitude,
        longitude,
        type,
        description: incidentDescription,
        message,
        statut: 'EN_COURS',
      },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        type: true,
        description: true,
        statut: true,
        message: true,
        createdAt: true,
        resolueAt: true,
      },
    })

    return tx.alerteSOS.findUniqueOrThrow({
      where: { id: createdAlert.id },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        type: true,
        description: true,
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

  const notificationCopy = notificationCopyForType(
    type,
    fullName,
    activeGroupRelation.groupe.nom,
  )

  if (familleUserIds.length) {
    await sendPushToUsers({
      userIds: familleUserIds,
      role: 'FAMILLE',
      title: notificationCopy.familyTitle,
      body: notificationCopy.familyBody,
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
      title: notificationCopy.guideTitle,
      body: notificationCopy.guideBody,
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
