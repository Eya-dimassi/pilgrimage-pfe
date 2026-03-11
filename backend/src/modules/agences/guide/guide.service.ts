// src/services/guide.service.ts
import prisma from '../../../config/prisma';
import bcrypt from 'bcrypt'; // Utilisation de bcrypt au lieu de bcryptjs

/**
 * Créer un nouveau guide
 */
export const createGuide = async (
  agenceId: string,
  guideData: {
    nom: string;
    prenom: string;
    email: string;
    telephone?: string;
    specialite?: string;
    motDePasse: string;
  }
) => {
  // Vérifier que l'email n'existe pas déjà
  const existingUser = await prisma.utilisateur.findUnique({
    where: { email: guideData.email }
  });

  if (existingUser) {
    throw new Error('Un utilisateur avec cet email existe déjà');
  }

  // Vérifier que l'agence existe et est approuvée
  const agence = await prisma.agenceVoyage.findUnique({
    where: { id: agenceId }
  });

  if (!agence) {
    throw new Error('Agence introuvable');
  }

  if (agence.status !== 'APPROVED') {
    throw new Error('Seules les agences approuvées peuvent créer des guides');
  }

  // Hasher le mot de passe (bcrypt avec 10 rounds comme votre auth.service)
  const hashedPassword = await bcrypt.hash(guideData.motDePasse, 10);

  // Créer le guide avec transaction
  const guide = await prisma.$transaction(async (tx) => {
    // 1. Créer l'utilisateur
    const utilisateur = await tx.utilisateur.create({
      data: {
        email: guideData.email,
        motDePasse: hashedPassword,
        nom: guideData.nom,
        prenom: guideData.prenom,
        telephone: guideData.telephone,
        role: 'GUIDE',
        actif: true,
        createdById: agenceId
      }
    });

    // 2. Créer le profil guide
    const newGuide = await tx.guide.create({
      data: {
        utilisateurId: utilisateur.id,
        agenceId: agenceId,
        specialite: guideData.specialite
      },
      include: {
        utilisateur: {
          select: {
            id: true,
            email: true,
            nom: true,
            prenom: true,
            telephone: true,
            actif: true,
            createdAt: true
          }
        },
        _count: {
          select: {
            groupes: true
          }
        }
      }
    });

    return newGuide;
  });

  return guide;
};

/**
 * Récupérer tous les guides d'une agence
 */
export const getGuidesByAgence = async (agenceId: string) => {
  const guides = await prisma.guide.findMany({
    where: { agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          email: true,
          nom: true,
          prenom: true,
          telephone: true,
          actif: true,
          createdAt: true,
          updatedAt: true
        }
      },
      _count: {
        select: {
          groupes: true
        }
      }
    },
    orderBy: {
      createdAt: 'desc'
    }
  });

  return guides;
};

/**
 * Récupérer un guide par ID
 */
export const getGuideById = async (guideId: string, agenceId: string) => {
  const guide = await prisma.guide.findFirst({
    where: {
      id: guideId,
      agenceId // Vérifier que le guide appartient bien à cette agence
    },
    include: {
      utilisateur: {
        select: {
          id: true,
          email: true,
          nom: true,
          prenom: true,
          telephone: true,
          actif: true,
          createdAt: true,
          updatedAt: true
        }
      },
      groupes: {
        select: {
          id: true,
          nom: true,
          annee: true,
          typeVoyage: true,
          _count: {
            select: {
              pelerins: true
            }
          }
        }
      },
      _count: {
        select: {
          groupes: true
        }
      }
    }
  });

  if (!guide) {
    throw new Error('Guide introuvable ou non autorisé');
  }

  return guide;
};

/**
 * Mettre à jour un guide
 */
