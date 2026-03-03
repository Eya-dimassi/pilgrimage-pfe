import { Router, Request, Response } from 'express';
import * as authService from './auth.service';
import { authenticate, AuthRequest } from './auth.middleware';

const router = Router();

// POST /auth/login
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, motDePasse } = req.body;

    if (!email || !motDePasse) {
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }

    const result = await authService.login(email, motDePasse);
    return res.status(200).json(result);

  } catch (error: any) {
    return res.status(401).json({ message: error.message });
  }
});

// GET /auth/me — protected route
router.get('/me', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const user = await authService.getMe(req.user!.id);
    return res.status(200).json(user);
  } catch (error: any) {
    return res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;