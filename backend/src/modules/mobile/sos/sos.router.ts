import { Router, Response } from 'express'
import { authenticate, requireRole, type AuthRequest } from '../../auth/auth.middleware'
import { createSosAlert, getMyActiveSos } from './sos.service'

const router = Router()

router.use(authenticate)
router.use(requireRole('PELERIN'))

router.get('/me', async (req: AuthRequest, res: Response) => {
  try {
    const result = await getMyActiveSos(req.user!.id)
    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const result = await createSosAlert(req.user!.id, {
      latitude: req.body?.latitude,
      longitude: req.body?.longitude,
      message: req.body?.message,
    })

    return res.status(result.created ? 201 : 200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

export default router
