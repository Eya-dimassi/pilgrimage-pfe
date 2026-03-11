// src/routes/guide.routes.ts
import { Router } from 'express';
import {
  createGuideController,
  getGuidesController,
  getAvailableGuidesController,
  getGuideDetailsController,
  getGuideStatsController,
  updateGuideController,
  deleteGuideController
} from './guide.controller';
import { authenticate, requireRole } from '../../auth/auth.middleware';

const router = Router();

// Toutes les routes nécessitent d'être authentifié en tant qu'AGENCE
router.use(authenticate);
router.use(requireRole('AGENCE'));

/**
 * @route   POST /api/agence/guides
 * @desc    Créer un nouveau guide
 * @access  AGENCE
 * @body    { nom, prenom, email, telephone?, specialite?, motDePasse }
 */
router.post('/', createGuideController);

/**
 * @route   GET /api/agence/guides
 * @desc    Récupérer tous les guides de l'agence
 * @access  AGENCE
 */
router.get('/', getGuidesController);

/**
 * @route   GET /api/agence/guides/available
 * @desc    Récupérer les guides disponibles (non assignés)
 * @access  AGENCE
 * @important Cette route doit être AVANT /:id pour éviter conflits
 */
router.get('/available', getAvailableGuidesController);

/**
 * @route   GET /api/agence/guides/:id
 * @desc    Récupérer les détails d'un guide
 * @access  AGENCE
 */
router.get('/:id', getGuideDetailsController);

/**
 * @route   GET /api/agence/guides/:id/stats
 * @desc    Récupérer les statistiques d'un guide
 * @access  AGENCE
 */
router.get('/:id/stats', getGuideStatsController);

/**
 * @route   PUT /api/agence/guides/:id
 * @desc    Mettre à jour un guide
 * @access  AGENCE
 * @body    { nom?, prenom?, email?, telephone?, specialite?, actif? }
 */
router.put('/:id', updateGuideController);

/**
 * @route   DELETE /api/agence/guides/:id
 * @desc    Supprimer un guide
 * @access  AGENCE
 */
router.delete('/:id', deleteGuideController);

export default router;