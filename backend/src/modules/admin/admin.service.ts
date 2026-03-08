import prisma from '../../config/prisma';
import { sendApprovalEmail } from '../../utils/mailer.utils';


//list agencies
export const getAgences = async (status?: string) => {
  return prisma.agenceVoyage.findMany({
    where: status ? { status: status as any } : undefined,
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
    orderBy: { createdAt: 'desc' },
  });
};

//agency details
export const getAgenceById = async (id: string) => {
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id },
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
      _count: {
        select: {
          guides: true,
          pelerins: true,
          groupes: true,
        },
      },
    },
  });

  if (!agence) throw new Error('Agence introuvable');
  return agence;
};

//approve agency
export const approveAgence = async (id: string) => {
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id },
    include: {
      utilisateur: { select: { email: true, nom: true } }
    }
  });
  if (!agence) throw new Error('Agence introuvable');
  if (agence.status!== 'PENDING') throw new Error('Seules les agences en attente peuvent être approuvées');

  await prisma.$transaction([
    prisma.agenceVoyage.update({
      where: { id },
      data: { status: 'APPROVED', approvedAt: new Date() },
    }),
    prisma.utilisateur.update({
      where: { id: agence.utilisateurId },
      data: { actif: true },
    }),
  ]);
  // send approval email
  await sendApprovalEmail(agence.utilisateur.email, agence.nomAgence);

  return { message: 'Agence approuvée avec succès' };
};


//reject agency
export const rejectAgence = async(id: string, reason: string) => {
  const agence = await prisma.agenceVoyage.findUnique({ where: { id } });
  if (!agence) throw new Error('Agence introuvable');

if (agence.status !== 'PENDING') {
    throw new Error("Seules les agences en attente peuvent être refusées");
  }

  await prisma.$transaction([
    prisma.agenceVoyage.update({
      where: { id },
      data: {status: 'REJECTED', rejectedAt: new Date(), rejectionReason: reason },
    }),
    prisma.utilisateur.update({
      where: {id: agence.utilisateurId },
      data: {actif: false },
    }),
  ]);

  return { message: 'Agence refusée' };
};

export const suspendAgence = async (id: string) => {
  const agence = await prisma.agenceVoyage.findUnique({ where: { id } });
  if (!agence) throw new Error('Agence introuvable');

  if (agence.status !== 'APPROVED') {
    throw new Error("Seules les agences approuvées peuvent être suspendues");
  }

  await prisma.$transaction([
    prisma.agenceVoyage.update({
      where: { id },
      data: { status: 'SUSPENDED' },
    }),
    prisma.utilisateur.update({
      where: { id: agence.utilisateurId },
      data: { actif: false },
    }),
  ]);

  return { message: 'Agence suspendue' };
};


