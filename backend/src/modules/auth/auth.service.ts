import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../../config/prisma';
import { env } from '../../config/env';

export const login = async(email: string, motDePasse: string) => {
  //sql query
  const utilisateur = await prisma.utilisateur.findUnique({
    where: { email },
    include: {
      agence: { select: { id: true } },
      guide: { select: { agenceId: true } },
      pelerin: { select: { agenceId: true } },
    },
  });

  if (!utilisateur || !utilisateur.actif) {
    throw new Error('Email ou mot de passe incorrect');
  }

  const passwordMatch = await bcrypt.compare(motDePasse, utilisateur.motDePasse);
  if (!passwordMatch) {
    throw new Error('Email ou mot de passe incorrect');
  }
  let agenceId: string | null = null;

  if (utilisateur.role === 'AGENCE' && utilisateur.agence) {
    agenceId = utilisateur.agence.id;
  } else if (utilisateur.role === 'GUIDE' && utilisateur.guide) {
    agenceId = utilisateur.guide.agenceId;
  } else if (utilisateur.role === 'PELERIN' && utilisateur.pelerin) {
    agenceId = utilisateur.pelerin.agenceId;
  }
  const accessToken = jwt.sign(
    {
      sub: utilisateur.id,
      email: utilisateur.email,
      role: utilisateur.role,
      agenceId,
    },
    env.JWT_SECRET,
    { expiresIn: '15m' }
  );

  const refreshToken = uuidv4();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);

  await prisma.refreshToken.create({
    data: {
      token: refreshToken,
      utilisateurId: utilisateur.id,
      expiresAt,
    },
  });

  return {
    accessToken,
    refreshToken,
    utilisateur: {
      id: utilisateur.id,
      nom: utilisateur.nom,
      prenom: utilisateur.prenom,
      email: utilisateur.email,
      role: utilisateur.role,
      agenceId,
    },
  };
};

export const getMe = async (userId: string) => {
  return prisma.utilisateur.findUnique({
    where: { id: userId },
    select: {
      id: true,
      nom: true,
      prenom: true,
      email: true,
      role: true,
      telephone: true,
    },
  });
};