import { Router, Response } from 'express'
import { authenticate, requireRole, type AuthRequest } from '../../auth/auth.middleware'
import { getMobilePlanningForGroup, getMobilePlanningGroups } from './planning.service'

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

export default router
