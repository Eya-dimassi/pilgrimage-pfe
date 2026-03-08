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