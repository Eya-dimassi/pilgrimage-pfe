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
// POST /auth/signup
router.post('/signup',async(req: Request, res: Response)=> {
  try {
    const {nomAgence, email, motDePasse, telephone, adresse}=req.body;

    if (!nomAgence || !email || !motDePasse) {
      return res.status(400).json({ message: 'Nom agence, email et mot de passe requis'});
    }

    const result = await authService.signup({nomAgence, email, motDePasse, telephone, adresse});
    return res.status(201).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
  }
});

// POST /auth/logout
router.post('/logout', async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) await authService.logout(refreshToken);
    return res.status(200).json({ message: 'Déconnecté avec succès' });
  } catch {
    return res.status(200).json({ message: 'Déconnecté' });
  }
});

// POST /auth/refresh
router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken)
      return res.status(400).json({ message: 'Refresh token requis' });

    const result = await authService.refresh(refreshToken);
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(401).json({ message: error.message });
  }
});

// POST /auth/forgot-password
router.post('/forgot-password', async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email requis' });

    const result = await authService.forgotPassword(email);
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(500).json({ message: error.message });
  }
});

// POST /auth/set-password
router.post('/set-password', async (req: Request, res: Response) => {
  try {
    const { token, newPassword } = req.body;
    if (!token || !newPassword)
      return res.status(400).json({ message: 'Token et nouveau mot de passe requis' });

    const result = await authService.setPassword(token, newPassword);
    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(400).json({ message: error.message });
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