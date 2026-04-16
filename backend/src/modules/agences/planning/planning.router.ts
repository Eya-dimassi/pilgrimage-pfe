import { Router, Response } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../auth/auth.middleware';
import * as planningService from './planning.service';

const router = Router();

router.use(authenticate, requireRole('AGENCE'));

// GET /agence/groupes/:id/plannings
router.get('/:id/plannings', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.getPlanningVoyage(req.user!.agenceId!, String(req.params.id));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// POST /agence/groupes/:id/plannings
router.post('/:id/plannings', async (req: AuthRequest, res: Response) => {
  try {
    const { date, titre } = req.body;
    if (!date) {
      return res.status(400).json({ message: 'date requise' });
    }

    const result = await planningService.createPlanningDay(req.user!.agenceId!, String(req.params.id), {
      date,
      titre,
    });
    return res.status(201).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// POST /agence/groupes/:id/plannings/generate-template
router.post('/:id/plannings/generate-template', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.generatePlanningTemplate(req.user!.agenceId!, String(req.params.id));
    return res.status(201).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// POST /agence/groupes/:id/plannings/shift
router.post('/:id/plannings/shift', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.shiftPlanningVoyage(
      req.user!.agenceId!,
      String(req.params.id),
      req.body,
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// DELETE /agence/groupes/:id/plannings
router.delete('/:id/plannings', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.deletePlanningVoyage(
      req.user!.agenceId!,
      String(req.params.id),
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// PATCH /agence/groupes/plannings/:planningId
router.patch('/plannings/:planningId', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.updatePlanningDay(
      req.user!.agenceId!,
      String(req.params.planningId),
      req.body,
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// DELETE /agence/groupes/plannings/:planningId
router.delete('/plannings/:planningId', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.deletePlanningDay(req.user!.agenceId!, String(req.params.planningId));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// POST /agence/groupes/plannings/:planningId/evenements
router.post('/plannings/:planningId/evenements', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.createPlanningEvent(
      req.user!.agenceId!,
      String(req.params.planningId),
      req.body,
    );
    return res.status(201).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// PATCH /agence/groupes/evenements/:eventId
router.patch('/evenements/:eventId', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.updatePlanningEvent(
      req.user!.agenceId!,
      String(req.params.eventId),
      req.body,
    );
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// DELETE /agence/groupes/evenements/:eventId
router.delete('/evenements/:eventId', async (req: AuthRequest, res: Response) => {
  try {
    const result = await planningService.deletePlanningEvent(req.user!.agenceId!, String(req.params.eventId));
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

export default router;
