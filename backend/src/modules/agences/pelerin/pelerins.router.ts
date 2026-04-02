import { Router, Response } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../auth/auth.middleware';
import * as pelerinsService from './pelerins.service';

const router = Router();

// all routes require AGENCE token
router.use(authenticate, requireRole('AGENCE'));

// POST /agence/pelerins
router.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const { nom, prenom, email, telephone, dateNaissance, numeroPasseport, nationalite } = req.body;

    if (!nom || !prenom || !email) {
      return res.status(400).json({ message: 'Nom, prénom et email sont requis' });
    }

    const result = await pelerinsService.createPelerin(
      req.user!.agenceId!,
      req.user!.id,
      { nom, prenom, email, telephone, dateNaissance, numeroPasseport, nationalite }
    );
    return res.status(201).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// GET /agence/pelerins
router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const pelerins = await pelerinsService.getPelerins(req.user!.agenceId!);
    return res.status(200).json(pelerins);
  } catch (error: any) {
    return res.status(500).json({ message: error.message });
  }
});

// GET /agence/pelerins/:id
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const pelerin = await pelerinsService.getPelerinById(req.user!.agenceId!, String(req.params.id));
    return res.status(200).json(pelerin);
  } catch (error: any) {
    return res.status(404).json({ message: error.message });
  }
});

// POST /agence/pelerins/:id/resend-activation
router.post('/:id/resend-activation', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pelerinsService.resendActivationEmail(String(req.params.id), req.user!.agenceId!);
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// PATCH /agence/pelerins/:id
router.patch('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pelerinsService.updatePelerin(
      req.user!.agenceId!,
      String(req.params.id),
      req.body
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// DELETE /agence/pelerins/:id
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await pelerinsService.deletePelerin(req.user!.agenceId!, String(req.params.id));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
