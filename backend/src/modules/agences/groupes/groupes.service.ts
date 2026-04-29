// backend/src/modules/agence/groupes/groupes.service.ts

import { addDays, startOfDay } from 'date-fns';
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// CREATE
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
    hajjStartDate?: string | Date;
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
      throw new Error("Guide introuvable ou n'appartient pas Ã  votre agence");
    }

    const inactiveGuide = guides.find((g) => !g.utilisateur.actif);
    if (inactiveGuide) {
      throw new Error("Ce guide n'a pas encore activÃ© son compte");
    }
  }

  const parsedDateDepart = data.dateDepart ? new Date(data.dateDepart) : undefined;
  const parsedDateRetour = data.dateRetour ? new Date(data.dateRetour) : undefined;
  const parsedHajjStartDate = data.hajjStartDate ? new Date(data.hajjStartDate) : undefined;

  if (parsedDateDepart && Number.isNaN(parsedDateDepart.getTime())) {
    throw new Error('dateDepart invalide');
  }

  if (parsedDateRetour && Number.isNaN(parsedDateRetour.getTime())) {
    throw new Error('dateRetour invalide');
  }

  if (parsedHajjStartDate && Number.isNaN(parsedHajjStartDate.getTime())) {
    throw new Error('hajjStartDate invalide');
  }

  if (parsedDateDepart && parsedDateRetour && parsedDateRetour < parsedDateDepart) {
    throw new Error('dateRetour doit etre >= dateDepart');
  }

  if (data.typeVoyage === 'HAJJ' && parsedHajjStartDate) {
    const anchorDate = startOfDay(parsedHajjStartDate);
    const fixedEndDate = addDays(anchorDate, 5);

    if (parsedDateDepart && anchorDate < startOfDay(parsedDateDepart)) {
      throw new Error('La date du 8 Dhul Hijja doit Ãªtre comprise dans la durÃ©e du voyage');
    }

    if (parsedDateRetour && fixedEndDate > startOfDay(parsedDateRetour)) {
      throw new Error('Le voyage Hajj doit couvrir au moins du 8 au 13 Dhul Hijja');
    }
  }

  // EmpÃªcher les doublons de nom (mÃªme agence + mÃªme annÃ©e)
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

  // CrÃ©er le groupe
  const groupe = await prisma.groupe.create({
    data: {
      nom: data.nom,
      annee: data.annee,
      typeVoyage: data.typeVoyage,
      description: data.description,
      status: data.status,
      dateDepart: parsedDateDepart,
      dateRetour: parsedDateRetour,
      hajjStartDate: data.typeVoyage === 'HAJJ' ? parsedHajjStartDate ?? null : null,
      agenceId,
    },
    include: {
      _count: { 
        select: { 
          membres: { where: { actif: true } }  // â­ Compter seulement les actifs
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

  // RÃ©cupÃ©rer le groupe complet avec le guide
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GET ALL
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
export const getGroupes = async (agenceId: string) => {
  const list = await prisma.groupe.findMany({
    where: { agenceId },
    include: {
      guides: {
        where: { actif: true },  // â­ Seulement le guide actif
        include: {
          guide: {
            include: {
              utilisateur: { select: { nom: true, prenom: true, email: true } },
            },
          },
        },
      },
      membres: {
        where: { actif: true },  // â­ Seulement les membres actifs
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GET ONE
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// UPDATE
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
    hajjStartDate?: string | Date | null;
  }
) => {
  // VÃ©rifier que le groupe existe et appartient Ã  l'agence
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
      throw new Error("Guide introuvable ou n'appartient pas Ã  votre agence");
    }

    const inactiveGuide = guides.find((g) => !g.utilisateur.actif);
    if (inactiveGuide) {
      throw new Error("Ce guide n'a pas encore activÃ© son compte");
    }
  }

  const parsedDateDepart = data.dateDepart === null ? null : (data.dateDepart ? new Date(data.dateDepart) : undefined);
  const parsedDateRetour = data.dateRetour === null ? null : (data.dateRetour ? new Date(data.dateRetour) : undefined);
  const parsedHajjStartDate = data.hajjStartDate === null ? null : (data.hajjStartDate ? new Date(data.hajjStartDate) : undefined);

  if (parsedDateDepart instanceof Date && Number.isNaN(parsedDateDepart.getTime())) {
    throw new Error('dateDepart invalide');
  }

  if (parsedDateRetour instanceof Date && Number.isNaN(parsedDateRetour.getTime())) {
    throw new Error('dateRetour invalide');
  }

  if (parsedHajjStartDate instanceof Date && Number.isNaN(parsedHajjStartDate.getTime())) {
    throw new Error('hajjStartDate invalide');
  }

  const finalDateDepart = parsedDateDepart === undefined ? groupe.dateDepart : parsedDateDepart;
  const finalDateRetour = parsedDateRetour === undefined ? groupe.dateRetour : parsedDateRetour;
  const finalTypeVoyage = data.typeVoyage ?? groupe.typeVoyage;
  const finalHajjStartDate = parsedHajjStartDate === undefined ? groupe.hajjStartDate : parsedHajjStartDate;

  if (finalDateDepart && finalDateRetour && finalDateRetour < finalDateDepart) {
    throw new Error('dateRetour doit etre >= dateDepart');
  }

  if (finalTypeVoyage === 'HAJJ' && finalHajjStartDate) {
    const anchorDate = startOfDay(finalHajjStartDate);
    const fixedEndDate = addDays(anchorDate, 5);

    if (finalDateDepart && anchorDate < startOfDay(finalDateDepart)) {
      throw new Error('La date du 8 Dhul Hijja doit Ãªtre comprise dans la durÃ©e du voyage');
    }

    if (finalDateRetour && fixedEndDate > startOfDay(finalDateRetour)) {
      throw new Error('Le voyage Hajj doit couvrir au moins du 8 au 13 Dhul Hijja');
    }
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

  const hajjStartDateUpdate =
    finalTypeVoyage !== 'HAJJ'
      ? { hajjStartDate: null }
      : parsedHajjStartDate !== undefined
        ? { hajjStartDate: parsedHajjStartDate }
        : {};

  // Mettre Ã  jour le groupe
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
      ...hajjStartDateUpdate,
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DELETE â­ CORRIGÃ‰
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
export const deleteGroupe = async (agenceId: string, groupeId: string) => {
  // 1. VÃ©rifier que le groupe existe et appartient Ã  l'agence
  const groupe = await prisma.groupe.findFirst({ 
    where: { id: groupeId, agenceId },
    include: {
      _count: {
        select: {
          membres: { where: { actif: true } }  // â­ Compter membres actifs
        }
      }
    }
  });
  
  if (!groupe) {
    // VÃ©rifier si le groupe existe mais appartient Ã  une autre agence
    const groupeExists = await prisma.groupe.findUnique({
      where: { id: groupeId },
    });

    if (groupeExists) {
      throw new Error('AccÃ¨s refusÃ© : ce groupe appartient Ã  une autre agence');
    } else {
      throw new Error('Groupe introuvable');
    }
  }

  // 2. â­ VÃ‰RIFIER QUE LE GROUPE EST VIDE
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
      message: `Le groupe contient ${nombreMembresActifs} pÃ¨lerin(s) actif(s) : suppression interdite`,
      groupe: mapGroupeForAgenceDashboard(updated),
    }
  }

  // 3. Supprimer le groupe (cascade automatique)
  await prisma.groupe.delete({  
    where: { id: groupeId } 
  });

  return { 
    action: 'deleted',
    message: 'Groupe supprimÃ© avec succÃ¨s',
    groupeId: groupe.id,
    groupeNom: groupe.nom,
  };
};

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ASSIGN PELERIN â­ CORRIGÃ‰
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
export const assignerPelerin = async (
  agenceId: string,
  groupeId: string,
  pelerinId: string
) => {
  // VÃ©rifier que le groupe existe et appartient Ã  l'agence
  const groupe = await prisma.groupe.findFirst({ 
    where: { id: groupeId, agenceId } 
  });
  
  if (!groupe) {
    throw new Error('Groupe introuvable');
  }

  if (['TERMINE', 'ANNULE'].includes(groupe.status)) {
    throw new Error("Impossible d'affecter des pelerins à un groupe terminé ou annulé")
  }

  const groupeStart = groupe.dateDepart ?? null
  const groupeEnd = groupe.dateRetour ?? groupe.dateDepart ?? null
  const groupeMax = Math.min((groupe.nbMax ?? 40), 40)

  // VÃ©rifier que le pÃ¨lerin existe et appartient Ã  l'agence
  const pelerin = await prisma.pelerin.findFirst({
    where: { id: pelerinId, agenceId },
    include: { 
      utilisateur: { select: { actif: true } } 
    }
  });
  
  if (!pelerin) {
    throw new Error("PÃ¨lerin introuvable ou n'appartient pas Ã  votre agence");
  }
  
  if (!pelerin.utilisateur.actif) {
    throw new Error("Ce pÃ¨lerin n'a pas encore activÃ© son compte");
  }

  // Verify whether the pilgrim is already an active member of this group.
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

  // Prevent overlapping active trip periods (PLANIFIE / EN_COURS).
  // A pilgrim may belong to multiple groups over time, but not two overlapping trips.
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

  // Max capacity guard (nbMax): do not exceed the allowed pilgrim count.
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

  // â­ CrÃ©er la nouvelle relation GroupePelerin
  await prisma.groupePelerin.create({
    data: {
      groupeId,
      pelerinId,
      actif: true,
    },
  });

  return { 
    message: 'PÃ¨lerin ajoutÃ© au groupe avec succÃ¨s',
    groupeId,
    pelerinId,
  };
};

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// REMOVE PELERIN â­ CORRIGÃ‰
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
export const retirerPelerin = async (
  agenceId: string,
  groupeId: string,
  pelerinId: string
) => {
  // VÃ©rifier que le pÃ¨lerin appartient Ã  l'agence
  const pelerin = await prisma.pelerin.findFirst({ 
    where: { id: pelerinId, agenceId } 
  });
  
  if (!pelerin) {
    throw new Error('PÃ¨lerin introuvable');
  }

  // â­ VÃ©rifier que le pÃ¨lerin est membre actif de ce groupe
  const membre = await prisma.groupePelerin.findFirst({
    where: {
      groupeId,
      pelerinId,
      actif: true,
    },
  });

  if (!membre) {
    throw new Error("Ce pÃ¨lerin n'est pas membre actif de ce groupe");
  }

  // â­ DÃ©sactiver la relation (soft delete)
  await prisma.groupePelerin.update({
    where: { id: membre.id },
    data: {
      actif: false,
      dateFin: new Date(),
    },
  });

  return { 
    message: 'PÃ¨lerin retirÃ© du groupe avec succÃ¨s',
    groupeId,
    pelerinId,
  };
};



