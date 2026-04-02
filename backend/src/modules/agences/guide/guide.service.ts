// src/services/guide.service.ts
import prisma from '../../../config/prisma';
import { createPasswordToken } from '../../../utils/token.utils';
import { sendActivationEmail } from '../../../utils/mailer.utils'; // ⭐ AJOUTER

/**
 * Créer un nouveau guide SANS mot de passe
 * Envoie un email avec lien d'activation
 */
export const createGuide = async (
  agenceId: string,
  guideData: {
    nom: string;
    prenom: string;
    email: string;
    telephone?: string;
    specialite?: string;
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
    where: { id: agenceId },
    select: {
      id: true,
      status: true,
      nomAgence: true
    }
  });

  if (!agence) {
    throw new Error('Agence introuvable');
  }

  if (agence.status !== 'APPROVED') {
    throw new Error('Seules les agences approuvées peuvent créer des guides');
  }

  // Créer le guide SANS mot de passe
  const result = await prisma.$transaction(async (tx) => {
    // 1. Créer l'utilisateur SANS mot de passe
    const utilisateur = await tx.utilisateur.create({
      data: {
        email: guideData.email,
        motDePasse: null, //  PAS DE MOT DE PASSE
        nom: guideData.nom,
        prenom: guideData.prenom,
        telephone: guideData.telephone,
        role: 'GUIDE',
        actif: false, // INACTIF jusqu'à activation
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

    return { utilisateur, guide: newGuide };
  });

  // 3. Générer le token d'activation (expire dans 7 jours)
  const activationToken = await createPasswordToken(
    result.utilisateur.id,
    'SET_PASSWORD'
  );

  // 4. Envoyer l'email d'activation au guide
  await sendActivationEmail(
    guideData.email,
    guideData.nom,
    activationToken
  );

  return result.guide;
};

// ⭐ AJOUTER CETTE NOUVELLE FONCTION
/**
 * Renvoyer l'email d'activation à un guide
 */
export const resendActivationEmail = async (guideId: string, agenceId: string) => {
  const guide = await prisma.guide.findFirst({
    where: {
      id: guideId,
      agenceId
    },
    include: {
      utilisateur: {
        select: {
          id: true,
          email: true,
          nom: true,
          prenom: true,
          actif: true,
          motDePasse: true
        }
      },
      agence: {
        select: {
          nomAgence: true
        }
      }
    }
  });

  if (!guide) {
    throw new Error('Guide introuvable');
  }

  // Si déjà activé, pas besoin de renvoyer
  if (guide.utilisateur.actif && guide.utilisateur.motDePasse) {
    throw new Error('Ce guide a déjà activé son compte');
  }

  // Générer nouveau token
  const activationToken = await createPasswordToken(
    guide.utilisateur.id,
    'SET_PASSWORD'
  );

  // Renvoyer l'email
  await sendActivationEmail(
    guide.utilisateur.email,
    guide.utilisateur.nom,
    activationToken
  );

  return { message: 'Email d\'activation renvoyé avec succès' };
};

// ⭐ MODIFIER getGuidesByAgence pour ajouter isActivated
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
          motDePasse: true, // ⭐ AJOUTER pour vérifier activation
          createdAt: true,
          updatedAt: true
        }
      },
      _count: {
        select: {
          groupes: { where: { actif: true } }
        }
      }
    },
    orderBy: {
      createdAt: 'desc'
    }
  });

  // ⭐  le statut d'activation
  return guides.map(guide => ({
    ...guide,
    isActivated: guide.utilisateur.motDePasse !== null, // ← AU NIVEAU RACINE
    utilisateur: {
      ...guide.utilisateur,
      motDePasse: undefined // Ne pas exposer le hash
    }
  }));
};

// Gardez les autres fonctions telles quelles (getGuideById, updateGuide, deleteGuide, etc.)

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
        where: { actif: true },
        include: {
          groupe: {
            select: {
              id: true,
              nom: true,
              annee: true,
              typeVoyage: true,
              _count: {
                select: {
                  membres: { where: { actif: true } }
                }
              }
            }
          }
        },
      },
      _count: {
        select: {
          groupes: { where: { actif: true } }
        }
      }
    }
  });

  if (!guide) {
    throw new Error('Guide introuvable ou non autorisé');
  }

  return {
    ...guide,
    groupes: (guide.groupes ?? []).map((rel) => ({
      ...rel.groupe,
      _count: {
        pelerins: rel.groupe?._count?.membres ?? 0,
      },
    })),
  };
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
          groupes: { where: { actif: true } }
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
      agenceId
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
        where: { actif: true },
        include: {
          groupe: {
            select: {
              typeVoyage: true,
              _count: {
                select: {
                  membres: { where: { actif: true } }
                }
              }
            }
          }
        },
      }
    }
  });

  if (!guide) {
    throw new Error('Guide introuvable');
  }

  const activeGroupes = (guide.groupes ?? [])
    .map((rel) => rel.groupe)
    .filter((groupe): groupe is NonNullable<typeof groupe> => Boolean(groupe));

  const stats = {
    totalGroupes: activeGroupes.length,
    totalPelerins: activeGroupes.reduce((sum: number, g) => sum + (g._count?.membres ?? 0), 0),
    groupesParType: {
      HAJJ: activeGroupes.filter((g) => g.typeVoyage === 'HAJJ').length,
      UMRAH: activeGroupes.filter((g) => g.typeVoyage === 'UMRAH').length
    }
  };

  return stats;
};
