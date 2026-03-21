import prisma from '../../config/prisma';
import { sendApprovalEmail, sendRejectionEmail, sendSuspensionEmail } from '../../utils/mailer.utils';


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
export const approveAgence = async (agenceId: string) => {
  // ── 1. DB update first — this is the source of truth ─────
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id: agenceId },
    include: { utilisateur: true },
  })
  if (!agence) throw new Error('Agence introuvable')
  if (agence.status === 'APPROVED') throw new Error('Agence déjà approuvée')

  await prisma.$transaction([
    prisma.agenceVoyage.update({
      where: { id: agenceId },
      data: { status: 'APPROVED' },
    }),
    prisma.utilisateur.update({
      where: { id: agence.utilisateurId },
      data: { actif: true },
    }),
  ])

  // ── 2. Email — best effort, never throws to caller ────────
  try {
    await sendApprovalEmail(agence.utilisateur.email, agence.nomAgence)
  } catch (mailError) {
    console.error('Approval email failed (agency already approved):', mailError)
    // don't rethrow — DB is already correct
  }

  return { message: 'Agence approuvée avec succès' }
}


//reject agency
export const rejectAgence = async (agenceId: string, _reason?: string) => {
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id: agenceId },
    include: { utilisateur: true },
  })
  if (!agence) throw new Error('Agence introuvable')
  if (agence.status === 'REJECTED') throw new Error('Agence déjà rejetée')

  await prisma.$transaction([
    prisma.agenceVoyage.update({
      where: { id: agenceId },
      data: { status: 'REJECTED' },
    }),
    prisma.utilisateur.update({
      where: { id: agence.utilisateurId },
      data: { actif: false },
    }),
  ])

  try {
    await sendRejectionEmail(agence.utilisateur.email, agence.nomAgence)
  } catch (mailError) {
    console.error('Rejection email failed (agency already rejected):', mailError)
  }

  return { message: 'Agence rejetée' }
}

export const suspendAgence = async (agenceId: string) => {
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id: agenceId },
    include: { utilisateur: true },
  })
  if (!agence) throw new Error('Agence introuvable')
  if (agence.status === 'SUSPENDED') throw new Error('Agence déjà suspendue')

  await prisma.$transaction([
    prisma.agenceVoyage.update({
      where: { id: agenceId },
      data: { status: 'SUSPENDED' },
    }),
    prisma.utilisateur.update({
      where: { id: agence.utilisateurId },
      data: { actif: false },
    }),
  ])

  try {
    await sendSuspensionEmail(agence.utilisateur.email, agence.nomAgence)
  } catch (mailError) {
    console.error('Suspension email failed (agency already suspended):', mailError)
  }

  // Also invalidate all refresh tokens so they get kicked immediately
  await prisma.refreshToken.deleteMany({
    where: { utilisateur: { agence: { id: agenceId } } }
  })

  return { message: 'Agence suspendue' }
}

export const deleteAgence = async (id: string) => {
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id },
  });

  if (!agence) {
    throw new Error('Agence introuvable');
  }

  await prisma.utilisateur.delete({
    where: { id: agence.utilisateurId },
  });

  return { message: 'Agence supprimée avec succès' };
};
