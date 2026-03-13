import { Router, Response } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../auth/auth.middleware';
import * as groupesService from './groupes.service';

const router = Router();

router.use(authenticate, requireRole('AGENCE'));

// POST /agence/groupes
router.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const { nom, annee, typeVoyage, description, guideId } = req.body;

    if (!nom || !annee || !typeVoyage) {
      return res.status(400).json({ message: 'Nom, année et type de voyage sont requis' });
    }
    if (!['HAJJ', 'UMRAH'].includes(typeVoyage)) {
      return res.status(400).json({ message: 'typeVoyage doit être HAJJ ou UMRAH' });
    }

    const result = await groupesService.createGroupe(req.user!.agenceId!, {
      nom, annee: Number(annee), typeVoyage, description, guideId,
    });
    return res.status(201).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// GET /agence/groupes
router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const groupes = await groupesService.getGroupes(req.user!.agenceId!);
    return res.status(200).json(groupes);
  } catch (error: any) {
    return res.status(500).json({ message: error.message });
  }
});

// GET /agence/groupes/:id
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const groupe = await groupesService.getGroupeById(req.user!.agenceId!, String(req.params.id));
    return res.status(200).json(groupe);
  } catch (error: any) {
    return res.status(404).json({ message: error.message });
  }
});

// PATCH /agence/groupes/:id
router.patch('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await groupesService.updateGroupe(
      req.user!.agenceId!,
      String(req.params.id),
      req.body
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// DELETE /agence/groupes/:id
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await groupesService.deleteGroupe(req.user!.agenceId!, String(req.params.id));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// POST /agence/groupes/:id/pelerins  — assign a pelerin
router.post('/:id/pelerins', async (req: AuthRequest, res: Response) => {
  try {
    const { pelerinId } = req.body;
    if (!pelerinId) return res.status(400).json({ message: 'pelerinId requis' });

    const result = await groupesService.assignerPelerin(
      req.user!.agenceId!,
      String(req.params.id),
      pelerinId
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// DELETE /agence/groupes/:id/pelerins/:pelerinId  — remove a pelerin
router.delete('/:id/pelerins/:pelerinId', async (req: AuthRequest, res: Response) => {
  try {
    const result = await groupesService.retirerPelerin(
      req.user!.agenceId!,
      String(req.params.id),
      String(req.params.pelerinId)
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;