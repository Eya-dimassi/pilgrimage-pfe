import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../../config/prisma';
import { env } from '../../config/env';
import { Role,StatutAgence} from '../../../generated/prisma/enums';
import { createPasswordToken, verifyPasswordToken, consumePasswordToken, hashToken } from '../../utils/token.utils';
import { sendPasswordResetEmail } from '../../utils/mailer.utils';



export const login =async(email: string, motDePasse: string) => {
  //sql query
  const utilisateur = await prisma.utilisateur.findUnique({
    where: { email },
    include: {
      agence: { select: { id: true, status: true } },
      guide: { select: { agenceId: true } },
      pelerin: { select: { agenceId: true } },
      famille: { select: { agenceId: true } },
    },
  });


if (!utilisateur) {
  throw new Error('Email ou mot de passe incorrect');
}

// password not set yet
  if (!utilisateur.motDePasse) {
    throw new Error('Compte non activé');
  }

//agence status check 
  if (utilisateur.role === 'AGENCE' && utilisateur.agence) {
    if (utilisateur.agence.status === 'PENDING') {
      throw new Error('Votre compte est en attente de validation');
    }
    if (utilisateur.agence.status === 'REJECTED') {
      throw new Error('Votre demande a été refusée');
    }
    if (utilisateur.agence.status === 'SUSPENDED') {
      throw new Error('Votre compte a été suspendu');
    }
  }
  //user not found or inactive
  if (!utilisateur.actif) {
    throw new Error('Compte inactif');
  }
  

  //password check
  const passwordMatch =await bcrypt.compare(motDePasse, utilisateur.motDePasse);
  if (!passwordMatch) {
    throw new Error('Email ou mot de passe incorrect');
  }


  let agenceId: string | null =null;

  if (utilisateur.role === 'AGENCE' && utilisateur.agence) {
    agenceId = utilisateur.agence.id;
  } else if (utilisateur.role === 'GUIDE' && utilisateur.guide) {
    agenceId = utilisateur.guide.agenceId;
  } else if (utilisateur.role === 'PELERIN' && utilisateur.pelerin) {
    agenceId = utilisateur.pelerin.agenceId;
  }else if (utilisateur.role === 'FAMILLE' && utilisateur.famille) {
    agenceId = utilisateur.famille.agenceId;
  }


  const accessToken = jwt.sign(
    {
      sub: utilisateur.id,
      email: utilisateur.email,
      role: utilisateur.role,
      agenceId,
    },
    env.JWT_SECRET,
      {expiresIn: '15m'}
  );

  const refreshToken = uuidv4();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate()+30);

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


export const signup = async (data: {
  nomAgence: string;
  email: string;
  motDePasse: string;
  telephone?: string;
  adresse?: string;
}) => {
  // check email not already taken
  const exist = await prisma.utilisateur.findUnique({
    where: { email: data.email },
  });
  if (exist) throw new Error('Un compte avec cet email existe déjà');

  const hash = await bcrypt.hash(data.motDePasse, 10);

  const utilisateur = await prisma.utilisateur.create({
    data: {
      email: data.email,
      motDePasse: hash,
      nom: data.nomAgence,
      prenom: '-',
      telephone: data.telephone,
      role: Role.AGENCE,
      actif: false,          // can't log in until approved
      agence: {
        create: {
          nomAgence: data.nomAgence,
          adresse: data.adresse,
          status: StatutAgence.PENDING, // admin must approve
        },
      },
    },
    include: { agence: true },
  });

  return {
    message: 'Demande envoyée, en attente de validation par l\'administrateur',
    agenceId: utilisateur.agence!.id,
  };
};

export const logout = async (refreshToken: string) => {
  await prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
};




export const refresh = async (refreshToken: string) => {
  const tokenRecord = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
    include: { utilisateur: true },
  });

  if (!tokenRecord) throw new Error('Refresh token invalide');
  
  if (tokenRecord.expiresAt < new Date()) {
    await prisma.refreshToken.delete({ where: { token: refreshToken } });
    throw new Error('Refresh token expiré');
  }

  const utilisateur = tokenRecord.utilisateur;

  const accessToken = jwt.sign(
    {
      sub: utilisateur.id,
      email: utilisateur.email,
      role: utilisateur.role,
    },
    env.JWT_SECRET,
    { expiresIn: '15m' }
  );

  // rotate refresh token — old one deleted, new one created
  const newRefreshToken = uuidv4();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);

  await prisma.refreshToken.update({
    where: { token: refreshToken },
    data: { token: newRefreshToken, expiresAt },
  });

  return { accessToken, refreshToken: newRefreshToken };
};


export const getMe =async(userId: string) => {
  return prisma.utilisateur.findUnique({
    where: {id:userId},
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



// ── FORGOT PASSWORD ────────────────────────────────────────
export const forgotPassword = async (email: string) => {
  const utilisateur = await prisma.utilisateur.findUnique({ where: { email } });

  // always return same message — don't reveal if email exists
  if (!utilisateur) {
    return { message: 'Si cet email existe, un lien de réinitialisation a été envoyé' };
  }

  const plainToken = await createPasswordToken(utilisateur.id, 'RESET_PASSWORD');
  await sendPasswordResetEmail(email, utilisateur.nom, plainToken);

  return { message: 'Si cet email existe, un lien de réinitialisation a été envoyé' };
};

// ── SET PASSWORD ───────────────────────────────────────────
export const setPassword = async (plainToken: string, newPassword: string) => {
  const record = await verifyPasswordToken(plainToken);

  if (newPassword.length < 8) {
    throw new Error('Mot de passe trop court (8 caractères minimum)');
  }

  const hash = await bcrypt.hash(newPassword, 10);

  await prisma.utilisateur.update({
    where: { id: record.utilisateurId },
    data: { motDePasse: hash, actif: true },
  });

  await consumePasswordToken(record.tokenHash);

  return { message: 'Mot de passe défini avec succès' };
};
// ⭐ AJOUTER CETTE FONCTION
export const verifyActivationToken = async (token: string) => {
  // Vérifier et décoder le token
  const record = await verifyPasswordToken(token);
  
  // Récupérer les infos de l'utilisateur
  const utilisateur = await prisma.utilisateur.findUnique({
    where: { id: record.utilisateurId },
    select: {
      id: true,
      email: true,
      nom: true,
      prenom: true,
      actif: true,
      motDePasse: true
    }
  });

  if (!utilisateur) {
    throw new Error('Utilisateur introuvable');
  }

  // Si déjà activé, erreur
  if (utilisateur.actif && utilisateur.motDePasse) {
    throw new Error('Ce compte est déjà activé');
  }

  return {
    email: utilisateur.email,
    nom: `${utilisateur.prenom} ${utilisateur.nom}`
  };
};