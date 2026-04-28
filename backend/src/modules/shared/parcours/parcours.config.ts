// backend/src/modules/shared/parcours/parcours.config.ts

import { EtapeVoyage, TypeVoyage } from '../../../../generated/prisma/enums';

// ════════════════════════════════════════════════════════
// INTERFACES
// ════════════════════════════════════════════════════════

export interface EtapeConfig {
  ordre: number;
  code: EtapeVoyage;
  nom: string;
  nomArabe: string;
  description: string;
  detailsLong: string;
  dureeEstimee: number; // en heures
  lieu: string;
}

// ════════════════════════════════════════════════════════
// CONFIGURATION DES ÉTAPES PAR TYPE DE VOYAGE
// ════════════════════════════════════════════════════════

export const ETAPES_CONFIG: Record<TypeVoyage, EtapeConfig[]> = {
  // ── HAJJ : 10 étapes ──
  HAJJ: [
    {
      ordre: 1,
      code: 'IHRAM',
      nom: 'Ihram',
      nomArabe: 'الإحرام',
      description: 'État de sacralisation - Entrée en état de pèlerinage',
      detailsLong: `L'Ihram est l'état de sacralisation dans lequel le pèlerin entre avant de commencer les rites du Hajj. Le pèlerin porte des vêtements spécifiques (deux pièces de tissu blanc pour les hommes) et prononce la Talbiyah.`,
      dureeEstimee: 2,
      lieu: 'Miqat ou hôtel',
    },
    {
      ordre: 2,
      code: 'TAWAF_AL_QUDUM',
      nom: 'Tawaf Al-Qudum',
      nomArabe: 'طواف القدوم',
      description: 'Circumambulation d\'arrivée autour de la Kaaba',
      detailsLong: `Le Tawaf Al-Qudum (tawaf d'arrivée) consiste à tourner sept fois autour de la Kaaba dans le sens antihoraire. C'est le premier rite effectué à la Mosquée Sacrée.`,
      dureeEstimee: 3,
      lieu: 'Masjid al-Haram (La Mecque)',
    },
    {
      ordre: 3,
      code: 'SAI',
      nom: 'Sa\'i',
      nomArabe: 'السعي',
      description: 'Course entre Safa et Marwa',
      detailsLong: `Le Sa'i consiste à parcourir sept fois la distance entre les collines de Safa et Marwa, en commémoration de Hajar (épouse d'Ibrahim) qui cherchait de l'eau pour son fils Ismaïl.`,
      dureeEstimee: 2,
      lieu: 'Entre Safa et Marwa (La Mecque)',
    },
    {
      ordre: 4,
      code: 'ARAFAT',
      nom: 'Jour d\'Arafat',
      nomArabe: 'يوم عرفة',
      description: 'Station debout à Arafat - Pilier central du Hajj',
      detailsLong: `Le 9 Dhul Hijjah, les pèlerins se rendent au Mont Arafat pour la station debout (Wuquf). C'est le pilier central du Hajj. Le Prophète ﷺ a dit : "Le Hajj, c'est Arafat".`,
      dureeEstimee: 8,
      lieu: 'Plaine d\'Arafat',
    },
    {
      ordre: 5,
      code: 'MUZDALIFAH',
      nom: 'Muzdalifah',
      nomArabe: 'مزدلفة',
      description: 'Nuit à Muzdalifah et collecte de cailloux',
      detailsLong: `Après le coucher du soleil à Arafat, les pèlerins se rendent à Muzdalifah où ils passent la nuit à la belle étoile et collectent des cailloux pour la lapidation.`,
      dureeEstimee: 10,
      lieu: 'Muzdalifah',
    },
    {
      ordre: 6,
      code: 'MINA',
      nom: 'Jours de Mina',
      nomArabe: 'أيام منى',
      description: 'Séjour à Mina pendant les jours du Tachriq',
      detailsLong: `Les pèlerins passent les 10, 11, 12 et éventuellement 13 Dhul Hijjah à Mina pour accomplir la lapidation des stèles et d'autres rites.`,
      dureeEstimee: 72, // 3 jours
      lieu: 'Mina',
    },
    {
      ordre: 7,
      code: 'RAMI_JAMARAT',
      nom: 'Rami (Lapidation)',
      nomArabe: 'رمي الجمرات',
      description: 'Lapidation des trois stèles',
      detailsLong: `Les pèlerins lancent des cailloux sur trois stèles (Jamarat) symbolisant le rejet de Satan. Ce rite se fait pendant les jours de Mina.`,
      dureeEstimee: 2,
      lieu: 'Jamarat (Mina)',
    },
    {
      ordre: 8,
      code: 'TAWAF_AL_IFADA',
      nom: 'Tawaf Al-Ifada',
      nomArabe: 'طواف الإفاضة',
      description: 'Circumambulation de l\'Ifada (pilier du Hajj)',
      detailsLong: `Le Tawaf Al-Ifada est un pilier du Hajj. Il est effectué après la lapidation de la grande stèle le jour de l'Aïd et marque la fin de l'état de sacralisation partielle.`,
      dureeEstimee: 3,
      lieu: 'Masjid al-Haram (La Mecque)',
    },
    {
      ordre: 9,
      code: 'TAWAF_AL_WADA',
      nom: 'Tawaf Al-Wada',
      nomArabe: 'طواف الوداع',
      description: 'Circumambulation d\'adieu',
      detailsLong: `Le Tawaf Al-Wada (tawaf d'adieu) est le dernier rite du Hajj. Il est effectué juste avant de quitter La Mecque pour rentrer chez soi.`,
      dureeEstimee: 2,
      lieu: 'Masjid al-Haram (La Mecque)',
    },
    {
      ordre: 10,
      code: 'TAHALLUL',
      nom: 'Tahallul',
      nomArabe: 'التحلل',
      description: 'Désacralisation complète - Fin du Hajj',
      detailsLong: `Le Tahallul marque la sortie complète de l'état de sacralisation. Le pèlerin peut à nouveau porter ses vêtements normaux et reprendre ses activités habituelles. Le Hajj est terminé.`,
      dureeEstimee: 1,
      lieu: 'Mina ou La Mecque',
    },
  ],

  // ── UMRAH : 4 étapes ──
  UMRAH: [
    {
      ordre: 1,
      code: 'IHRAM',
      nom: 'Ihram',
      nomArabe: 'الإحرام',
      description: 'État de sacralisation - Entrée en Umrah',
      detailsLong: `L'Ihram pour l'Umrah se fait au Miqat ou à l'hôtel si le pèlerin est déjà à La Mecque. Le pèlerin prononce la Niyyah (intention) et la Talbiyah.`,
      dureeEstimee: 1,
      lieu: 'Miqat ou hôtel',
    },
    {
      ordre: 2,
      code: 'TAWAF_UMRAH',
      nom: 'Tawaf',
      nomArabe: 'طواف العمرة',
      description: 'Circumambulation autour de la Kaaba (7 tours)',
      detailsLong: `Le Tawaf de l'Umrah consiste à effectuer 7 tours complets autour de la Kaaba dans le sens antihoraire, en commençant depuis la Pierre Noire.`,
      dureeEstimee: 2,
      lieu: 'Masjid al-Haram (La Mecque)',
    },
    {
      ordre: 3,
      code: 'SAI',
      nom: 'Sa\'i',
      nomArabe: 'السعي',
      description: 'Course entre Safa et Marwa (7 allers-retours)',
      detailsLong: `Le Sa'i consiste à parcourir 7 fois la distance entre Safa et Marwa, soit 7 allers-retours, en commémoration de Hajar.`,
      dureeEstimee: 1,
      lieu: 'Entre Safa et Marwa (La Mecque)',
    },
    {
      ordre: 4,
      code: 'TAHALLUL',
      nom: 'Tahallul',
      nomArabe: 'التحلل',
      description: 'Désacralisation - Rasage ou coupe des cheveux',
      detailsLong: `Le Tahallul marque la fin de l'Umrah. Le pèlerin se rase ou coupe une partie de ses cheveux pour sortir de l'état de sacralisation.`,
      dureeEstimee: 1,
      lieu: 'La Mecque',
    },
  ],
};

