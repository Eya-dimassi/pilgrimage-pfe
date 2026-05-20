import { Router, Response } from 'express'
import { authenticate, requireRole, AuthRequest } from '../../../auth/auth.middleware'
import { PresenceService } from './presence.service'
import prisma from '../../../../config/prisma'

const router = Router()
router.use(authenticate, requireRole('GUIDE'))

const getGuideId = async (req: AuthRequest, res: Response): Promise<string | null> => {
  const guide = await prisma.guide.findUnique({
    where: { utilisateurId: req.user!.id },
    select: { id: true },
  })

  if (!guide) {
    res.status(404).json({
      success: false,
      message: 'Profil guide introuvable',
    })
    return null
  }

  return guide.id
}

/**
 * POST /guide/presence/appels
 * Creer un appel de presence
 */
router.post('/appels', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const { groupeId } = req.body

    if (!groupeId) {
      return res.status(400).json({
        success: false,
        message: 'groupeId est requis',
      })
    }

    const result = await PresenceService.creerAppelPresence(guideId, groupeId)

    return res.status(result.isExisting ? 200 : 201).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in creerAppelPresence route:', error)
    const errorCode = error?.code
    const statusCode = errorCode === 'GROUP_NOT_IN_PROGRESS' ? 409 : 400

    return res.status(statusCode).json({
      success: false,
      message: error.message || 'Erreur lors de la creation de l\'appel',
      ...(errorCode ? { code: errorCode } : {}),
    })
  }
})

/**
 * GET /guide/presence/appels/:appelId
 */
router.get('/appels/:appelId', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const appelId = String(req.params.appelId)
    const result = await PresenceService.getAppelPresence(guideId, appelId)

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in getAppelPresence route:', error)
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors du chargement de l\'appel',
    })
  }
})

/**
 * PUT /guide/presence/confirmations/:confirmationId
 */
router.put('/confirmations/:confirmationId', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const confirmationId = String(req.params.confirmationId)
    const { statut, note } = req.body

    if (!['PRESENT', 'ABSENT', 'EXCUSE'].includes(statut)) {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide',
      })
    }

    const result = await PresenceService.marquerPresence(guideId, confirmationId, {
      statut,
      note,
    })

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in marquerPresence route:', error)
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors de la mise a jour',
    })
  }
})

/**
 * POST /guide/presence/appels/:appelId/bulk
 */
router.post('/appels/:appelId/bulk', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const appelId = String(req.params.appelId)
    const { confirmations } = req.body

    if (!Array.isArray(confirmations) || confirmations.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'confirmations est requis',
      })
    }

    const result = await PresenceService.marquerPresenceBulk(guideId, appelId, {
      confirmations,
    })

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in marquerPresenceBulk route:', error)
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors de la mise a jour en masse',
    })
  }
})

/**
 * POST /guide/presence/appels/:appelId/scan
 */
router.post('/appels/:appelId/scan', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const appelId = String(req.params.appelId)
    const codeUnique = String(req.body?.codeUnique ?? '')

    if (!codeUnique.trim()) {
      return res.status(400).json({
        success: false,
        message: 'codeUnique est requis',
      })
    }

    const result = await PresenceService.scannerPresenceParQr(
      guideId,
      appelId,
      codeUnique,
    )

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in scannerPresenceParQr route:', error)
    const errorCode = error?.code
    const statusCodeByCode: Record<string, number> = {
      APPEL_NOT_FOUND: 404,
      APPEL_NOT_ACTIVE: 409,
      QR_INVALID: 404,
      PELERIN_NOT_IN_GROUP: 403,
      CONFIRMATION_NOT_FOUND: 404,
      ALREADY_PRESENT: 409,
    }
    const statusCode = statusCodeByCode[errorCode] ?? 400

    return res.status(statusCode).json({
      success: false,
      message: error.message || 'Erreur lors du scan QR',
      ...(errorCode ? { code: errorCode } : {}),
    })
  }
})

/**
 * POST /guide/presence/appels/:appelId/cloturer
 */
router.post('/appels/:appelId/cloturer', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const appelId = String(req.params.appelId)
    const result = await PresenceService.cloturerAppel(guideId, appelId)

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in cloturerAppel route:', error)
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors de la cloture',
    })
  }
})

/**
 * POST /guide/presence/appels/:appelId/reinitialiser-absents
 */
router.post('/appels/:appelId/reinitialiser-absents', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const appelId = String(req.params.appelId)
    const result = await PresenceService.reinitialiserAbsents(guideId, appelId)

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in reinitialiserAbsents route:', error)
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors de la reinitialisation des absents',
    })
  }
})

/**
 * GET /guide/presence/groupes/:groupeId/historique
 */
router.get('/groupes/:groupeId/historique', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const groupeId = String(req.params.groupeId)
    const result = await PresenceService.getHistoriqueAppels(guideId, groupeId)

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in getHistoriqueAppels route:', error)
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors du chargement de l\'historique',
    })
  }
})

/**
 * GET /guide/presence/pelerins/:pelerinId/stats
 */
router.get('/pelerins/:pelerinId/stats', async (req: AuthRequest, res: Response) => {
  try {
    const guideId = await getGuideId(req, res)
    if (!guideId) return

    const pelerinId = String(req.params.pelerinId)
    const result = await PresenceService.getStatsPelerin(guideId, pelerinId)

    return res.status(200).json({
      success: true,
      data: result,
    })
  } catch (error: any) {
    console.error('Error in getStatsPelerin route:', error)
    return res.status(400).json({
      success: false,
      message: error.message || 'Erreur lors du chargement des stats',
    })
  }
})

export default router
