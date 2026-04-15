import { Router, Response } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../../auth/auth.middleware';
import * as parcoursService from './parcours.service';
import prisma from '../../../../config/prisma';

const router = Router();

// Toutes les routes nécessitent authentification + rôle PELERIN
router.use(authenticate, requireRole('PELERIN'));

// GET /pelerin/parcours
// Récupérer mon parcours
router.get('/parcours', async (req: AuthRequest, res: Response) => {
  try {
    const utilisateurId = req.user!.id;

    const pelerinData = await prisma.pelerin.findUnique({
      where: { utilisateurId },
      select: { id: true },
    });

    if (!pelerinData) {
      return res.status(404).json({ message: 'Profil pèlerin introuvable' });
    }

    const parcours = await parcoursService.getMonParcours(pelerinData.id);
    return res.status(200).json(parcours);
  } catch (error: any) {
    console.error('Erreur getMonParcours:', error);
    return res.status(400).json({
      message: error.message || "Erreur lors de la récupération du parcours",
    });
  }
});

export default router;
