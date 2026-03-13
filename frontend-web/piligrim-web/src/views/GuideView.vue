<template>
  <div class="min-h-screen bg-gradient-to-br from-[#0d0f1a] to-[#1b1e2e] text-white p-6">
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-3xl font-bold">Gestion des Guides</h1>
          <p class="text-gray-400 mt-1">Gérez vos guides et leurs affectations</p>
        </div>
        <button 
          @click="openCreateModal"
          class="px-6 py-3 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 rounded-xl font-semibold transition flex items-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          Nouveau Guide
        </button>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-400 text-sm">Total Guides</p>
              <p class="text-3xl font-bold mt-1">{{ totalGuides }}</p>
            </div>
            <div class="p-3 bg-blue-500/20 rounded-xl">
              <svg class="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>
              </svg>
            </div>
          </div>
        </div>

        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-400 text-sm">Guides Actifs</p>
              <p class="text-3xl font-bold mt-1 text-green-400">{{ activeGuides.length }}</p>
            </div>
            <div class="p-3 bg-green-500/20 rounded-xl">
              <svg class="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
          </div>
        </div>

        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-400 text-sm">Disponibles</p>
              <p class="text-3xl font-bold mt-1 text-orange-400">{{ guidesDisponibles.length }}</p>
            </div>
            <div class="p-3 bg-orange-500/20 rounded-xl">
              <svg class="w-6 h-6 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
          </div>
        </div>

        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-400 text-sm">Avec Groupes</p>
              <p class="text-3xl font-bold mt-1 text-purple-400">{{ totalGuides - guidesDisponibles.length }}</p>
            </div>
            <div class="p-3 bg-purple-500/20 rounded-xl">
              <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"></path>
              </svg>
            </div>
          </div>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading.list" class="flex justify-center items-center h-64">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>

      <!-- Guides Table -->
      <div v-else class="bg-[#1b1e2e] rounded-2xl border border-gray-800 overflow-hidden">
        <div class="p-6 border-b border-gray-800">
          <h2 class="text-xl font-bold">Liste des Guides</h2>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-gray-800 bg-gray-800/30">
                <th class="text-left py-4 px-6 text-sm font-semibold text-gray-400">Guide</th>
                <th class="text-left py-4 px-6 text-sm font-semibold text-gray-400">Contact</th>
                <th class="text-left py-4 px-6 text-sm font-semibold text-gray-400">Spécialité</th>
                <th class="text-left py-4 px-6 text-sm font-semibold text-gray-400">Groupes</th>
                <th class="text-left py-4 px-6 text-sm font-semibold text-gray-400">Activation</th>
                <th class="text-left py-4 px-6 text-sm font-semibold text-gray-400">Statut</th>
                <th class="text-left py-4 px-6 text-sm font-semibold text-gray-400">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="guides.length === 0">
                <td colspan="6" class="py-12 text-center text-gray-400">
                  <svg class="w-16 h-16 mx-auto mb-4 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>
                  </svg>
                  <p class="text-lg">Aucun guide pour le moment</p>
                  <p class="text-sm mt-2">Cliquez sur "Nouveau Guide" pour créer votre premier guide</p>
                </td>
              </tr>
              <tr 
                v-for="guide in guides" 
                :key="guide.id"
                class="border-b border-gray-800/50 hover:bg-gray-800/30 transition"
              >
                <!-- Guide Info -->
                <td class="py-4 px-6">
                  <div class="flex items-center gap-3">
                    <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white font-bold text-lg">
                      {{ getInitials(guide.utilisateur.nom, guide.utilisateur.prenom) }}
                    </div>
                    <div>
                      <p class="font-semibold">{{ guide.utilisateur.prenom }} {{ guide.utilisateur.nom }}</p>
                      <p class="text-xs text-gray-400">ID: {{ guide.id.substring(0, 8) }}</p>
                    </div>
                  </div>
                </td>

                <!-- Contact -->
                <td class="py-4 px-6">
                  <div>
                    <p class="text-sm">{{ guide.utilisateur.email }}</p>
                    <p class="text-xs text-gray-400">{{ guide.utilisateur.telephone || 'Non renseigné' }}</p>
                  </div>
                </td>

                <!-- Spécialité -->
                <td class="py-4 px-6">
                  <span v-if="guide.specialite" class="px-3 py-1 bg-purple-500/20 text-purple-400 rounded-full text-sm">
                    {{ guide.specialite }}
                  </span>
                  <span v-else class="text-gray-500 text-sm">Non spécifié</span>
                </td>

                <!-- Groupes -->
                <td class="py-4 px-6">
                  <div class="flex items-center gap-2">
                    <span class="px-3 py-1 bg-blue-500/20 text-blue-400 rounded-full text-sm font-medium">
                      {{ guide._count.groupes }} groupe(s)
                    </span>
                    <span 
                      v-if="guide._count.groupes === 0"
                      class="px-2 py-1 bg-green-500/20 text-green-400 rounded text-xs"
                    >
                      Disponible
                    </span>
                  </div>
                </td>
                <!-- Activation -->
