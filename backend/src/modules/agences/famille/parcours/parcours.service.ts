// backend/src/modules/famille/parcours/parcours.service.ts

import prisma from '../../../../config/prisma';
import {
  getEtapesByType,
  getEtapesOrdre,
} from '../../../shared/parcours/parcours.config';

// ════════════════════════════════════════════════════════
// RÉCUPÉRER LE PARCOURS D'UN PÈLERIN SUIVI
// ════════════════════════════════════════════════════════

export const getParcoursPelerin = async (
  familleId: string,
  pelerinId: string
) => {
  // 1. Vérifier que la famille suit bien ce pèlerin
  const association = await prisma.famillePelerin.findFirst({
    where: {
      familleId,
      pelerinId,
      actif: true,
    },
  });

  if (!association) {
    throw new Error('Vous ne suivez pas ce pèlerin');
  }

  // 2. Récupérer le groupe actif du pèlerin
  const pelerin = await prisma.pelerin.findUnique({
    where: { id: pelerinId },
    include: {
      utilisateur: {
        select: {
          prenom: true,
          nom: true,
        },
      },
      groupes: {
        where: { actif: true },
        take: 1,
        orderBy: { dateDebut: 'desc' },
        include: {
          groupe: {
            include: {
              etapesValidees: {
                orderBy: { valideeAt: 'asc' },
                include: {
                  valideParGuide: {
                    include: {
                      utilisateur: {
                        select: {
                          prenom: true,
                          nom: true,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  });

  if (!pelerin) {
    throw new Error('Pèlerin introuvable');
  }

  const groupeMembership = pelerin.groupes[0];

  if (!groupeMembership) {
    throw new Error('Le pèlerin n\'est affecté à aucun groupe');
  }

  const groupe = groupeMembership.groupe;

  // 3. Récupérer les étapes selon le type de voyage
  const etapesConfig = getEtapesByType(groupe.typeVoyage);
  const etapesOrdre = getEtapesOrdre(groupe.typeVoyage);

  // 4. Trouver l'index de l'étape actuelle
  const etapeActuelleIndex = groupe.etapeActuelle
    ? etapesOrdre.indexOf(groupe.etapeActuelle)
    : -1;

  // 5. Construire le parcours
  const parcours = etapesConfig.map((etapeConfig, index) => {
    const etapeValidee = groupe.etapesValidees.find(
      (ev) => ev.etape === etapeConfig.code
    );

    let statut: 'VALIDEE' | 'EN_COURS' | 'A_VENIR';

    if (etapeValidee) {
      statut = 'VALIDEE';
    } else if (index === etapeActuelleIndex) {
      statut = 'EN_COURS';
    } else {
      statut = 'A_VENIR';
    }

    return {
      code: etapeConfig.code,
      ordre: etapeConfig.ordre,
      nom: etapeConfig.nom,
      nomArabe: etapeConfig.nomArabe,
      description: etapeConfig.description,
      dureeEstimee: etapeConfig.dureeEstimee,
      lieu: etapeConfig.lieu,
      statut,
      valideeAt: etapeValidee?.valideeAt || null,
      valideePar: etapeValidee?.valideParGuide
        ? `${etapeValidee.valideParGuide.utilisateur.prenom} ${etapeValidee.valideParGuide.utilisateur.nom}`
        : null,
      note: etapeValidee?.note || null,
    };
  });

  return {
    pelerinId: pelerin.id,
    pelerinNom: `${pelerin.utilisateur.prenom} ${pelerin.utilisateur.nom}`,
    groupeId: groupe.id,
    groupeNom: groupe.nom,
    typeVoyage: groupe.typeVoyage,
    etapeActuelle: groupe.etapeActuelle,
    progression: {
      etapesValidees: groupe.etapesValidees.length,
      total: etapesConfig.length,
      pourcentage: Math.round(
        (groupe.etapesValidees.length / etapesConfig.length) * 100
      ),
    },
    etapes: parcours,
  };
};

// ════════════════════════════════════════════════════════
// RÉCUPÉRER LA LISTE DES PÈLERINS SUIVIS
// ════════════════════════════════════════════════════════

export const getMesPelerins = async (familleId: string) => {
  const associations = await prisma.famillePelerin.findMany({
    where: {
      familleId,
      actif: true,
    },
    include: {
      pelerin: {
        include: {
          utilisateur: {
            select: {
              prenom: true,
              nom: true,
            },
          },
          groupes: {
            where: { actif: true },
            take: 1,
            include: {
              groupe: {
                select: {
                  id: true,
                  nom: true,
                  typeVoyage: true,
                  etapeActuelle: true,
                },
              },
            },
          },
        },
      },
    },
  });

  return associations.map((assoc) => {
    const pelerin = assoc.pelerin;
    const groupeMembership = pelerin.groupes[0];
    const groupe = groupeMembership?.groupe;

    return {
      pelerinId: pelerin.id,
      pelerinNom: `${pelerin.utilisateur.prenom} ${pelerin.utilisateur.nom}`,
      groupeId: groupe?.id || null,
      groupeNom: groupe?.nom || null,
      typeVoyage: groupe?.typeVoyage || null,
      etapeActuelle: groupe?.etapeActuelle || null,
    };
  });
};