export const updateGuide = async (
  guideId: string,
  agenceId: string,
  updateData: {
    nom?: string;
    prenom?: string;
    email?: string;
    telephone?: string;
    specialite?: string;
    actif?: boolean;
  }
) => {
  // Vérifier que le guide appartient à l'agence
  const guide = await prisma.guide.findFirst({
    where: {
      id: guideId,
      agenceId
    }
  });

  if (!guide) {
    throw new Error('Guide introuvable ou non autorisé');
  }

  // Si l'email est modifié, vérifier qu'il n'existe pas déjà
  if (updateData.email) {
    const existingUser = await prisma.utilisateur.findFirst({
      where: {
        email: updateData.email,
        id: { not: guide.utilisateurId }
      }
    });

    if (existingUser) {
      throw new Error('Cet email est déjà utilisé');
    }
  }

  // Séparer les données utilisateur et guide
  const { specialite, ...utilisateurData } = updateData;

  // Mettre à jour avec transaction
  const updatedGuide = await prisma.$transaction(async (tx) => {
    // Mettre à jour l'utilisateur si nécessaire
    if (Object.keys(utilisateurData).length > 0) {
      await tx.utilisateur.update({
        where: { id: guide.utilisateurId },
        data: utilisateurData
      });
    }

    // Mettre à jour le profil guide si nécessaire
    const guideUpdate: any = {};
    if (specialite !== undefined) {
      guideUpdate.specialite = specialite;
    }

    const updated = await tx.guide.update({
      where: { id: guideId },
      data: guideUpdate,
      include: {
        utilisateur: {
          select: {
            id: true,
            email: true,
            nom: true,
            prenom: true,
            telephone: true,
            actif: true,
            createdAt: true,
            updatedAt: true
          }
        },
        _count: {
          select: {
            groupes: true
          }
        }
      }
    });

    return updated;
  });

  return updatedGuide;
};

/**
 * Supprimer un guide
 */
export const deleteGuide = async (guideId: string, agenceId: string) => {
  // Vérifier que le guide appartient à l'agence
  const guide = await prisma.guide.findFirst({
    where: {
      id: guideId,
      agenceId
    },
    include: {
      _count: {
        select: {
          groupes: true
        }
      }
    }
  });

  if (!guide) {
    throw new Error('Guide introuvable ou non autorisé');
  }

  // Vérifier que le guide n'a pas de groupes assignés
  if (guide._count.groupes > 0) {
    throw new Error(
      `Impossible de supprimer ce guide car il est assigné à ${guide._count.groupes} groupe(s). Veuillez d'abord retirer le guide de ses groupes.`
    );
  }

  // Supprimer le guide (cascade sur utilisateur grâce au onDelete: Cascade)
  await prisma.guide.delete({
    where: { id: guideId }
  });

  return { message: 'Guide supprimé avec succès' };
};

/**
 * Récupérer les guides disponibles (non assignés) d'une agence
 */
export const getAvailableGuides = async (agenceId: string) => {
  const guides = await prisma.guide.findMany({
    where: {
      agenceId,
      groupes: {
        none: {} // Guides sans groupes assignés
      }
    },
    include: {
      utilisateur: {
        select: {
          id: true,
          nom: true,
          prenom: true,
          email: true,
          telephone: true
        }
      }
    }
  });

  return guides;
};

/**
 * Obtenir les statistiques d'un guide
 */
export const getGuideStats = async (guideId: string, agenceId: string) => {
  const guide = await prisma.guide.findFirst({
    where: {
      id: guideId,
      agenceId
    },
    include: {
      groupes: {
        include: {
          _count: {
            select: {
              pelerins: true
            }
          }
        }
      }
    }
  });

  if (!guide) {
    throw new Error('Guide introuvable');
  }

  const stats = {
    totalGroupes: guide.groupes.length,
    totalPelerins: guide.groupes.reduce((sum, g) => sum + g._count.pelerins, 0),
    groupesParType: {
      HAJJ: guide.groupes.filter(g => g.typeVoyage === 'HAJJ').length,
      UMRAH: guide.groupes.filter(g => g.typeVoyage === 'UMRAH').length
    }
  };

  return stats;
};