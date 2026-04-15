// backend/src/modules/guide/parcours/parcours.service.ts

import prisma from '../../../../config/prisma';
import { EtapeVoyage, TypeVoyage } from '../../../../../generated/prisma/enums';
import {
  getEtapesByType,
  getEtapesOrdre,
  getEtapeDetails,
  isEtapeValidForType,
  canValidateEtape,
} from '../../../shared/parcours/parcours.config';

// ════════════════════════════════════════════════════════
// INTERFACES
// ════════════════════════════════════════════════════════

interface EtapeStatut {
  code: EtapeVoyage;
  ordre: number;
  nom: string;
  nomArabe: string;
  description: string;
  detailsLong: string;
  dureeEstimee: number;
  lieu: string;
  statut: 'VALIDEE' | 'EN_COURS' | 'PROCHAINE' | 'A_VENIR';
  valideeAt: Date | null;
  valideePar: string | null;
  note: string | null;
}

interface ParcoursResponse {
  groupeId: string;
  groupeNom: string;
  typeVoyage: TypeVoyage;
  nbPelerins: number;
  etapeActuelle: EtapeVoyage | null;
  progression: {
    etapesValidees: number;
    total: number;
    pourcentage: number;
  };
  etapes: EtapeStatut[];
}

// ════════════════════════════════════════════════════════
// RÉCUPÉRER LE PARCOURS D'UN GROUPE (GUIDE)
// ════════════════════════════════════════════════════════

