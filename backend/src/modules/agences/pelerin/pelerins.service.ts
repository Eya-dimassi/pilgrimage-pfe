import prisma from '../../../config/prisma';
import { createPasswordToken } from '../../../utils/token.utils';
import { sendActivationEmail } from '../../../utils/mailer.utils';
import { v4 as uuidv4 } from 'uuid';

// ── CREATE ────────────────────────────────────────────────────────────────────
export const createPelerin = async (
  agenceId: string,
  createdById: string,
  data: {
    nom: string;
    prenom: string;
    email: string;
    telephone?: string;
    dateNaissance?: string;
    numeroPasseport?: string;
    nationalite?: string;
  }
) => {
  const existing = await prisma.utilisateur.findUnique({ where: { email: data.email } });
  if (existing) throw new Error('Un compte avec cet email existe déjà');

  const utilisateur = await prisma.utilisateur.create({
    data: {
      email: data.email,
      motDePasse: null,
      nom: data.nom,
      prenom: data.prenom,
      telephone: data.telephone,
      role: 'PELERIN',
      actif: false,
      createdById,
      pelerin: {
        create: {
          agenceId,
          codeUnique: uuidv4(),
          nationalite: data.nationalite,
          numeroPasseport: data.numeroPasseport,
          dateNaissance: data.dateNaissance ? new Date(data.dateNaissance) : undefined,
        },
      },
    },
    include: { pelerin: true },
  });

  const plainToken = await createPasswordToken(utilisateur.id, 'SET_PASSWORD');
  await sendActivationEmail(utilisateur.email, utilisateur.prenom, plainToken);

  return {
    id: utilisateur.id,
    email: utilisateur.email,
    nom: utilisateur.nom,
    prenom: utilisateur.prenom,
    telephone: utilisateur.telephone,
    pelerinId: utilisateur.pelerin!.id,
    agenceId,
  };
};

// ── GET ALL ───────────────────────────────────────────────────────────────────
export const getPelerins = async (agenceId: string) => {
  const list = await prisma.pelerin.findMany({
    where: { agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          nom: true,
          prenom: true,
          email: true,
          telephone: true,
          actif: true,
          createdAt: true,
        },
      },
      groupes: {
        where: { actif: true },
        take: 1,
        orderBy: { dateDebut: 'desc' },
        include: {
          groupe: { select: { id: true, nom: true } },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return list.map((p) => {
    const membership = p.groupes?.[0] ?? null;
    return {
      ...p,
      groupeId: membership?.groupeId ?? null,
      groupe: membership?.groupe ?? null,
    };
  });
};

// ── GET ONE ───────────────────────────────────────────────────────────────────
export const getPelerinById = async (agenceId: string, pelerinId: string) => {
  const pelerin = await prisma.pelerin.findFirst({
    where: { id: pelerinId, agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          nom: true,
          prenom: true,
          email: true,
          telephone: true,
          actif: true,
          createdAt: true,
        },
      },
      groupes: {
        where: { actif: true },
        take: 1,
        orderBy: { dateDebut: 'desc' },
        include: {
          groupe: { select: { id: true, nom: true, typeVoyage: true } },
        },
      },
    },
  });

  if (!pelerin) throw new Error('Pèlerin introuvable');
  const membership = pelerin.groupes?.[0] ?? null;
  return {
    ...pelerin,
    groupeId: membership?.groupeId ?? null,
    groupe: membership?.groupe ?? null,
  };
};

// ── UPDATE ────────────────────────────────────────────────────────────────────
export const updatePelerin = async (
  agenceId: string,
  pelerinId: string,
  data: {
    nom?: string;
    prenom?: string;
    telephone?: string;
    nationalite?: string;
    numeroPasseport?: string;
    dateNaissance?: string;
  }
) => {
  const pelerin = await prisma.pelerin.findFirst({ where: { id: pelerinId, agenceId } });
  if (!pelerin) throw new Error('Pèlerin introuvable');

  const { nom, prenom, telephone, ...pelerinFields } = data;

  if (nom || prenom || telephone) {
    await prisma.utilisateur.update({
      where: { id: pelerin.utilisateurId },
      data: {
        ...(nom && { nom }),
        ...(prenom && { prenom }),
        ...(telephone && { telephone }),
      },
    });
  }

  return prisma.pelerin.update({
    where: { id: pelerinId },
    data: {
      ...(pelerinFields.nationalite && { nationalite: pelerinFields.nationalite }),
      ...(pelerinFields.numeroPasseport && { numeroPasseport: pelerinFields.numeroPasseport }),
      ...(pelerinFields.dateNaissance && { dateNaissance: new Date(pelerinFields.dateNaissance) }),
    },
    include: {
      utilisateur: {
        select: { id: true, nom: true, prenom: true, email: true, telephone: true, actif: true },
      },
      groupes: {
        where: { actif: true },
        take: 1,
        orderBy: { dateDebut: 'desc' },
        include: {
          groupe: { select: { id: true, nom: true } },
        },
      },
    },
  }).then((p) => {
    const membership = p.groupes?.[0] ?? null;
    return {
      ...p,
      groupeId: membership?.groupeId ?? null,
      groupe: membership?.groupe ?? null,
    };
  });
};

// ── DELETE ────────────────────────────────────────────────────────────────────
export const deletePelerin = async (agenceId: string, pelerinId: string) => {
  const pelerin = await prisma.pelerin.findFirst({ where: { id: pelerinId, agenceId } });
  if (!pelerin) throw new Error('Pèlerin introuvable');

  await prisma.utilisateur.delete({ where: { id: pelerin.utilisateurId } });

  return { message: 'Pèlerin supprimé avec succès' };
};

/**
 * Renvoyer l'email d'activation à un pèlerin
 */
export const resendActivationEmail = async (pelerinId: string, agenceId: string) => {
  const pelerin = await prisma.pelerin.findFirst({
    where: { id: pelerinId, agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          email: true,
          nom: true,
          prenom: true,
          actif: true,
          motDePasse: true,
        },
      },
    },
  });

  if (!pelerin) throw new Error('Pèlerin introuvable');

  if (pelerin.utilisateur.actif && pelerin.utilisateur.motDePasse) {
    throw new Error('Ce pèlerin a déjà activé son compte');
  }

  const activationToken = await createPasswordToken(pelerin.utilisateur.id, 'SET_PASSWORD');
  await sendActivationEmail(
    pelerin.utilisateur.email,
    pelerin.utilisateur.prenom || pelerin.utilisateur.nom,
    activationToken
  );

  return { message: "Email d'activation renvoyé avec succès" };
};
