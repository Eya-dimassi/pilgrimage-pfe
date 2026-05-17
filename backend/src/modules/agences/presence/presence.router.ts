import { Router, Response } from 'express'
import { authenticate, requireRole, AuthRequest } from '../../auth/auth.middleware'
import { getAgencePresenceHistory } from './presence.service'

const router = Router()

router.use(authenticate, requireRole('AGENCE'))

router.get('/appels', async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user?.agenceId
    if (!agenceId) {
      return res.status(403).json({
        message: 'Agence introuvable pour cet utilisateur',
      })
    }

    const groupeId = String(req.query.groupeId ?? '').trim() || undefined
    const guideId = String(req.query.guideId ?? '').trim() || undefined
    const statutRaw = String(req.query.statut ?? '').trim().toUpperCase()
    const statut = statutRaw === 'EN_COURS' || statutRaw === 'CLOTURE' ? statutRaw : undefined
    const dateFrom = String(req.query.dateFrom ?? '').trim() || undefined
    const dateTo = String(req.query.dateTo ?? '').trim() || undefined

    const data = await getAgencePresenceHistory(agenceId, {
      groupeId,
      guideId,
      statut,
      dateFrom,
      dateTo,
    })

    return res.status(200).json(data)
  } catch (error: any) {
    return res.status(400).json({
      message: error.message || "Erreur lors du chargement de l'historique des appels",
    })
  }
})

export default router
