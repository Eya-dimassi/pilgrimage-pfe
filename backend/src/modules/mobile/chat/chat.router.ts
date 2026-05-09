import { Router, Response } from 'express';
import {
  authenticate,
  requireRole,
  type AuthRequest,
} from '../../auth/auth.middleware';
import { handleChatMessage } from './chat.service';
import { ChatRequest, type UserRole } from './chat.types';

const router = Router();

router.use(authenticate);
router.use(requireRole('PELERIN', 'FAMILLE'));

function mapUserRole(role: string): UserRole {
  return role === 'FAMILLE' ? 'famille' : 'pelerin';
}

router.post('/message', async (req: AuthRequest, res: Response) => {
  try {
    const { message, history, language } =
      req.body as Omit<ChatRequest, 'userRole'>;

    if (!message || typeof message !== 'string' || message.trim() === '') {
      return res.status(400).json({ error: 'Message is required' });
    }

    if (!language || !['ar', 'fr', 'en'].includes(language)) {
      return res.status(400).json({ error: 'Invalid language' });
    }

    if (history !== undefined && !Array.isArray(history)) {
      return res.status(400).json({ error: 'Invalid history' });
    }

    const response = await handleChatMessage({
      message: message.trim(),
      history: history ?? [],
      userRole: mapUserRole(req.user!.role),
      language,
    });

    return res.status(200).json(response);
  } catch (err) {
    console.error('Router error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
