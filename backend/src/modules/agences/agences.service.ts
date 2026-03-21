import bcrypt from 'bcrypt';
import prisma from '../../config/prisma';

export const createAgence = async (data: {
  nomAgence: string;
  email: string;
  motDePasse: string;
  adresse?: string;
  telephone?: string;
  siteWeb?: string;
}) => {
  const existing = await prisma.utilisateur.findUnique({
    where: { email: data.email },
  });

  if (existing) {
    throw new Error('Un compte avec cet email existe déjà');
  }

  const hash = await bcrypt.hash(data.motDePasse, 10);

  const utilisateur = await prisma.utilisateur.create({
    data: {
      email: data.email,
      motDePasse: hash,
      nom: data.nomAgence,
      prenom: '-',          // agencies don't have a prenom — using placeholder
      telephone: data.telephone,
      role: 'AGENCE',
      agence: {
        create: {
          nomAgence: data.nomAgence,
          adresse: data.adresse,
          siteWeb: data.siteWeb,
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