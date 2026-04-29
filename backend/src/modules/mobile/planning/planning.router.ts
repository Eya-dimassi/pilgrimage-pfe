import { Router, Response } from 'express'
import { authenticate, requireRole, type AuthRequest } from '../../auth/auth.middleware'
import {
  getMobilePelerinGroupHistory,
  getMobilePlanningForGroup,
  getMobileGroupPelerins,
  getMobilePlanningGroups,
  validateMobilePlanningEvent,
} from './planning.service'

const router = Router()

router.use(authenticate)
router.use(requireRole('GUIDE', 'PELERIN', 'FAMILLE'))

router.get('/groupes', async (req: AuthRequest, res: Response) => {
  try {
    const groupes = await getMobilePlanningGroups(req.user!.id, req.user!.role)
    return res.status(200).json(groupes)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.get(
  '/groupes/historique',
  requireRole('PELERIN'),
  async (req: AuthRequest, res: Response) => {
    try {
      const groupes = await getMobilePelerinGroupHistory(req.user!.id, req.user!.role)
      return res.status(200).json(groupes)
    } catch (error: any) {
      return res.status(400).json({ message: error.message })
    }
  },
)

router.get('/groupes/:groupeId', async (req: AuthRequest, res: Response) => {
  try {
    const planning = await getMobilePlanningForGroup(
      req.user!.id,
      req.user!.role,
      String(req.params.groupeId),
    )
    return res.status(200).json(planning)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.get(
  '/groupes/:groupeId/pelerins',
  requireRole('GUIDE'),
  async (req: AuthRequest, res: Response) => {
    try {
      const pelerins = await getMobileGroupPelerins(
        req.user!.id,
        req.user!.role,
        String(req.params.groupeId),
      )
      return res.status(200).json(pelerins)
    } catch (error: any) {
      return res.status(400).json({ message: error.message })
    }
  },
)

router.put(
  '/groupes/:groupeId/evenements/:eventId/valider',
  requireRole('GUIDE'),
  async (req: AuthRequest, res: Response) => {
    try {
      const result = await validateMobilePlanningEvent(
        req.user!.id,
        req.user!.role,
        String(req.params.groupeId),
        String(req.params.eventId),
      )
      return res.status(200).json(result)
    } catch (error: any) {
      return res.status(400).json({ message: error.message })
    }
  },
)

export default router
