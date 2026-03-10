import { Router, Response,Request } from 'express';
import { authenticate, requireRole, AuthRequest } from '../auth/auth.middleware';
import * as adminService from './admin.service';
const router = Router();

router.use(authenticate, requireRole('SUPER_ADMIN'));

// GET /admin/agences?status=PENDING
router.get('/agences', async (req: AuthRequest, res: Response) => {
  try {
    const status = typeof req.query.status === 'string' ? req.query.status : undefined;
    const agences = await adminService.getAgences(status);
    return res.status(200).json(agences);
  } catch (error: any) {
    return res.status(500).json({ message: error.message });
  }
});


// GET /admin/agences/:id
router.get('/agences/:id', async (req: AuthRequest, res: Response) => {
  try {
    const agence = await adminService.getAgenceById(String(req.params.id));
    return res.status(200).json(agence);
  } catch (error: any) {
    return res.status(404).json({ message: error.message });
  }
});

// PATCH /admin/agences/:id/approve
router.patch('/agences/:id/approve', async (req: AuthRequest, res: Response) => {
  try {
    const result = await adminService.approveAgence(String(req.params.id));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// PATCH /admin/agences/:id/reject
router.patch('/agences/:id/reject', async (req: AuthRequest, res: Response) => {
  try {
    const { reason } = req.body;
    if (!reason) return res.status(400).json({ message: 'Raison de refus requise' });
    const result = await adminService.rejectAgence(String(req.params.id), reason);
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// PATCH /admin/agences/:id/suspend
router.patch('/agences/:id/suspend', async (req: AuthRequest, res: Response) => {
  try {
    const result = await adminService.suspendAgence(String(req.params.id));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});
// DELETE /admin/agences/:id
router.delete('/agences/:id', async (req: AuthRequest, res: Response) => {
  try {
    const result = await adminService.deleteAgence(String(req.params.id));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;