export const getParcoursGroupe = async (
  groupeId: string,
  guideId: string
): Promise<ParcoursResponse> => {
  // 1. Vérifier que le guide est bien guide du groupe
  const guideGroupe = await prisma.groupeGuide.findFirst({
    where: {
      groupeId,
      guideId,
      actif: true,
    },
  });

  if (!guideGroupe) {
    throw new Error('Vous n\'êtes pas guide de ce groupe');
  }

  // 2. Récupérer le groupe avec ses étapes validées
  const groupe = await prisma.groupe.findUnique({
    where: { id: groupeId },
    include: {
      membres: {
        where: { actif: true },
        select: { id: true },
      },
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
  });

  if (!groupe) {
    throw new Error('Groupe introuvable');
  }

  // 3. Récupérer les étapes selon le type de voyage
  const etapesConfig = getEtapesByType(groupe.typeVoyage);
  const etapesOrdre = getEtapesOrdre(groupe.typeVoyage);

  // 4. Trouver l'index de l'étape actuelle
  const etapeActuelleIndex = groupe.etapeActuelle
    ? etapesOrdre.indexOf(groupe.etapeActuelle)
    : -1;

  // 5. Construire le parcours avec statut de chaque étape
  const parcours: EtapeStatut[] = etapesConfig.map((etapeConfig, index) => {
    const etapeValidee = groupe.etapesValidees.find(
      (ev) => ev.etape === etapeConfig.code
    );

    let statut: 'VALIDEE' | 'EN_COURS' | 'PROCHAINE' | 'A_VENIR';

    if (etapeValidee) {
      statut = 'VALIDEE';
    } else if (index === etapeActuelleIndex) {
      statut = 'EN_COURS';
    } else if (index === etapeActuelleIndex + 1) {
      statut = 'PROCHAINE';
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
    nbPelerins: groupe.membres.length,
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
// VALIDER UNE ÉTAPE (GUIDE)
// ════════════════════════════════════════════════════════

export const validerEtapeGroupe = async (
  groupeId: string,
  guideId: string,
  etape: EtapeVoyage,
  note?: string
) => {
  // 1. Vérifier que le guide est bien guide du groupe
  const guideGroupe = await prisma.groupeGuide.findFirst({
    where: {
      groupeId,
      guideId,
      actif: true,
    },
  });

  if (!guideGroupe) {
    throw new Error('Vous n\'êtes pas guide de ce groupe');
  }

  // 2. Récupérer le groupe
  const groupe = await prisma.groupe.findUnique({
    where: { id: groupeId },
    select: {
      id: true,
      nom: true,
      typeVoyage: true,
      etapeActuelle: true,
    },
  });

  if (!groupe) {
    throw new Error('Groupe introuvable');
  }

  // 3. Vérifier que l'étape appartient au type de voyage
  if (!isEtapeValidForType(etape, groupe.typeVoyage)) {
    throw new Error(
      `L'étape ${etape} n'est pas valide pour un voyage de type ${groupe.typeVoyage}`
    );
  }

  // 4. Vérifier que l'étape n'est pas déjà validée
  const existingValidation = await prisma.etapeValideeGroupe.findUnique({
    where: {
      groupeId_etape: {
        groupeId,
        etape,
      },
    },
  });

  if (existingValidation) {
    throw new Error('Cette étape a déjà été validée');
  }

  // 5. Vérifier que c'est la bonne étape à valider
  if (!canValidateEtape(etape, groupe.etapeActuelle, groupe.typeVoyage)) {
    const etapesOrdre = getEtapesOrdre(groupe.typeVoyage);
    const nextEtapeIndex = groupe.etapeActuelle
      ? etapesOrdre.indexOf(groupe.etapeActuelle) + 1
      : 0;
    const nextEtape = etapesOrdre[nextEtapeIndex];
    const nextEtapeDetails = getEtapeDetails(nextEtape, groupe.typeVoyage);

    throw new Error(
      `Vous devez valider l'étape : ${nextEtapeDetails?.nom || nextEtape}`
    );
  }

  // 6. Transaction : Valider l'étape
  const result = await prisma.$transaction(async (tx) => {
    // a. Mettre à jour l'étape actuelle du groupe
    await tx.groupe.update({
      where: { id: groupeId },
      data: {
        etapeActuelle: etape,
      },
    });

    // b. Créer l'historique de validation
    const validation = await tx.etapeValideeGroupe.create({
      data: {
        groupeId,
        etape,
        valideParGuideId: guideId,
        note,
      },
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
    });

    return validation;
  });

  return {
    id: result.id,
    etape: result.etape,
    valideeAt: result.valideeAt,
    valideePar: `${result.valideParGuide?.utilisateur.prenom} ${result.valideParGuide?.utilisateur.nom}`,
    note: result.note,
  };
};

// ════════════════════════════════════════════════════════
// RÉCUPÉRER L'HISTORIQUE DES VALIDATIONS
// ════════════════════════════════════════════════════════

export const getHistoriqueEtapes = async (
  groupeId: string,
  guideId: string
) => {
  // Vérifier que le guide est bien guide du groupe
  const guideGroupe = await prisma.groupeGuide.findFirst({
    where: {
      groupeId,
      guideId,
      actif: true,
    },
  });

  if (!guideGroupe) {
    throw new Error('Vous n\'êtes pas guide de ce groupe');
  }

  // Récupérer le type de voyage
  const groupe = await prisma.groupe.findUnique({
    where: { id: groupeId },
    select: { typeVoyage: true },
  });

  if (!groupe) {
    throw new Error('Groupe introuvable');
  }

  // Récupérer l'historique
  const historique = await prisma.etapeValideeGroupe.findMany({
    where: { groupeId },
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
  });

  return historique.map((h) => {
    const etapeDetails = getEtapeDetails(h.etape, groupe.typeVoyage);

    return {
      etape: h.etape,
      etapeNom: etapeDetails?.nom || h.etape,
      etapeNomArabe: etapeDetails?.nomArabe || '',
      ordre: etapeDetails?.ordre || 0,
      valideeAt: h.valideeAt,
      valideePar: h.valideParGuide
        ? `${h.valideParGuide.utilisateur.prenom} ${h.valideParGuide.utilisateur.nom}`
        : 'Inconnu',
      note: h.note,
    };
  });
};
