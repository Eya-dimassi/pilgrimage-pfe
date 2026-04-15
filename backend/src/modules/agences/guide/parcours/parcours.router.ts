import { Router, Response } from 'express';

import { authenticate, requireRole, AuthRequest } from '../../../auth/auth.middleware';
import prisma from '../../../../config/prisma';
import { EtapeVoyage, TypeVoyage } from '../../../../../generated/prisma/enums';
import {
  getEtapeDetails,
  getEtapesOrdre,
} from '../../../shared/parcours/parcours.config';
import * as parcoursService from './parcours.service';

const router = Router();

// Toutes les routes nécessitent authentification + rôle GUIDE
router.use(authenticate, requireRole('GUIDE'));

const resolveGuideId = async (utilisateurId: string): Promise<string> => {
  const guide = await prisma.guide.findUnique({
    where: { utilisateurId },
    select: { id: true },
  });

  if (!guide) {
    throw new Error('Profil guide introuvable');
  }

  return guide.id;
};

// GET /guide/groupes
// Récupérer tous les groupes affectés au guide (actifs)
router.get('/groupes', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await resolveGuideId(req.user!.id);

    const groupesDb = await prisma.groupe.findMany({
      where: {
        guides: {
          some: {
            guideId,
            actif: true,
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
      select: {
        id: true,
        nom: true,
        typeVoyage: true,
        etapeActuelle: true,
        status: true,
        dateDepart: true,
        etapesValidees: {
          select: { id: true },
        },
        membres: {
          where: { actif: true },
          select: { id: true },
        },
      },
    });

    const groupes = groupesDb.map((g) => {
      const etapesOrdre = getEtapesOrdre(g.typeVoyage as TypeVoyage);
      const indexActuel = g.etapeActuelle
        ? etapesOrdre.indexOf(g.etapeActuelle as EtapeVoyage)
        : -1;
      const nextIndex = indexActuel + 1;
      const nextEtape =
        nextIndex >= 0 && nextIndex < etapesOrdre.length
          ? (etapesOrdre[nextIndex] as EtapeVoyage)
          : null;
      const nextDetails = nextEtape
        ? getEtapeDetails(nextEtape, g.typeVoyage as TypeVoyage)
        : undefined;

      const currentDetails = g.etapeActuelle
        ? getEtapeDetails(g.etapeActuelle as EtapeVoyage, g.typeVoyage as TypeVoyage)
        : undefined;

      const total = etapesOrdre.length;
      const done = g.etapesValidees.length;
      const percent = total > 0 ? Math.round((done / total) * 100) : 0;

      return {
        id: g.id,
        nom: g.nom,
        typeVoyage: g.typeVoyage,
        etapeActuelle: g.etapeActuelle,
        status: g.status,
        dateDepart: g.dateDepart,
        nbPelerins: g.membres.length,
        progression: {
          etapesValidees: done,
          total,
          pourcentage: percent,
        },
        etapeActuelleDetails: currentDetails
          ? {
              code: currentDetails.code,
              ordre: currentDetails.ordre,
              nom: currentDetails.nom,
              nomArabe: currentDetails.nomArabe,
            }
          : null,
        prochaineEtape: nextDetails
          ? {
              code: nextDetails.code,
              ordre: nextDetails.ordre,
              nom: nextDetails.nom,
              nomArabe: nextDetails.nomArabe,
            }
          : null,
      };
    });

    return res.status(200).json(groupes);
  } catch (error: any) {
    console.error('Erreur getGroupesGuide:', error);
    return res.status(400).json({
      message: error.message || 'Erreur lors de la récupération des groupes',
    });
  }
});

// GET /guide/groupes/:groupeId/parcours
// Récupérer le parcours d'un groupe
router.get('/groupes/:groupeId/parcours', async (req: AuthRequest, res: Response) => {
  try {
    const groupeIdParam = req.params.groupeId;
    if (Array.isArray(groupeIdParam)) {
      return res.status(400).json({ message: 'groupeId invalide' });
    }
    const groupeId = groupeIdParam;
    const guideId = await resolveGuideId(req.user!.id);

    const parcours = await parcoursService.getParcoursGroupe(groupeId, guideId);
    return res.status(200).json(parcours);
  } catch (error: any) {
    console.error('Erreur getParcoursGroupe:', error);
    return res.status(400).json({
      message: error.message || 'Erreur lors de la récupération du parcours',
    });
  }
});

// GET /guide/groupes/:groupeId/pelerins
// Recuperer la liste des pelerins d'un groupe (si le guide y est affecte)
router.get('/groupes/:groupeId/pelerins', async (req: AuthRequest, res: Response) => {
  try {
    const groupeIdParam = req.params.groupeId;
    if (Array.isArray(groupeIdParam)) {
      return res.status(400).json({ message: 'groupeId invalide' });
    }
    const groupeId = groupeIdParam;
    const guideId = await resolveGuideId(req.user!.id);

    const groupe = await prisma.groupe.findFirst({
      where: {
        id: groupeId,
        guides: {
          some: {
            guideId,
            actif: true,
          },
        },
      },
      select: {
        membres: {
          where: { actif: true },
          select: {
            pelerin: {
              select: {
                id: true,
                utilisateur: {
                  select: {
                    nom: true,
                    prenom: true,
                    telephone: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!groupe) {
      return res.status(404).json({ message: 'Groupe introuvable' });
    }

    const pelerins = groupe.membres
      .map((m) => ({
        id: m.pelerin.id,
        nom: m.pelerin.utilisateur.nom,
        prenom: m.pelerin.utilisateur.prenom,
        telephone: m.pelerin.utilisateur.telephone,
      }))
      .sort((a, b) =>
        `${a.prenom} ${a.nom}`.localeCompare(`${b.prenom} ${b.nom}`, 'fr', {
          sensitivity: 'base',
        })
      );

    return res.status(200).json(pelerins);
  } catch (error: any) {
    console.error('Erreur getPelerinsGroupeGuide:', error);
    return res.status(400).json({
      message: error.message || 'Erreur lors de la recuperation des pelerins',
    });
  }
});

// PUT /guide/groupes/:groupeId/parcours/valider
// Valider une étape du parcours
router.put('/groupes/:groupeId/parcours/valider', async (req: AuthRequest, res: Response) => {
  try {
    const groupeIdParam = req.params.groupeId;
    if (Array.isArray(groupeIdParam)) {
      return res.status(400).json({ message: 'groupeId invalide' });
    }
    const groupeId = groupeIdParam;
    const guideId = await resolveGuideId(req.user!.id);
    const { etape, note } = req.body;

    if (!etape || typeof etape !== 'string') {
      return res.status(400).json({ message: "L'étape est requise" });
    }

    if (note !== undefined && note !== null && typeof note !== 'string') {
      return res
        .status(400)
        .json({ message: 'La note doit être une chaîne de caractères' });
    }

    const etapesValides = Object.values(EtapeVoyage);
    if (!etapesValides.includes(etape as EtapeVoyage)) {
      return res.status(400).json({ message: 'Étape invalide' });
    }

    const validation = await parcoursService.validerEtapeGroupe(
      groupeId,
      guideId,
      etape as EtapeVoyage,
      note
    );

    return res.status(200).json({
      message: 'Étape validée avec succès',
      validation,
    });
  } catch (error: any) {
    console.error('Erreur validerEtape:', error);
    return res.status(400).json({
      message: error.message || "Erreur lors de la validation de l'étape",
    });
  }
});

// GET /guide/groupes/:groupeId/parcours/historique
// Récupérer l'historique des validations
router.get('/groupes/:groupeId/parcours/historique', async (req: AuthRequest, res: Response) => {
  try {
    const groupeIdParam = req.params.groupeId;
    if (Array.isArray(groupeIdParam)) {
      return res.status(400).json({ message: 'groupeId invalide' });
    }
    const groupeId = groupeIdParam;
    const guideId = await resolveGuideId(req.user!.id);

    const historique = await parcoursService.getHistoriqueEtapes(groupeId, guideId);
    return res.status(200).json(historique);
  } catch (error: any) {
    console.error('Erreur getHistorique:', error);
    return res.status(400).json({
      message: error.message || "Erreur lors de la récupération de l'historique",
    });
  }
});

export default router;
