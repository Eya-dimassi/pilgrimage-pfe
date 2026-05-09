import { Router, Response } from 'express'
import {
  authenticate,
  requireRole,
  type AuthRequest,
} from '../../auth/auth.middleware'
import {
  confirmPresenceAsPelerin,
  getActivePresenceCallForPelerin,
  getPresenceCallForPelerin,
} from './presence.service'

const router = Router()

router.use(authenticate)
router.use(requireRole('PELERIN'))

router.get('/active', async (req: AuthRequest, res: Response) => {
  try {
    const result = await getActivePresenceCallForPelerin(req.user!.id)
    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors du chargement de l\'appel actif',
    })
  }
})

router.get('/appels/:appelId', async (req: AuthRequest, res: Response) => {
  try {
    const appelId = String(req.params.appelId)
    const result = await getPresenceCallForPelerin(req.user!.id, appelId)
    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors du chargement de l\'appel',
    })
  }
})

router.put('/confirmations/:confirmationId', async (req: AuthRequest, res: Response) => {
  try {
    const confirmationId = String(req.params.confirmationId)
    const result = await confirmPresenceAsPelerin(req.user!.id, confirmationId)
    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors de la confirmation de presence',
    })
  }
})

export default router
