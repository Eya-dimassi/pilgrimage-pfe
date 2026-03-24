<template>
  <div class="dashboard" :class="{ dark: isDark }">
    <AppSidebar
      :nav-items="navItems"
      :current-view="currentView"
      :get-badge="getBadge"
      :user-initials="userInitials"
      :user="user"
      logo-variant="brand-mark"
      logo-subtitle="Espace Agence"
      user-role="Agence"
      profile-clickable
      @navigate="currentView = $event"
      @open-profile="openProfile"
      @logout="handleLogout"
    />

    <div class="main-area">
      <AppTopbar
        :view-title="viewTitle"
        root-label="Agence"
        :is-dark="isDark"
        @refresh="loadAll"
        @toggle-theme="isDark = !isDark"
      />

      <div class="content">
        <div v-if="loading" class="state-center">
          <div class="spinner"></div>
          <p>Chargement...</p>
        </div>

        <div v-else-if="fetchError" class="state-center">
          <p class="error-text">{{ fetchError }}</p>
          <button class="btn-primary" @click="loadAll">Reessayer</button>
        </div>

        <template v-else>
          <DashboardHome
            v-if="currentView === 'dashboard'"
            :pelerins="pelerins"
            :guides="guides"
            :groupes="groupes"
            :pelerins-without-group-count="pelerinsWithoutGroupCount"
            :activated-guides-count="activatedGuidesCount"
            :pending-guides-count="pendingGuidesCount"
            :pending-activations-count="pendingActivationsCount"
            :actions-needed="actionsNeeded"
            :initials="initials"
            :guide-status-class="guideStatusClass"
            :guide-status-label="guideStatusLabel"
            :get-group-symbol="getGroupSymbol"
            @navigate="currentView = $event"
            @open-modal="openModal($event)"
          />

          <DashPelerins
            v-if="currentView === 'pelerins'"
            :pelerins="pelerins"
            :groupes="groupes"
            :bulk-assign-loading="bulkAssignLoading"
            @create="openModal('createPelerin')"
            @edit="openEdit('pelerin', $event)"
            @delete="confirmDelete('pelerin', $event)"
            @assign="doAssignerPelerin($event)"
            @bulk-assign="doBulkAssignerPelerins($event)"
            @unassign="doRetirerPelerin($event)"
          />

          <DashGuides
            v-if="currentView === 'guides'"
            :guides="guides"
            :resending-id="resendingId"
            @create="openModal('createGuide')"
            @detail="openGuideDetail($event)"
            @edit="openEdit('guide', $event)"
            @delete="confirmDelete('guide', $event)"
            @resend="doResendActivation($event)"
          />

          <DashGroupes
            v-if="currentView === 'groupes'"
            :groupes="groupes"
            @create="openModal('createGroupe')"
            @edit="openEdit('groupe', $event)"
            @delete="confirmDelete('groupe', $event)"
            @assign="openAssign($event)"
            @remove-pelerin="doRetirerPelerin($event)"
          />
        </template>
      </div>
    </div>

    <CreatePelerinModal
      v-if="modal === 'createPelerin'"
      :form="form"
      :error="modalError"
      :loading="actionLoading"
      @close="closeModal"
      @submit="doCreatePelerin"
    />

    <CreateGuideModal
      v-if="modal === 'createGuide'"
      :form="form"
      :error="modalError"
      :loading="actionLoading"
      @close="closeModal"
      @submit="doCreateGuide"
    />

    <CreateGroupeModal
      v-if="modal === 'createGroupe'"
      :form="form"
      :guides="guides"
      :error="modalError"
      :loading="actionLoading"
      @close="closeModal"
      @submit="doCreateGroupe"
    />

    <EditModal
      v-if="modal === 'edit'"
      :form="form"
      :edit-type="editType"
      :guides="guides"
      :error="modalError"
      :loading="actionLoading"
      @close="closeModal"
      @submit="doEdit"
    />

    <DashboardModalShell
      v-if="modal === 'assign'"
      :title="`Affecter un pelerin - ${selectedGroupe?.nom ?? ''}`"
      :error="modalError"
      @close="closeModal"
    >
      <div class="form-field">
        <label>Choisir un pelerin</label>
        <select v-model="form.pelerinId">
          <option value="">Selectionner</option>
          <option v-for="p in unassignedPelerins" :key="p.id" :value="p.id">
            {{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}
          </option>
        </select>
      </div>
      <template #actions>
        <button class="btn-secondary" @click="closeModal">Annuler</button>
        <button class="btn-primary" :disabled="actionLoading || !form.pelerinId" @click="doAssign">
          {{ actionLoading ? 'Affectation...' : 'Affecter' }}
        </button>
      </template>
    </DashboardModalShell>

    <DashboardModalShell
      v-if="modal === 'delete'"
      title="Confirmer la suppression"
      danger
      small
      @close="closeModal"
    >
      <p class="modal-desc">
        Supprimer <strong>{{ deleteTarget?.utilisateur?.prenom ?? deleteTarget?.nom }} {{ deleteTarget?.utilisateur?.nom ?? '' }}</strong>
        ? Cette action est irreversible.
      </p>
      <template #actions>
        <button class="btn-secondary" @click="closeModal">Annuler</button>
        <button class="btn-danger" :disabled="actionLoading" @click="doDelete">
          {{ actionLoading ? 'Suppression...' : 'Supprimer' }}
        </button>
      </template>
    </DashboardModalShell>

    <ProfileModal
      v-if="showProfile"
      :form="profileForm"
      :error="profileError"
      :loading="profileLoading"
      @close="showProfile = false"
      @submit="saveProfile"
    />

    <GuideDetailModal
      v-if="selectedGuideDetail"
      :guide="selectedGuideDetail"
      :stats="selectedGuideStats"
      :loading="guideDetailLoading"
      :error="guideDetailError"
      @close="closeGuideDetail"
    />

    <div v-if="toast.show" :class="['toast', toast.type]">{{ toast.message }}</div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import DashboardHome from '@/features/agence/components/dashboard/DashboardHome.vue'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'
import AppSidebar from '@/components/layout/AppSidebar.vue'
import AppTopbar from '@/components/layout/AppTopbar.vue'
import CreateGroupeModal from '@/features/agence/components/modals/CreateGroupeModal.vue'
import CreateGuideModal from '@/features/agence/components/modals/CreateGuideModal.vue'
import CreatePelerinModal from '@/features/agence/components/modals/CreatePelerinModal.vue'
import EditModal from '@/features/agence/components/modals/EditModal.vue'
import GuideDetailModal from '@/features/agence/components/modals/GuideDetailModal.vue'
import ProfileModal from '@/features/agence/components/modals/ProfileModal.vue'
import { useAgenceData } from '@/features/agence/composables/useAgenceData'
import { useDashboardStats } from '@/features/agence/composables/useDashboardStats'
import { useGuideStatus } from '@/features/agence/composables/useGuideStatus'
import { useModal } from '@/features/agence/composables/useModal'
import DashGroupes from '@/features/agence/views/Dashgroupes.vue'
import DashGuides from '@/features/agence/views/Dashguides.vue'
import DashPelerins from '@/features/agence/views/Dashpelerins.vue'

import '@/assets/styles/dashboard.css'

const {
  user,
  handleLogout,
  pelerins,
  guides,
  groupes,
  loading,
  fetchError,
  loadAll,
  getBadge,
  initials,
  getGuideStats,
  getProfile,
  updateProfile,
} = useAgenceData()

const {
  modal,
  modalError,
  actionLoading,
  bulkAssignLoading,
  resendingId,
  form,
  editType,
  deleteTarget,
  selectedGroupe,
  toast,
  closeModal,
  openModal,
  openEdit,
  openAssign,
  confirmDelete,
  showToast,
  doCreatePelerin,
  doCreateGuide,
  doCreateGroupe,
  doEdit,
  doAssign,
  doDelete,
  doResendActivation,
  doAssignerPelerin,
  doBulkAssignerPelerins,
  doRetirerPelerin,
} = useModal()

const isDark = ref(true)
const currentView = ref('dashboard')
const showProfile = ref(false)
const profileForm = ref({})
const profileLoading = ref(false)
const profileError = ref('')
const selectedGuideDetail = ref(null)
const selectedGuideStats = ref(null)
const guideDetailLoading = ref(false)
const guideDetailError = ref('')

const userInitials = computed(() =>
  ((user.value?.prenom?.[0] ?? '') + (user.value?.nom?.[0] ?? '')).toUpperCase() || 'AG'
)

const { guideStatusClass, guideStatusLabel } = useGuideStatus()

const {
  pelerinsWithoutGroupCount,
  activatedGuidesCount,
  pendingGuidesCount,
  pendingActivationsCount,
  actionsNeeded,
} = useDashboardStats({ pelerins, guides, groupes })

const viewTitle = computed(() => ({
  dashboard: "Vue d'ensemble",
  pelerins: 'Pelerins',
  guides: 'Guides',
  groupes: 'Groupes',
}[currentView.value]))

const unassignedPelerins = computed(() =>
  pelerins.value.filter((p) => !p.groupeId || p.groupeId !== selectedGroupe.value?.id)
)

const navItems = [
  { view: 'dashboard', label: "Vue d'ensemble", badge: null, iconName: 'grid' },
  { view: 'pelerins', label: 'Pelerins', badge: 'pelerins', iconName: 'users' },
  { view: 'guides', label: 'Guides', badge: 'guides', iconName: 'user' },
  { view: 'groupes', label: 'Groupes', badge: 'groupes', iconName: 'home' },
]

function getGroupSymbol(typeVoyage) {
  return typeVoyage === 'HAJJ' ? 'HJ' : 'UM'
}

async function openProfile() {
  profileError.value = ''

  try {
    const data = await getProfile()
    profileForm.value = {
      nomAgence: data.nomAgence,
      adresse: data.adresse || '',
      siteWeb: data.siteWeb || '',
      telephone: data.utilisateur?.telephone || '',
    }
    showProfile.value = true
  } catch (error) {
    showToast('Impossible de charger le profil', 'error')
  }
}

async function saveProfile() {
  profileLoading.value = true
  profileError.value = ''

  try {
    await updateProfile(profileForm.value)
    showProfile.value = false
    showToast('Profil mis a jour')
  } catch (error) {
    profileError.value = error.response?.data?.message || error.message
  } finally {
    profileLoading.value = false
  }
}

async function openGuideDetail(guide) {
  selectedGuideDetail.value = guide
  selectedGuideStats.value = null
  guideDetailError.value = ''
  guideDetailLoading.value = true

  try {
    selectedGuideStats.value = await getGuideStats(guide.id)
  } catch (error) {
    guideDetailError.value = error.response?.data?.message || 'Impossible de charger les statistiques du guide.'
  } finally {
    guideDetailLoading.value = false
  }
}

function closeGuideDetail() {
  selectedGuideDetail.value = null
  selectedGuideStats.value = null
  guideDetailError.value = ''
}

onMounted(loadAll)
</script>
