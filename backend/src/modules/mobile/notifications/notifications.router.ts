import { Router, Response } from 'express'
import { authenticate, requireRole, type AuthRequest } from '../../auth/auth.middleware'
import {
  getMyNotifications,
  markAllMyNotificationsAsRead,
  markMyNotificationAsRead,
  registerMyDeviceToken,
  unregisterMyDeviceToken,
} from './notifications.service'

const router = Router()

router.use(authenticate)
router.use(requireRole('GUIDE', 'PELERIN', 'FAMILLE'))

router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const result = await getMyNotifications(req.user!.id)
    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.post('/device-token', async (req: AuthRequest, res: Response) => {
  try {
    const result = await registerMyDeviceToken(req.user!.id, {
      token: req.body?.token,
      platform: req.body?.platform,
    })

    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.delete('/device-token', async (req: AuthRequest, res: Response) => {
  try {
    const result = await unregisterMyDeviceToken(
      req.user!.id,
      String(req.body?.token ?? req.query?.token ?? ''),
    )

    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.patch('/:notificationId/read', async (req: AuthRequest, res: Response) => {
  try {
    const result = await markMyNotificationAsRead(req.user!.id, String(req.params.notificationId))
    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

router.post('/read-all', async (req: AuthRequest, res: Response) => {
  try {
    const result = await markAllMyNotificationsAsRead(req.user!.id)
    return res.status(200).json(result)
  } catch (error: any) {
    return res.status(400).json({ message: error.message })
  }
})

export default router