<td class="py-4 px-6">
  <span 
    v-if="guide.utilisateur.isActivated"
    class="px-3 py-1 bg-green-500/20 text-green-400 rounded-full text-sm font-medium flex items-center gap-1 w-fit"
  >
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    </svg>
    Activé
  </span>
  <span 
    v-else
    class="px-3 py-1 bg-orange-500/20 text-orange-400 rounded-full text-sm font-medium flex items-center gap-1 w-fit"
  >
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    </svg>
    En attente
  </span>
</td>
                <!-- Statut -->
                <td class="py-4 px-6">
                  <span 
                    class="px-3 py-1 rounded-full text-sm font-medium"
                    :class="guide.utilisateur.actif ? 'bg-green-500/20 text-green-400' : 'bg-gray-500/20 text-gray-400'"
                  >
                    {{ guide.utilisateur.actif ? 'Actif' : 'Inactif' }}
                  </span>
                </td>

                <!-- Actions -->
                <td class="py-4 px-6">
                  <div class="flex gap-2">
                    <!-- Renvoyer activation (si non activé) -->
<button 
  v-if="!guide.utilisateur.isActivated"
  @click="resendActivation(guide)"
  class="p-2 bg-blue-500/20 text-blue-400 rounded-lg hover:bg-blue-500/30 transition"
  title="Renvoyer l'email d'activation"
>
  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
  </svg>
</button>
                    <button 
                      @click="openEditModal(guide)"
                      class="p-2 bg-blue-500/20 text-blue-400 rounded-lg hover:bg-blue-500/30 transition"
                      title="Modifier"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                      </svg>
                    </button>
                    <button 
                      @click="openDeleteModal(guide)"
                      class="p-2 bg-red-500/20 text-red-400 rounded-lg hover:bg-red-500/30 transition"
                      title="Supprimer"
                      :disabled="guide._count.groupes > 0"
                      :class="guide._count.groupes > 0 ? 'opacity-50 cursor-not-allowed' : ''"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                      </svg>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Modal Create/Edit -->
    <div v-if="showModal" class="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center z-50 p-4" @click.self="closeModal">
      <div class="bg-[#1b1e2e] rounded-2xl max-w-2xl w-full p-6 border border-gray-800">
        <h3 class="text-2xl font-bold mb-6">{{ isEditMode ? 'Modifier le guide' : 'Nouveau guide' }}</h3>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <!-- Nom & Prénom -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-semibold text-gray-300 mb-2">Prénom *</label>
              <input 
                v-model="formData.prenom" 
                type="text" 
                required
                class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Ahmed"
              >
            </div>
            <div>
              <label class="block text-sm font-semibold text-gray-300 mb-2">Nom *</label>
              <input 
                v-model="formData.nom" 
                type="text" 
                required
                class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Mansouri"
              >
            </div>
          </div>

          <!-- Email -->
          <div>
            <label class="block text-sm font-semibold text-gray-300 mb-2">Email *</label>
            <input 
              v-model="formData.email" 
              type="email" 
              required
              class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="ahmed.guide@email.com"
            >
          </div>

          <!-- Téléphone -->
          <div>
            <label class="block text-sm font-semibold text-gray-300 mb-2">Téléphone</label>
            <input 
              v-model="formData.telephone" 
              type="tel"
              class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="+33 6 12 34 56 78"
            >
          </div>

          <!-- Spécialité -->
          <div>
            <label class="block text-sm font-semibold text-gray-300 mb-2">Spécialité</label>
            <select 
              v-model="formData.specialite"
              class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Aucune spécialité</option>
              <option value="Hajj">Hajj</option>
              <option value="Umrah">Umrah</option>
              <option value="Bilingue">Bilingue (Arabe/Français)</option>
              <option value="Médical">Formation médicale</option>
              <option value="Senior">Guide senior (10+ ans)</option>
            </select>
          </div>

         <!-- Info activation par email -->
<div v-if="!isEditMode" class="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4">
  <div class="flex gap-3">
    <svg class="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    </svg>
    <div>
      <p class="text-sm font-semibold text-blue-400">Activation par email</p>
      <p class="text-sm text-gray-300 mt-1">
        Un email sera envoyé au guide avec un lien d'activation. 
        Il pourra définir son propre mot de passe lors de l'activation.
      </p>
    </div>
  </div>
