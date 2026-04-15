// backend/src/modules/pelerin/parcours/parcours.service.ts

import prisma from '../../../../config/prisma';
import { EtapeVoyage, TypeVoyage } from '../../../../../generated/prisma/enums';
import {
  getEtapesByType,
  getEtapesOrdre,
} from '../../../shared/parcours/parcours.config';

// ════════════════════════════════════════════════════════
// RÉCUPÉRER LE PARCOURS DU GROUPE DU PÈLERIN
// ════════════════════════════════════════════════════════

export const getMonParcours = async (pelerinId: string) => {
  // 1. Récupérer le groupe actif du pèlerin
  const pelerin = await prisma.pelerin.findUnique({
    where: { id: pelerinId },
    include: {
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
    throw new Error('Vous n\'êtes affecté à aucun groupe');
  }

  const groupe = groupeMembership.groupe;

  // 2. Récupérer les étapes selon le type de voyage
  const etapesConfig = getEtapesByType(groupe.typeVoyage);
  const etapesOrdre = getEtapesOrdre(groupe.typeVoyage);

  // 3. Trouver l'index de l'étape actuelle
  const etapeActuelleIndex = groupe.etapeActuelle
    ? etapesOrdre.indexOf(groupe.etapeActuelle)
    : -1;

  // 4. Construire le parcours
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
      detailsLong: etapeConfig.detailsLong,
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