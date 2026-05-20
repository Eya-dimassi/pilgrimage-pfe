import bcrypt from 'bcrypt';
import prisma from '../../config/prisma';
import { normalizeInternationalPhone } from '../../utils/phone.utils';

export const createAgence = async (data: {
  nomAgence: string;
  email: string;
  motDePasse: string;
  adresse?: string;
  telephone?: string;
  siteWeb?: string;
}) => {
  const normalizedAgenceName = data.nomAgence.trim();
  const normalizedEmail = data.email.trim().toLowerCase();
  const normalizedPassword = data.motDePasse.trim();
  const normalizedTelephone = data.telephone?.trim() ?? '';
  const normalizedAdresse = data.adresse?.trim() ?? '';
  const normalizedSiteWeb = data.siteWeb?.trim() || null;

  if (!normalizedTelephone) {
    throw new Error('Telephone requis');
  }

  if (!normalizedAdresse) {
    throw new Error('Adresse requise');
  }

  const existing = await prisma.utilisateur.findUnique({
    where: { email: normalizedEmail },
  });

  if (existing) {
    throw new Error('Un compte avec cet email existe déjà');
  }

  const hash = await bcrypt.hash(normalizedPassword, 10);
  const phoneNumber = normalizeInternationalPhone(normalizedTelephone);

  const utilisateur = await prisma.utilisateur.create({
    data: {
      email: normalizedEmail,
      motDePasse: hash,
      nom: normalizedAgenceName,
      prenom: '-',          // agencies don't have a prenom — using placeholder
      telephone: phoneNumber,
      role: 'AGENCE',
      agence: {
        create: {
          nomAgence: normalizedAgenceName,
          adresse: normalizedAdresse,
          siteWeb: normalizedSiteWeb,
        },
      },
    },
    include: { agence: true },
  });

  return {
    id: utilisateur.id,
    email: utilisateur.email,
    nomAgence: utilisateur.agence!.nomAgence,
    role: utilisateur.role,
    agenceId: utilisateur.agence!.id,
  };
};
export const getAgenceProfile = async (agenceId: string) => {
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id: agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          nom: true,
          prenom: true,
          email: true,
          telephone: true,
        },
      },
    },
  })
  if (!agence) throw new Error('Agence introuvable')
  return agence
}
 
export const updateAgenceProfile = async (
  agenceId: string,
  data: {
    nomAgence?: string
    adresse?: string
    siteWeb?: string
    telephone?: string
    logo?: string
  }
) => {
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id: agenceId },
    include: { utilisateur: true },
  })
  if (!agence) throw new Error('Agence introuvable')

  // ── 1. Update Utilisateur first ───────────────────────────
  if (data.telephone !== undefined || data.nomAgence !== undefined) {
    await prisma.utilisateur.update({
      where: { id: agence.utilisateurId },
      data: {
        ...(data.telephone !== undefined && { telephone: data.telephone }),
        ...(data.nomAgence !== undefined && { nom: data.nomAgence }),
      },
    })
  }

  // ── 2. Update AgenceVoyage and return fresh data ──────────
  return prisma.agenceVoyage.update({
    where: { id: agenceId },
    data: {
      ...(data.nomAgence !== undefined && { nomAgence: data.nomAgence }),
      ...(data.adresse   !== undefined && { adresse: data.adresse }),
      ...(data.siteWeb   !== undefined && { siteWeb: data.siteWeb }),
      ...(data.logo      !== undefined && { logo: data.logo }),
    },
    include: {
      utilisateur: {
        select: { id: true, nom: true, prenom: true, email: true, telephone: true },
      },
    },
  })
}

export const getAgences = async () => {
  return prisma.agenceVoyage.findMany({
    include: {
      utilisateur: {
        select: {
          id: true,
          email: true,
          nom: true,
          telephone: true,
          actif: true,
          createdAt: true,
        },
      },
    },
    orderBy: {
      createdAt: 'desc',
    },
  });
};

export const getAgenceSosHistory = async (agenceId: string) => {
  const alerts = await prisma.alerteSOS.findMany({
    where: {
      pelerin: {
        agenceId,
      },
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
      groupe: {
        select: {
          id: true,
          nom: true,
          typeVoyage: true,
        },
      },
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
            where: { actif: true },
            orderBy: { dateDebut: 'desc' },
            take: 1,
            select: {
              groupe: {
                select: {
                  id: true,
                  nom: true,
                  typeVoyage: true,
                },
              },
            },
          },
        },
      },
      resolueParGuide: {
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
  })

  return alerts.map((alert) => ({
    id: alert.id,
    latitude: alert.latitude,
    longitude: alert.longitude,
    statut: alert.statut,
    message: alert.message,
    createdAt: alert.createdAt,
    resolueAt: alert.resolueAt,
    pelerin: alert.pelerin,
    resolueParGuide: alert.resolueParGuide,
    type: alert.type,
    description: alert.description ?? '',
    groupe: alert.groupe ?? alert.pelerin.groupes[0]?.groupe ?? null,
  }))
}