// ════════════════════════════════════════════════════════
// FONCTIONS UTILITAIRES
// ════════════════════════════════════════════════════════

/**
 * Récupérer les étapes selon le type de voyage
 */
export const getEtapesByType = (typeVoyage: TypeVoyage): EtapeConfig[] => {
  return ETAPES_CONFIG[typeVoyage];
};

/**
 * Récupérer les codes d'étapes dans l'ordre
 */
export const getEtapesOrdre = (typeVoyage: TypeVoyage): EtapeVoyage[] => {
  return ETAPES_CONFIG[typeVoyage].map((e) => e.code);
};

/**
 * Récupérer les détails d'une étape
 */
export const getEtapeDetails = (
  etapeCode: EtapeVoyage,
  typeVoyage: TypeVoyage
): EtapeConfig | undefined => {
  const etapes = ETAPES_CONFIG[typeVoyage];
  return etapes.find((e) => e.code === etapeCode);
};

/**
 * Vérifier si une étape est valide pour un type de voyage
 */
export const isEtapeValidForType = (
  etapeCode: EtapeVoyage,
  typeVoyage: TypeVoyage
): boolean => {
  const etapesOrdre = getEtapesOrdre(typeVoyage);
  return etapesOrdre.includes(etapeCode);
};

/**
 * Récupérer l'index d'une étape
 */
export const getEtapeIndex = (
  etapeCode: EtapeVoyage,
  typeVoyage: TypeVoyage
): number => {
  const etapesOrdre = getEtapesOrdre(typeVoyage);
  return etapesOrdre.indexOf(etapeCode);
};

/**
 * Vérifier si une étape peut être validée
 */
export const canValidateEtape = (
  etapeCode: EtapeVoyage,
  etapeActuelle: EtapeVoyage | null,
  typeVoyage: TypeVoyage
): boolean => {
  const etapesOrdre = getEtapesOrdre(typeVoyage);
  
  // Première étape : doit être la première de la liste
  if (!etapeActuelle) {
    return etapeCode === etapesOrdre[0];
  }
  
  const indexActuel = etapesOrdre.indexOf(etapeActuelle);
  const indexNouveau = etapesOrdre.indexOf(etapeCode);
  
  // On peut valider l'étape suivante uniquement
  return indexNouveau === indexActuel + 1;
};