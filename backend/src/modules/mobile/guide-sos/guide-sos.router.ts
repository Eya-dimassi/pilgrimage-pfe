import { Router, Response } from 'express'
import { authenticate, requireRole, type AuthRequest } from '../../auth/auth.middleware'
import { getActiveGuideSosAlerts, resolveGuideSosAlert } from './guide-sos.service'

const router = Router()

router.use(authenticate)
router.use(requireRole('GUIDE'))

router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const result = await getActiveGuideSosAlerts(req.user!.id)
    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.patch('/:sosId/resolve', async (req: AuthRequest, res: Response) => {
  try {
    const result = await resolveGuideSosAlert(req.user!.id, String(req.params.sosId))
    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

export default router
