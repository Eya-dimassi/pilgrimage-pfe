import { Router, Response } from 'express'
import {
  authenticate,
  requireRole,
  type AuthRequest,
} from '../../auth/auth.middleware'
import {
  confirmPresenceAsPelerin,
  getFamilyPresenceStatuses,
  getActivePresenceCallForPelerin,
  getPresenceCallForPelerin,
} from './presence.service'

const router = Router()

router.use(authenticate)

router.get('/active', requireRole('PELERIN'), async (req: AuthRequest, res: Response) => {
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

router.get('/appels/:appelId', requireRole('PELERIN'), async (req: AuthRequest, res: Response) => {
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

router.put('/confirmations/:confirmationId', requireRole('PELERIN'), async (req: AuthRequest, res: Response) => {
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

router.get('/family/statuses', requireRole('FAMILLE'), async (req: AuthRequest, res: Response) => {
  try {
    const result = await getFamilyPresenceStatuses(req.user!.id)
    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors du chargement des statuts famille',
    })
  }
})

export default router
