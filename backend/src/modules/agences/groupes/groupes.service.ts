// backend/src/modules/agence/groupes/groupes.service.ts

import prisma from '../../../config/prisma';

function mapGroupeForAgenceDashboard(groupe: any) {
  const guidesList = Array.isArray(groupe.guides)
    ? groupe.guides.map((rel: any) => rel.guide).filter(Boolean)
    : [];
  const activeGuide = guidesList[0] ?? null;
  const pelerins = Array.isArray(groupe.membres) ? groupe.membres.map((m: any) => m.pelerin) : [];

  return {
    ...groupe,
    guideIds: guidesList.map((g: any) => g.id),
    guides: guidesList,
    guideId: activeGuide?.id ?? null,
    guide: activeGuide,
    pelerins,
    _count: {
      ...(groupe._count ?? {}),
      pelerins: groupe._count?.membres ?? pelerins.length,
    },
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// CREATE
// ══════════════════════════════════════════════════════════════════════════════
export const createGroupe = async (
  agenceId: string,
  data: {
    nom: string;
    annee: number;
    typeVoyage: 'HAJJ' | 'UMRAH';
    description?: string;
    guideId?: string;
    guideIds?: string[];
    status?: 'PLANIFIE' | 'EN_COURS' | 'TERMINE' | 'ANNULE';
    dateDepart?: string | Date;
    dateRetour?: string | Date;
  }
) => {
  const guideIds = Array.isArray(data.guideIds)
    ? Array.from(new Set(data.guideIds.filter(Boolean)))
    : data.guideId
      ? [data.guideId]
      : [];

  if (guideIds.length > 0) {
    const guides = await prisma.guide.findMany({
      where: { id: { in: guideIds }, agenceId },
      include: { utilisateur: { select: { actif: true } } },
    });

    if (guides.length !== guideIds.length) {
      throw new Error("Guide introuvable ou n'appartient pas à votre agence");
    }

    const inactiveGuide = guides.find((g) => !g.utilisateur.actif);
    if (inactiveGuide) {
      throw new Error("Ce guide n'a pas encore activé son compte");
    }
  }

  const parsedDateDepart = data.dateDepart ? new Date(data.dateDepart) : undefined;
  const parsedDateRetour = data.dateRetour ? new Date(data.dateRetour) : undefined;

  if (parsedDateDepart && Number.isNaN(parsedDateDepart.getTime())) {
    throw new Error('dateDepart invalide');
  }

  if (parsedDateRetour && Number.isNaN(parsedDateRetour.getTime())) {
    throw new Error('dateRetour invalide');
  }

  if (parsedDateDepart && parsedDateRetour && parsedDateRetour < parsedDateDepart) {
    throw new Error('dateRetour doit etre >= dateDepart');
  }

  // Empêcher les doublons de nom (même agence + même année)
  const existingByName = await prisma.groupe.findFirst({
    where: {
      agenceId,
      annee: data.annee,
      nom: { equals: data.nom, mode: 'insensitive' },
    },
    select: { id: true },
  })

  if (existingByName) {
    throw new Error('Un groupe avec ce nom existe deja pour cette annee')
  }

  // Créer le groupe
  const groupe = await prisma.groupe.create({
    data: {
      nom: data.nom,
      annee: data.annee,
      typeVoyage: data.typeVoyage,
      description: data.description,
      status: data.status,
      dateDepart: parsedDateDepart,
      dateRetour: parsedDateRetour,
      agenceId,
    },
    include: {
      _count: { 
        select: { 
          membres: { where: { actif: true } }  // ⭐ Compter seulement les actifs
        } 
      },
    },
  });

  if (guideIds.length > 0) {
    await prisma.groupeGuide.createMany({
      data: guideIds.map((guideId) => ({
        groupeId: groupe.id,
        guideId,
        actif: true,
      })),
      skipDuplicates: true,
    });
  }

  // Récupérer le groupe complet avec le guide
  const full = await prisma.groupe.findUnique({
    where: { id: groupe.id },
    include: {
      guides: {
        where: { actif: true },
        include: {
          guide: {
            include: {
              utilisateur: { select: { nom: true, prenom: true, email: true } },
            },
          },
        },
      },
      membres: {
        where: { actif: true },
        include: {
          pelerin: {
            include: {
              utilisateur: {
                select: { id: true, nom: true, prenom: true, email: true },
              },
            },
          },
        },
      },
      _count: { 
        select: { 
          membres: { where: { actif: true } } 
        } 
      },
    },
  });

  return full ? mapGroupeForAgenceDashboard(full) : full;
};

// ══════════════════════════════════════════════════════════════════════════════
// GET ALL
// ══════════════════════════════════════════════════════════════════════════════
export const getGroupes = async (agenceId: string) => {
  const list = await prisma.groupe.findMany({
    where: { agenceId },
    include: {
      guides: {
        where: { actif: true },  // ⭐ Seulement le guide actif
        include: {
          guide: {
            include: {
              utilisateur: { select: { nom: true, prenom: true, email: true } },
            },
          },
        },
      },
      membres: {
        where: { actif: true },  // ⭐ Seulement les membres actifs
        include: {
          pelerin: {
            include: {
              utilisateur: { 
                select: { id: true, nom: true, prenom: true, email: true, telephone: true } 
              },
            },
          },
        },
      },
      _count: { 
        select: { 
          membres: { where: { actif: true } } 
        } 
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return list.map(mapGroupeForAgenceDashboard);
};

// ══════════════════════════════════════════════════════════════════════════════
// GET ONE
// ══════════════════════════════════════════════════════════════════════════════
export const getGroupeById = async (agenceId: string, groupeId: string) => {
  const groupe = await prisma.groupe.findFirst({
    where: { id: groupeId, agenceId },
    include: {
      guides: {
        where: { actif: true },
        include: {
          guide: {
            include: {
              utilisateur: { 
                select: { id: true, nom: true, prenom: true, email: true } 
              },
            },
          },
        },
      },
      membres: {
        where: { actif: true },
        include: {
          pelerin: {
            include: {
              utilisateur: { 
                select: { id: true, nom: true, prenom: true, email: true, telephone: true } 
              },
            },
          },
        },
      },
      _count: { 
        select: { 
          membres: { where: { actif: true } } 
        } 
      },
    },
  });

  if (!groupe) {
    throw new Error('Groupe introuvable');
  }
  
  return mapGroupeForAgenceDashboard(groupe);
};

// ══════════════════════════════════════════════════════════════════════════════
// UPDATE
// ══════════════════════════════════════════════════════════════════════════════
export const updateGroupe = async (
  agenceId: string,
  groupeId: string,
  data: {
    nom?: string;
    description?: string;
    annee?: number;
    typeVoyage?: 'HAJJ' | 'UMRAH';
    guideId?: string | null;
    guideIds?: string[];
    status?: 'PLANIFIE' | 'EN_COURS' | 'TERMINE' | 'ANNULE';
    dateDepart?: string | Date | null;
    dateRetour?: string | Date | null;
  }
) => {
  // Vérifier que le groupe existe et appartient à l'agence
  const groupe = await prisma.groupe.findFirst({ 
    where: { id: groupeId, agenceId } 
  });
  
  if (!groupe) {
    throw new Error('Groupe introuvable');
  }

  if (data.nom) {
    const nextYear = data.annee ?? groupe.annee
    const existingByName = await prisma.groupe.findFirst({
      where: {
        agenceId,
        annee: nextYear,
        id: { not: groupeId },
        nom: { equals: data.nom, mode: 'insensitive' },
      },
      select: { id: true },
    })

    if (existingByName) {
      throw new Error('Un groupe avec ce nom existe deja pour cette annee')
    }
  }

  let requestedGuideIds: string[] | null = null;
  if (Array.isArray(data.guideIds)) {
    requestedGuideIds = Array.from(new Set(data.guideIds.filter(Boolean)));
  } else if (data.guideId !== undefined) {
    requestedGuideIds = data.guideId ? [data.guideId] : [];
  }

  const nextStatus = data.status ?? groupe.status
  if (requestedGuideIds !== null && ['TERMINE', 'ANNULE'].includes(nextStatus)) {
    throw new Error("Impossible d'affecter des guides pour ce groupe")
  }

  if (requestedGuideIds && requestedGuideIds.length > 0) {
    const guides = await prisma.guide.findMany({
      where: { id: { in: requestedGuideIds }, agenceId },
      include: { utilisateur: { select: { actif: true } } },
    });

    if (guides.length !== requestedGuideIds.length) {
      throw new Error("Guide introuvable ou n'appartient pas à votre agence");
    }

    const inactiveGuide = guides.find((g) => !g.utilisateur.actif);
    if (inactiveGuide) {
      throw new Error("Ce guide n'a pas encore activé son compte");
    }
  }

  const parsedDateDepart = data.dateDepart === null ? null : (data.dateDepart ? new Date(data.dateDepart) : undefined);
  const parsedDateRetour = data.dateRetour === null ? null : (data.dateRetour ? new Date(data.dateRetour) : undefined);

  if (parsedDateDepart instanceof Date && Number.isNaN(parsedDateDepart.getTime())) {
    throw new Error('dateDepart invalide');
  }

  if (parsedDateRetour instanceof Date && Number.isNaN(parsedDateRetour.getTime())) {
    throw new Error('dateRetour invalide');
  }

  const finalDateDepart = parsedDateDepart === undefined ? groupe.dateDepart : parsedDateDepart;
  const finalDateRetour = parsedDateRetour === undefined ? groupe.dateRetour : parsedDateRetour;

  if (finalDateDepart && finalDateRetour && finalDateRetour < finalDateDepart) {
    throw new Error('dateRetour doit etre >= dateDepart');
  }

  if (requestedGuideIds !== null) {
    const now = new Date();
    const activeRelations = await prisma.groupeGuide.findMany({
      where: { groupeId, actif: true },
      select: { guideId: true },
    });
    const activeIds = activeRelations.map((rel) => rel.guideId);

    if (requestedGuideIds.length === 0) {
      await prisma.groupeGuide.updateMany({
        where: { groupeId, actif: true },
        data: { actif: false, dateFin: now },
      });
    } else {
      await prisma.groupeGuide.updateMany({
        where: {
          groupeId,
          actif: true,
          guideId: { notIn: requestedGuideIds },
        },
        data: { actif: false, dateFin: now },
      });

      const toAdd = requestedGuideIds.filter((id) => !activeIds.includes(id));
      if (toAdd.length > 0) {
        await prisma.groupeGuide.createMany({
          data: toAdd.map((guideId) => ({
            groupeId,
            guideId,
            actif: true,
          })),
          skipDuplicates: true,
        });
      }
    }
  }

  // Mettre à jour le groupe
  const updated = await prisma.groupe.update({
    where: { id: groupeId },
    data: {
      ...(data.nom !== undefined && { nom: data.nom }),
      ...(data.description !== undefined && { description: data.description }),
      ...(data.annee !== undefined && { annee: data.annee }),
      ...(data.typeVoyage !== undefined && { typeVoyage: data.typeVoyage }),
      ...(data.status !== undefined && { status: data.status }),
      ...(parsedDateDepart !== undefined && { dateDepart: parsedDateDepart }),
      ...(parsedDateRetour !== undefined && { dateRetour: parsedDateRetour }),
    },
    include: {
      guides: {
        where: { actif: true },
        include: {
          guide: {
            include: {
              utilisateur: { select: { nom: true, prenom: true, email: true } },
            },
          },
        },
      },
      membres: {
        where: { actif: true },
        include: {
          pelerin: {
            include: {
              utilisateur: {
                select: { id: true, nom: true, prenom: true, email: true, telephone: true },
              },
            },
          },
        },
      },
      _count: { 
        select: { 
          membres: { where: { actif: true } } 
        } 
      },
    },
  });

  return mapGroupeForAgenceDashboard(updated);
};

// ══════════════════════════════════════════════════════════════════════════════
// DELETE ⭐ CORRIGÉ
// ══════════════════════════════════════════════════════════════════════════════
export const deleteGroupe = async (agenceId: string, groupeId: string) => {
  // 1. Vérifier que le groupe existe et appartient à l'agence
  const groupe = await prisma.groupe.findFirst({ 
    where: { id: groupeId, agenceId },
    include: {
      _count: {
        select: {
          membres: { where: { actif: true } }  // ⭐ Compter membres actifs
        }
      }
    }
  });
  
  if (!groupe) {
    // Vérifier si le groupe existe mais appartient à une autre agence
    const groupeExists = await prisma.groupe.findUnique({
      where: { id: groupeId },
    });

    if (groupeExists) {
      throw new Error('Accès refusé : ce groupe appartient à une autre agence');
    } else {
      throw new Error('Groupe introuvable');
    }
  }

  // 2. ⭐ VÉRIFIER QUE LE GROUPE EST VIDE
  const nombreMembresActifs = groupe._count.membres;

  if (nombreMembresActifs > 0) {
    const updated = await prisma.groupe.update({
      where: { id: groupeId },
      data: { status: 'ANNULE' },
      include: { 
        guides: {
          where: { actif: true },
          include: {
            guide: {
              include: {
                utilisateur: { select: { nom: true, prenom: true, email: true } },
              },
            },
          },
        },
        membres: {
          where: { actif: true },
          include: {
            pelerin: {
              include: {
                utilisateur: {
                  select: { id: true, nom: true, prenom: true, email: true, telephone: true },
                },
              },
            },
          },
        },
        _count: {
          select: {
            membres: { where: { actif: true } },
          },
        },
      },
    })

    return {
      action: 'status_changed',
      message: `Le groupe contient ${nombreMembresActifs} pèlerin(s) actif(s) : suppression interdite`,
      groupe: mapGroupeForAgenceDashboard(updated),
    }
  }

  // 3. Supprimer le groupe (cascade automatique)
  await prisma.groupe.delete({ 
    where: { id: groupeId } 
  });

  return { 
    action: 'deleted',
    message: 'Groupe supprimé avec succès',
    groupeId: groupe.id,
    groupeNom: groupe.nom,
  };
};

// ══════════════════════════════════════════════════════════════════════════════
// ASSIGN PELERIN ⭐ CORRIGÉ
// ══════════════════════════════════════════════════════════════════════════════
export const assignerPelerin = async (
  agenceId: string,
  groupeId: string,
  pelerinId: string
) => {
  // Vérifier que le groupe existe et appartient à l'agence
  const groupe = await prisma.groupe.findFirst({ 
    where: { id: groupeId, agenceId } 
  });
  
  if (!groupe) {
    throw new Error('Groupe introuvable');
  }

  if (['TERMINE', 'ANNULE'].includes(groupe.status)) {
    throw new Error("Impossible d'affecter des pelerins ")
  }

  const groupeStart = groupe.dateDepart ?? null
  const groupeEnd = groupe.dateRetour ?? groupe.dateDepart ?? null
  const groupeMax = Math.min((groupe.nbMax ?? 40), 40)

  // Vérifier que le pèlerin existe et appartient à l'agence
  const pelerin = await prisma.pelerin.findFirst({
    where: { id: pelerinId, agenceId },
    include: { 
      utilisateur: { select: { actif: true } } 
    }
  });
  
  if (!pelerin) {
    throw new Error("Pèlerin introuvable ou n'appartient pas à votre agence");
  }
  
  if (!pelerin.utilisateur.actif) {
    throw new Error("Ce pèlerin n'a pas encore activé son compte");
  }

  // ⭐ Vérifier si le pèlerin est déjà dans ce groupe (relation actif)
  const existingMembre = await prisma.groupePelerin.findFirst({
    where: {
      groupeId,
      pelerinId,
      actif: true,
    },
  });

  if (existingMembre) {
    throw new Error('Ce pèlerin est déjà membre actif de ce groupe');
  }

  // ⭐ Interdire chevauchement de période (groupes PLANIFIE/EN_COURS)
  // Règle: un pèlerin peut appartenir à plusieurs groupes, mais pas à deux groupes qui se chevauchent en dates.
  if (groupeStart && groupeEnd && ['PLANIFIE', 'EN_COURS'].includes(groupe.status)) {
    const activeMemberships = await prisma.groupePelerin.findMany({
      where: {
        pelerinId,
        actif: true,
        groupeId: { not: groupeId },
        groupe: {
          status: { in: ['PLANIFIE', 'EN_COURS'] },
        },
      },
      include: {
        groupe: {
          select: { id: true, nom: true, dateDepart: true, dateRetour: true, status: true },
        },
      },
    })

    const overlapping = activeMemberships.find((m) => {
      const other = m.groupe
      const otherStart = other.dateDepart ?? null
      const otherEnd = other.dateRetour ?? other.dateDepart ?? null
      if (!otherStart || !otherEnd) return false

      return otherStart <= groupeEnd && otherEnd >= groupeStart
    })

    if (overlapping) {
      throw new Error(
        `Impossible d'ajouter ce pèlerin : chevauchement de période avec le groupe "${overlapping.groupe.nom}".`
      )
    }
  }

  // ⭐ Capacité max (nbMax) : ne pas dépasser le nombre de pèlerins autorisé
  if (groupeMax > 0) {
    const activeCount = await prisma.groupePelerin.count({
      where: {
        groupeId,
        actif: true,
      },
    })

    if (activeCount >= groupeMax) {
      throw new Error(`Ce groupe a atteint sa capacite maximale (${groupeMax} pelerin(s)).`)
    }
  }

  // ⭐ Créer la nouvelle relation GroupePelerin
  await prisma.groupePelerin.create({
    data: {
      groupeId,
      pelerinId,
      actif: true,
    },
  });

  return { 
    message: 'Pèlerin ajouté au groupe avec succès',
    groupeId,
    pelerinId,
  };
};

// ══════════════════════════════════════════════════════════════════════════════
// REMOVE PELERIN ⭐ CORRIGÉ
// ══════════════════════════════════════════════════════════════════════════════
export const retirerPelerin = async (
  agenceId: string,
  groupeId: string,
  pelerinId: string
) => {
  // Vérifier que le pèlerin appartient à l'agence
  const pelerin = await prisma.pelerin.findFirst({ 
    where: { id: pelerinId, agenceId } 
  });
  
  if (!pelerin) {
    throw new Error('Pèlerin introuvable');
  }

  // ⭐ Vérifier que le pèlerin est membre actif de ce groupe
  const membre = await prisma.groupePelerin.findFirst({
    where: {
      groupeId,
      pelerinId,
      actif: true,
    },
  });

  if (!membre) {
    throw new Error("Ce pèlerin n'est pas membre actif de ce groupe");
  }

  // ⭐ Désactiver la relation (soft delete)
  await prisma.groupePelerin.update({
    where: { id: membre.id },
    data: {
      actif: false,
      dateFin: new Date(),
    },
  });

  return { 
    message: 'Pèlerin retiré du groupe avec succès',
    groupeId,
    pelerinId,
  };
};
