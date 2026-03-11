// src/controllers/guide.controller.ts
import { Response } from 'express';
import { AuthRequest } from '../../auth/auth.middleware';
import {
  createGuide,
  getGuidesByAgence,
  getGuideById,
  updateGuide,
  deleteGuide,
  getAvailableGuides,
  getGuideStats
} from './guide.service';

/**
 * POST /api/agence/guides
 * Créer un nouveau guide
 */
export const createGuideController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    // Vérifier que l'utilisateur a bien une agence
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    const { nom, prenom, email, telephone, specialite, motDePasse } = req.body;

    // Validation
    if (!nom || !prenom || !email || !motDePasse) {
      return res.status(400).json({
        message: 'Nom, prénom, email et mot de passe sont obligatoires'
      });
    }

    // Valider format email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: 'Format email invalide' });
    }

    // Valider mot de passe (min 8 caractères)
    if (motDePasse.length < 8) {
      return res.status(400).json({
        message: 'Le mot de passe doit contenir au moins 8 caractères'
      });
    }

    const guide = await createGuide(agenceId, {
      nom,
      prenom,
      email,
      telephone,
      specialite,
      motDePasse
    });

    res.status(201).json({
      message: 'Guide créé avec succès',
      guide
    });
  } catch (error: any) {
    console.error('Erreur création guide:', error);
    if (error.message.includes('existe déjà') || error.message.includes('approuvées')) {
      return res.status(400).json({ message: error.message });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * GET /api/agence/guides
 * Récupérer tous les guides de l'agence
 */
export const getGuidesController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    const guides = await getGuidesByAgence(agenceId);

    res.json({
      count: guides.length,
      guides
    });
  } catch (error) {
    console.error('Erreur récupération guides:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * GET /api/agence/guides/available
 * Récupérer les guides disponibles (sans groupe assigné)
 */
export const getAvailableGuidesController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    const guides = await getAvailableGuides(agenceId);

    res.json({
      count: guides.length,
      guides
    });
  } catch (error) {
    console.error('Erreur récupération guides disponibles:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * GET /api/agence/guides/:id
 * Récupérer les détails d'un guide
 */
export const getGuideDetailsController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    // ✅ FIX: Gérer le type string | string[]
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    const guide = await getGuideById(id, agenceId);

    res.json(guide);
  } catch (error: any) {
    console.error('Erreur récupération guide:', error);
    if (error.message.includes('introuvable')) {
      return res.status(404).json({ message: error.message });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * GET /api/agence/guides/:id/stats
 * Récupérer les statistiques d'un guide
 */
export const getGuideStatsController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    // ✅ FIX: Gérer le type string | string[]
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    const stats = await getGuideStats(id, agenceId);

    res.json(stats);
  } catch (error: any) {
    console.error('Erreur stats guide:', error);
    if (error.message.includes('introuvable')) {
      return res.status(404).json({ message: error.message });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * PUT /api/agence/guides/:id
 * Mettre à jour un guide
 */
export const updateGuideController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    // ✅ FIX: Gérer le type string | string[]
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    
    const { nom, prenom, email, telephone, specialite, actif } = req.body;

    // Validation email si fourni
    if (email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({ message: 'Format email invalide' });
      }
    }

    const guide = await updateGuide(id, agenceId, {
      nom,
      prenom,
      email,
      telephone,
      specialite,
      actif
    });

    res.json({
      message: 'Guide mis à jour avec succès',
      guide
    });
  } catch (error: any) {
    console.error('Erreur mise à jour guide:', error);
    if (error.message.includes('introuvable') || error.message.includes('utilisé')) {
      return res.status(400).json({ message: error.message });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

/**
 * DELETE /api/agence/guides/:id
 * Supprimer un guide
 */
export const deleteGuideController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    // ✅ FIX: Gérer le type string | string[]
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    const result = await deleteGuide(id, agenceId);

    res.json(result);
  } catch (error: any) {
    console.error('Erreur suppression guide:', error);
    if (error.message.includes('introuvable') || error.message.includes('assigné')) {
      return res.status(400).json({ message: error.message });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
};