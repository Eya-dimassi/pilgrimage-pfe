// src/services/guide.service.js
import api from './api';

export const guideService = {
  /**
   * Créer un nouveau guide
   */
  async createGuide(guideData) {
    const response = await api.post('/agence/guides', guideData);
    return response.data;
  },

  /**
   * Récupérer tous les guides de l'agence
   */
  async getAllGuides() {
    const response = await api.get('/agence/guides');
    return response.data;
  },

  /**
   * Récupérer les guides disponibles (sans groupe)
   */
  async getAvailableGuides() {
    const response = await api.get('/agence/guides/available');
    return response.data;
  },

  /**
   * Récupérer les détails d'un guide
   */
  async getGuideById(guideId) {
    const response = await api.get(`/agence/guides/${guideId}`);
    return response.data;
  },

  /**
   * Récupérer les statistiques d'un guide
   */
  async getGuideStats(guideId) {
    const response = await api.get(`/agence/guides/${guideId}/stats`);
    return response.data;
  },

  /**
   * Mettre à jour un guide
   */
  async updateGuide(guideId, updateData) {
    const response = await api.put(`/agence/guides/${guideId}`, updateData);
    return response.data;
  },

  /**
   * Supprimer un guide
   */
  async deleteGuide(guideId) {
    const response = await api.delete(`/agence/guides/${guideId}`);
    return response.data;
  },
  /**
   * Renvoyer l'email d'activation
   */
  async resendActivation(guideId) {
    const response = await api.post(`/agence/guides/${guideId}/resend-activation`);
    return response.data;
  }
};