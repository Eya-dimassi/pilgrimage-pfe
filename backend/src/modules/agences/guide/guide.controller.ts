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
  getGuideStats,
  resendActivationEmail
} from './guide.service';

/**
 * POST /agence/guides
 * Créer un nouveau guide (SANS mot de passe)
 */
export const createGuideController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    const { nom, prenom, email, telephone, specialite } = req.body; // ⭐ RETIRER motDePasse

    // Validation
    if (!nom || !prenom || !email) { // ⭐ RETIRER motDePasse de la validation
      return res.status(400).json({
        message: 'Nom, prénom et email sont obligatoires'
      });
    }

    // Valider format email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: 'Format email invalide' });
    }

    // ⭐ RETIRER la validation du mot de passe

    const guide = await createGuide(agenceId, {
      nom,
      prenom,
      email,
      telephone,
      specialite
    });

    res.status(201).json({
      message: 'Guide créé avec succès. Un email d\'activation a été envoyé à ' + email,
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

// ⭐ AJOUTER CETTE NOUVELLE FONCTION
/**
 * POST /api/agence/guides/:id/resend-activation
 * Renvoyer l'email d'activation
 */
export const resendActivationController = async (req: AuthRequest, res: Response) => {
  try {
    const agenceId = req.user!.agenceId;
    
    if (!agenceId) {
      return res.status(400).json({
        message: 'Utilisateur non associé à une agence'
      });
    }

    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    const result = await resendActivationEmail(id, agenceId);

    res.json(result);
  } catch (error: any) {
    console.error('Erreur renvoi activation:', error);
    if (error.message.includes('introuvable') || error.message.includes('déjà activé')) {
      return res.status(400).json({ message: error.message });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Gardez les autres fonctions telles quelles
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