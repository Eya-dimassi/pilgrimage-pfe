import { Router, Response } from 'express';
import { authenticate,requireRole, AuthRequest  } from '../auth/auth.middleware';
import * as agencesService from './agences.service';

const router = Router();

// POST /agences — super admin creates an agency
router.post(
  '/',
  authenticate,
  requireRole('SUPER_ADMIN'),
  async (req: AuthRequest, res: Response) => {
    try {
      const { nomAgence, email, motDePasse, adresse, telephone, siteWeb } = req.body;

      if (!nomAgence || !email || !motDePasse) {
        return res.status(400).json({
          message: 'Nom de l\'agence, email et mot de passe sont requis',
        });
      }

      const agence = await agencesService.createAgence({
        nomAgence,
        email,
        motDePasse,
        adresse,
        telephone,
        siteWeb,
      });

      return res.status(201).json(agence);
    } catch (error: any) {
      return res.status(400).json({ message: error.message });
    }
  }
);

// GET /agences — super admin gets all agencies
router.get(
  '/',
  authenticate,
  requireRole('SUPER_ADMIN'),
  async (req: AuthRequest, res: Response) => {
    try {
      const agences = await agencesService.getAgences();
      return res.status(200).json(agences);
    } catch (error: any) {
      return res.status(500).json({ message: 'Erreur serveur' });
    }
  }
);
// GET /agence/profile
router.get('/profile', authenticate, requireRole('AGENCE'), async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId!
    const profile = await agencesService.getAgenceProfile(agenceId)
    return res.json(profile)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.patch('/profile', authenticate, requireRole('AGENCE'), async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId!
    const { nomAgence, adresse, siteWeb, telephone, logo } = req.body
    const result = await agencesService.updateAgenceProfile(agenceId, {
      nomAgence, adresse, siteWeb, telephone, logo,
    })
    return res.json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

export default router;
