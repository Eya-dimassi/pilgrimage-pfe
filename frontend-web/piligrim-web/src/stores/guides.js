// src/stores/guides.js
import { defineStore } from 'pinia';
import { guideService } from '@/services/guide.service';

export const useGuidesStore = defineStore('guides', {
  state: () => ({
    guides: [],
    availableGuides: [],
    selectedGuide: null,
    loading: {
      list: false,
      create: false,
      update: false,
      delete: false,
      details: false
    }
  }),

  getters: {
    // Nombre total de guides
    totalGuides: (state) => state.guides.length,

    // Guides actifs
    activeGuides: (state) => {
      return state.guides.filter(g => g.utilisateur.actif);
    },

    // Guides par spécialité
    guidesBySpecialite: (state) => {
      const grouped = {};
      state.guides.forEach(guide => {
        const spec = guide.specialite || 'Non spécifié';
        if (!grouped[spec]) {
          grouped[spec] = [];
        }
        grouped[spec].push(guide);
      });
      return grouped;
    },

    // Guides disponibles (sans groupe)
    guidesDisponibles: (state) => {
      return state.guides.filter(g => g._count.groupes === 0);
    }
  },

  actions: {
    /**
     * Charger tous les guides
     */
    async fetchGuides() {
      this.loading.list = true;
      try {
        const response = await guideService.getAllGuides();
        this.guides = response.guides || [];
      } catch (error) {
        console.error('Erreur chargement guides:', error);
        throw error;
      } finally {
        this.loading.list = false;
      }
    },

    /**
     * Charger les guides disponibles
     */
    async fetchAvailableGuides() {
      try {
        const response = await guideService.getAvailableGuides();
        this.availableGuides = response.guides || [];
      } catch (error) {
        console.error('Erreur chargement guides disponibles:', error);
        throw error;
      }
    },

    /**
     * Charger les détails d'un guide
     */
    async fetchGuideDetails(guideId) {
      this.loading.details = true;
      try {
        const guide = await guideService.getGuideById(guideId);
        this.selectedGuide = guide;
        return guide;
      } catch (error) {
        console.error('Erreur chargement détails guide:', error);
        throw error;
      } finally {
        this.loading.details = false;
      }
    },

    /**
     * Créer un nouveau guide
     */
    async createGuide(guideData) {
      this.loading.create = true;
      try {
        const response = await guideService.createGuide(guideData);
        
        // Ajouter le nouveau guide à la liste
        this.guides.unshift(response.guide);
        
        return response;
      } catch (error) {
        console.error('Erreur création guide:', error);
        throw error;
      } finally {
        this.loading.create = false;
      }
    },

    /**
     * Mettre à jour un guide
     */
    async updateGuide(guideId, updateData) {
      this.loading.update = true;
      try {
        const response = await guideService.updateGuide(guideId, updateData);
        
        // Mettre à jour dans la liste
        const index = this.guides.findIndex(g => g.id === guideId);
        if (index !== -1) {
          this.guides[index] = response.guide;
        }
        
        // Mettre à jour selectedGuide si c'est celui-ci
        if (this.selectedGuide?.id === guideId) {
          this.selectedGuide = response.guide;
        }
        
        return response;
      } catch (error) {
        console.error('Erreur mise à jour guide:', error);
        throw error;
      } finally {
        this.loading.update = false;
      }
    },

    /**
     * Supprimer un guide
     */
    async deleteGuide(guideId) {
      this.loading.delete = true;
      try {
        await guideService.deleteGuide(guideId);
        
        // Retirer de la liste
        this.guides = this.guides.filter(g => g.id !== guideId);
        
        // Clear selectedGuide si c'est celui-ci
        if (this.selectedGuide?.id === guideId) {
          this.selectedGuide = null;
        }
        
        return { success: true };
      } catch (error) {
        console.error('Erreur suppression guide:', error);
        throw error;
      } finally {
        this.loading.delete = false;
      }
    },
    /**
 * Renvoyer l'email d'activation à un guide
 */
async resendActivationEmail(guideId) {
  try {
    const response = await guideService.resendActivation(guideId);
    return response;
  } catch (error) {
    console.error('Erreur renvoi activation:', error);
    throw error;
  }
},

    /**
     * Réinitialiser le store
     */
    resetStore() {
      this.guides = [];
      this.availableGuides = [];
      this.selectedGuide = null;
    }
  }
});