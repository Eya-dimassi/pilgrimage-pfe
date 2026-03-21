import prisma from '../../../config/prisma';

// ── CREATE ────────────────────────────────────────────────────────────────────
export const createGroupe = async (
  agenceId: string,
  data: {
    nom: string;
    annee: number;
    typeVoyage: 'HAJJ' | 'UMRAH';
    description?: string;
    guideId?: string;
  }
) => {
  if (data.guideId) {
    const guide = await prisma.guide.findFirst({
      where: { id: data.guideId, agenceId },
      include: { utilisateur: { select: { actif: true } } }
    })
    if (!guide) throw new Error("Guide introuvable ou n'appartient pas à votre agence")
    if (!guide.utilisateur.actif) throw new Error("Ce guide n'a pas encore activé son compte")
  }

  return prisma.groupe.create({
    data: {
      nom: data.nom,
      annee: data.annee,
      typeVoyage: data.typeVoyage,
      description: data.description,
      agenceId,
      guideId: data.guideId ?? null,
    },
    include: {
      guide: {
        include: {
          utilisateur: { select: { nom: true, prenom: true, email: true } },
        },
      },
      _count: { select: { pelerins: true } },
    },
  })
}

// ── GET ALL ───────────────────────────────────────────────────────────────────
export const getGroupes = async (agenceId: string) => {
  return prisma.groupe.findMany({
    where: { agenceId },
    include: {
      guide: {
        include: {
          utilisateur: { select: { nom: true, prenom: true, email: true } },
        },
      },
      pelerins: {
        include: {
          utilisateur: { select: { id: true, nom: true, prenom: true, email: true } },
        },
      },
      _count: { select: { pelerins: true } },
    },
    orderBy: { createdAt: 'desc' },
  });
};

// ── GET ONE ───────────────────────────────────────────────────────────────────
export const getGroupeById = async (agenceId: string, groupeId: string) => {
  const groupe = await prisma.groupe.findFirst({
    where: { id: groupeId, agenceId },
    include: {
      guide: {
        include: {
          utilisateur: { select: { id: true, nom: true, prenom: true, email: true } },
        },
      },
      pelerins: {
        include: {
          utilisateur: { select: { id: true, nom: true, prenom: true, email: true, telephone: true } },
        },
      },
      _count: { select: { pelerins: true } },
    },
  });

  if (!groupe) throw new Error('Groupe introuvable');
  return groupe;
};

// ── UPDATE ────────────────────────────────────────────────────────────────────
export const updateGroupe = async (
  agenceId: string,
  groupeId: string,
  data: {
    nom?: string;
    description?: string;
    annee?: number;
    typeVoyage?: 'HAJJ' | 'UMRAH';
    guideId?: string | null;
  }
) => {
  const groupe = await prisma.groupe.findFirst({ where: { id: groupeId, agenceId } })
  if (!groupe) throw new Error('Groupe introuvable')

  if (data.guideId) {
    const guide = await prisma.guide.findFirst({
      where: { id: data.guideId, agenceId },
      include: { utilisateur: { select: { actif: true } } }
    })
    if (!guide) throw new Error("Guide introuvable ou n'appartient pas à votre agence")
    if (!guide.utilisateur.actif) throw new Error("Ce guide n'a pas encore activé son compte")
  }

  return prisma.groupe.update({
    where: { id: groupeId },
    data: {
      ...(data.nom !== undefined && { nom: data.nom }),
      ...(data.description !== undefined && { description: data.description }),
      ...(data.annee !== undefined && { annee: data.annee }),
      ...(data.typeVoyage !== undefined && { typeVoyage: data.typeVoyage }),
      ...(data.guideId !== undefined && { guideId: data.guideId }),
    },
    include: {
      guide: {
        include: {
          utilisateur: { select: { nom: true, prenom: true, email: true } },
        },
      },
      _count: { select: { pelerins: true } },
    },
  })
}

// ── DELETE ────────────────────────────────────────────────────────────────────
export const deleteGroupe = async (agenceId: string, groupeId: string) => {
  const groupe = await prisma.groupe.findFirst({ where: { id: groupeId, agenceId } });
  if (!groupe) throw new Error('Groupe introuvable');

  await prisma.groupe.delete({ where: { id: groupeId } });

  return { message: 'Groupe supprimé avec succès' };
};

// ── ASSIGN PELERIN ─────────────────────────────────────────────────────────────
// Schema: Pelerin has groupeId FK — assigning = setting groupeId on Pelerin
export const assignerPelerin = async (
  agenceId: string,
  groupeId: string,
  pelerinId: string
) => {
  const groupe = await prisma.groupe.findFirst({ where: { id: groupeId, agenceId } })
  if (!groupe) throw new Error('Groupe introuvable')

  const pelerin = await prisma.pelerin.findFirst({
    where: { id: pelerinId, agenceId },
    include: { utilisateur: { select: { actif: true } } }  // ← add this
  })
  if (!pelerin) throw new Error("Pèlerin introuvable ou n'appartient pas à votre agence")
  if (!pelerin.utilisateur.actif) throw new Error("Ce pèlerin n'a pas encore activé son compte")  // ← add this
  if (pelerin.groupeId === groupeId) throw new Error('Ce pèlerin est déjà dans ce groupe')

  await prisma.pelerin.update({
    where: { id: pelerinId },
    data: { groupeId },
  })

  return { message: 'Pèlerin ajouté au groupe avec succès' }
}

// ── REMOVE PELERIN ─────────────────────────────────────────────────────────────
export const retirerPelerin = async (
  agenceId: string,
  groupeId: string,
  pelerinId: string
) => {
  const pelerin = await prisma.pelerin.findFirst({ where: { id: pelerinId, agenceId } });
  if (!pelerin) throw new Error('Pèlerin introuvable');

  if (pelerin.groupeId !== groupeId) throw new Error("Ce pèlerin n'est pas dans ce groupe");

  await prisma.pelerin.update({
    where: { id: pelerinId },
    data: { groupeId: null },
  });

  return { message: 'Pèlerin retiré du groupe avec succès' };
};