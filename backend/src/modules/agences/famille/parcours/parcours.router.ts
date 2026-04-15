import { Router, Response } from 'express';

import { authenticate, requireRole, AuthRequest } from '../../../auth/auth.middleware';
import prisma from '../../../../config/prisma';
import * as parcoursService from './parcours.service';

const router = Router();

// Toutes les routes nécessitent authentification + rôle FAMILLE
router.use(authenticate, requireRole('FAMILLE'));

const resolveFamilleId = async (utilisateurId: string): Promise<string> => {
  const famille = await prisma.famille.findUnique({
    where: { utilisateurId },
    select: { id: true },
  });

  if (!famille) {
    throw new Error('Profil famille introuvable');
  }

  return famille.id;
};

// GET /famille/pelerins
// Récupérer la liste de mes pèlerins suivis
router.get('/pelerins', async (req: AuthRequest, res: Response) => {
  try {
    const familleId = await resolveFamilleId(req.user!.id);
    const pelerins = await parcoursService.getMesPelerins(familleId);
    return res.status(200).json(pelerins);
  } catch (error: any) {
    console.error('Erreur getMesPelerins:', error);
    return res.status(400).json({
      message: error.message || 'Erreur lors de la récupération des pèlerins',
    });
  }
});

// GET /famille/pelerins/:pelerinId/parcours
// Récupérer le parcours d'un pèlerin suivi
router.get('/pelerins/:pelerinId/parcours', async (req: AuthRequest, res: Response) => {
  try {
    const pelerinIdParam = req.params.pelerinId;
    if (Array.isArray(pelerinIdParam)) {
      return res.status(400).json({ message: 'pelerinId invalide' });
    }
    const pelerinId = pelerinIdParam;
    const familleId = await resolveFamilleId(req.user!.id);

    const parcours = await parcoursService.getParcoursPelerin(familleId, pelerinId);
    return res.status(200).json(parcours);
  } catch (error: any) {
    console.error('Erreur getParcoursPelerin:', error);
    return res.status(400).json({
      message: error.message || 'Erreur lors de la récupération du parcours',
    });
  }
});

export default router;