</div>

          <!-- Statut (uniquement en édition) -->
          <div v-if="isEditMode" class="flex items-center gap-3">
            <input 
              v-model="formData.actif" 
              type="checkbox" 
              id="actif"
              class="w-5 h-5 rounded border-gray-600 bg-black text-blue-500 focus:ring-2 focus:ring-blue-500"
            >
            <label for="actif" class="text-sm font-medium">Compte actif</label>
          </div>

          <!-- Buttons -->
          <div class="flex gap-3 pt-4">
            <button 
              type="button" 
              @click="closeModal"
              class="flex-1 px-4 py-3 bg-gray-800 hover:bg-gray-700 rounded-lg font-medium transition"
            >
              Annuler
            </button>
            <button 
              type="submit"
              :disabled="loading.create || loading.update"
              class="flex-1 px-4 py-3 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 rounded-lg font-medium transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="loading.create || loading.update" class="flex items-center justify-center gap-2">
                <svg class="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Traitement...
              </span>
              <span v-else>{{ isEditMode ? 'Mettre à jour' : 'Créer le guide' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal Delete -->
    <div v-if="showDeleteModal" class="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center z-50 p-4" @click.self="closeDeleteModal">
      <div class="bg-[#1b1e2e] rounded-2xl max-w-md w-full p-6 border border-gray-800">
        <h3 class="text-xl font-bold mb-4">Supprimer le guide</h3>
        <p class="text-gray-400 mb-6">
          Êtes-vous sûr de vouloir supprimer le guide 
          <strong class="text-white">{{ selectedGuide?.utilisateur.prenom }} {{ selectedGuide?.utilisateur.nom }}</strong> ?
        </p>
        <p class="text-sm text-red-400 mb-6">
          ⚠️ Cette action est irréversible et supprimera définitivement le compte.
        </p>
        <div class="flex gap-3">
          <button 
            @click="closeDeleteModal"
            class="flex-1 px-4 py-3 bg-gray-800 hover:bg-gray-700 rounded-lg font-medium transition"
          >
            Annuler
          </button>
          <button 
            @click="confirmDelete"
            :disabled="loading.delete"
            class="flex-1 px-4 py-3 bg-red-500 hover:bg-red-600 rounded-lg font-medium transition disabled:opacity-50"
          >
            {{ loading.delete ? 'Suppression...' : 'Supprimer' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Toast -->
    <div v-if="showToast" class="fixed bottom-8 right-8 px-6 py-4 rounded-xl shadow-2xl flex items-center gap-3 z-50"
         :class="toastType === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'">
      <svg v-if="toastType === 'success'" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
      </svg>
      <svg v-else class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
      <div>
        <div class="font-bold">{{ toastMessage }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useGuidesStore } from '@/stores/guides';
import { storeToRefs } from 'pinia';

const guidesStore = useGuidesStore();
const { guides, loading, activeGuides, guidesDisponibles } = storeToRefs(guidesStore);
const { totalGuides } = guidesStore;

// État local
const showModal = ref(false);
const showDeleteModal = ref(false);
const isEditMode = ref(false);
const selectedGuide = ref(null);
const showToast = ref(false);
const toastMessage = ref('');
const toastType = ref('success');

const formData = ref({
  nom: '',
  prenom: '',
  email: '',
  telephone: '',
  specialite: '',
  actif: true
});

// Charger les guides au montage
onMounted(async () => {
  await guidesStore.fetchGuides();
});

// Méthodes
function getInitials(nom, prenom) {
  return `${prenom.charAt(0)}${nom.charAt(0)}`.toUpperCase();
}

function openCreateModal() {
  isEditMode.value = false;
  resetForm();
  showModal.value = true;
}

function openEditModal(guide) {
  isEditMode.value = true;
  selectedGuide.value = guide;
  formData.value = {
    nom: guide.utilisateur.nom,
    prenom: guide.utilisateur.prenom,
    email: guide.utilisateur.email,
    telephone: guide.utilisateur.telephone || '',
    specialite: guide.specialite || '',
    actif: guide.utilisateur.actif
  };
  showModal.value = true;
}

function openDeleteModal(guide) {
  selectedGuide.value = guide;
  showDeleteModal.value = true;
}

function closeModal() {
  showModal.value = false;
  selectedGuide.value = null;
  resetForm();
}

function closeDeleteModal() {
  showDeleteModal.value = false;
  selectedGuide.value = null;
}

function resetForm() {
  formData.value = {
    nom: '',
    prenom: '',
    email: '',
    telephone: '',
    specialite: '',
    actif: true
  };
}

async function handleSubmit() {
  try {
    if (isEditMode.value) {
      await guidesStore.updateGuide(selectedGuide.value.id, formData.value);
      toast('Guide mis à jour avec succès', 'success');
    } else {
      await guidesStore.createGuide(formData.value);
      toast('Guide créé avec succès', 'success');
    }
    closeModal();
  } catch (error) {
    const message = error.response?.data?.message || 'Une erreur est survenue';
    toast(message, 'error');
  }
}

async function confirmDelete() {
  try {
    await guidesStore.deleteGuide(selectedGuide.value.id);
    toast('Guide supprimé avec succès', 'success');
    closeDeleteModal();
  } catch (error) {
    const message = error.response?.data?.message || 'Une erreur est survenue';
    toast(message, 'error');
  }
}

function toast(message, type = 'success') {
  toastMessage.value = message;
  toastType.value = type;
  showToast.value = true;
  setTimeout(() => {
    showToast.value = false;
  }, 3000);
}
async function resendActivation(guide) {
  try {
    await guidesStore.resendActivationEmail(guide.id);
    toast('Email d\'activation renvoyé avec succès', 'success');
  } catch (error) {
    const message = error.response?.data?.message || 'Erreur lors du renvoi de l\'email';
    toast(message, 'error');
  }
}
</script>