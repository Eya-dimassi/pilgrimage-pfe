<template>
  <div class="dashboard" :class="{ dark: isDark }">
    <AppSidebar
      :nav-items="navItems"
      :current-view="currentView"
      :get-badge="getBadge"
      :user-initials="userInitials"
      :user="sidebarUser"
      header-title="Bienvenue"
      :header-subtitle="welcomeSubtitle"
      profile-position="bottom"
      footer-variant="profile"
      logout-position="bottom"
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
        @toggle-theme="toggleTheme"
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
            :resending-id="resendingPelerinId"
            @create="openModal('createPelerin')"
            @detail="openPelerinDetail($event)"
            @edit="openEdit('pelerin', $event)"
            @delete="confirmDelete('pelerin', $event)"
            @resend="doResendPelerinActivation($event)"
            @assign="doAssignerPelerin($event)"
            @bulk-assign="doBulkAssignerPelerins($event)"
            @unassign="doRetirerPelerin($event)"
          />

          <DashGuides
            v-if="currentView === 'guides'"
            :guides="guides"
            :resending-id="resendingId"
            :groupes="groupes"
            @create="openModal('createGuide')"
            @detail="openGuideDetail($event)"
            @edit="openEdit('guide', $event)"
            @delete="confirmDelete('guide', $event)"
            @resend="doResendActivation($event)"
            @assign="doAssignerGuide($event)"
          />

          <DashGroupes
            v-if="currentView === 'groupes'"
            :groupes="groupes"
            @create="openModal('createGroupe')"
            @edit="openEdit('groupe', $event)"
            @delete="confirmDelete('groupe', $event)"
            @assign="openAssign($event)"
            @remove-pelerin="doRetirerPelerin($event)"
            @remove-guide="doRetirerGuide($event)"
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
      :title="`Affecter des pelerins - ${selectedGroupe?.nom ?? ''}`"
      :error="modalError"
      @close="closeModal"
    >
      <div class="form-field">
        <label>Choisir des pelerins</label>

        <div class="multi-select" @click="assignDropdownOpen = !assignDropdownOpen">
          <div class="multi-select-value">{{ assignSelectedLabel }}</div>
          <AppIcon :name="assignDropdownOpen ? 'chevron-up' : 'chevron-down'" :size="14" />
        </div>

        <div v-if="assignDropdownOpen" class="multi-select-menu" @click.stop>
          <input v-model="assignSearch" class="multi-select-search" placeholder="Rechercher un pelerin..." />

          <div v-if="filteredUnassignedPelerins.length === 0" class="multi-select-empty">
            Aucun pelerin disponible
          </div>

          <label v-for="p in filteredUnassignedPelerins" :key="p.id" class="multi-select-option">
            <input type="checkbox" :value="p.id" v-model="form.pelerinIds" />
            <span>{{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}</span>
          </label>
        </div>
      </div>
      <template #actions>
        <button class="btn-secondary" @click="closeModal">Annuler</button>
        <button class="btn-primary" :disabled="actionLoading || selectedAssignPelerinIds.length === 0" @click="doAssign">
          {{ actionLoading ? 'Affectation...' : 'Affecter' }}
        </button>
      </template>
    </DashboardModalShell>

    <DashboardModalShell
      v-if="modal === 'delete'"
      :title="deleteModalTitle"
      danger
      small
      @close="closeModal"
    >
      <p class="modal-desc">
        <template v-if="deleteTarget?.typeVoyage">
          <template v-if="(deleteTarget?._count?.pelerins ?? deleteTarget?.pelerins?.length ?? 0) > 0">
            Ce groupe contient des pelerins : il sera <strong>annule</strong> (statut <strong>ANNULE</strong>) au lieu d'etre supprime.
          </template>
          <template v-else>
            Supprimer le groupe <strong>{{ deleteTarget?.nom }}</strong> ? Cette action est irreversible.
          </template>
        </template>
        <template v-else>
          Supprimer <strong>{{ deleteTarget?.utilisateur?.prenom ?? deleteTarget?.nom }} {{ deleteTarget?.utilisateur?.nom ?? '' }}</strong>
          ? Cette action est irreversible.
        </template>
      </p>
      <template #actions>
        <button class="btn-secondary" @click="closeModal">Annuler</button>
        <button class="btn-danger" :disabled="actionLoading" @click="doDelete">
          {{ actionLoading ? deleteModalLoadingLabel : deleteModalConfirmLabel }}
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

    <PelerinDetailModal
      v-if="selectedPelerinDetail"
      :pelerin="selectedPelerinDetail"
      :loading="pelerinDetailLoading"
      :error="pelerinDetailError"
      @close="closePelerinDetail"
    />

    <div v-if="toast.show" :class="['toast', toast.type]">{{ toast.message }}</div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import DashboardHome from '@/features/agence/components/dashboard/DashboardHome.vue'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'
import AppIcon from '@/components/AppIcon.vue'
import AppSidebar from '@/components/layout/AppSidebar.vue'
import AppTopbar from '@/components/layout/AppTopbar.vue'
import CreateGroupeModal from '@/features/agence/components/modals/CreateGroupeModal.vue'
import CreateGuideModal from '@/features/agence/components/modals/CreateGuideModal.vue'
import CreatePelerinModal from '@/features/agence/components/modals/CreatePelerinModal.vue'
import EditModal from '@/features/agence/components/modals/EditModal.vue'
import GuideDetailModal from '@/features/agence/components/modals/GuideDetailModal.vue'
import PelerinDetailModal from '@/features/agence/components/modals/PelerinDetailModal.vue'
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
  getPelerinDetails,
  getProfile,
  updateProfile,
} = useAgenceData()

const {
  modal,
  modalError,
  actionLoading,
  bulkAssignLoading,
  resendingId,
  resendingPelerinId,
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
  doResendPelerinActivation,
  doAssignerPelerin,
  doAssignerGuide,
  doBulkAssignerPelerins,
  doRetirerPelerin,
  doRetirerGuide,
} = useModal()

const THEME_STORAGE_KEY = 'agence-dark'
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
const selectedPelerinDetail = ref(null)
const pelerinDetailLoading = ref(false)
const pelerinDetailError = ref('')

const userInitials = computed(() =>
  ((sidebarUser.value?.prenom?.[0] ?? '') + (sidebarUser.value?.nom?.[0] ?? '')).toUpperCase() || 'AG'
)

const sidebarUser = computed(() => {
  const rawPrenom = String(user.value?.prenom ?? '').trim()
  const rawNom = String(user.value?.nom ?? '').trim()

  const prenom = rawPrenom === '-' || rawPrenom === '—' ? '' : rawPrenom
  const nom = rawNom === '-' || rawNom === '—' ? '' : rawNom

  return {
    ...(user.value ?? {}),
    prenom,
    nom,
  }
})

const agencyName = computed(() => sidebarUser.value?.nom || 'Agence')
const welcomeSubtitle = computed(() => `Agence ${agencyName.value}`.trim())

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

const isGroupeCancelDelete = computed(() => {
  const target = deleteTarget.value
  if (!target?.typeVoyage) return false
  const count = target?._count?.pelerins ?? target?.pelerins?.length ?? 0
  return count > 0
})

const deleteModalTitle = computed(() =>
  isGroupeCancelDelete.value ? "Confirmer l'annulation" : 'Confirmer la suppression'
)

const deleteModalConfirmLabel = computed(() =>
  isGroupeCancelDelete.value ? 'Annuler le groupe' : 'Supprimer'
)

const deleteModalLoadingLabel = computed(() =>
  isGroupeCancelDelete.value ? 'Annulation...' : 'Suppression...'
)

const unassignedPelerins = computed(() =>
  pelerins.value.filter((p) => !p.groupeId || p.groupeId !== selectedGroupe.value?.id)
)

const assignDropdownOpen = ref(false)
const assignSearch = ref('')

const selectedAssignPelerinIds = computed(() => {
  const ids = Array.isArray(form.value?.pelerinIds) ? form.value.pelerinIds : []
  return ids.filter(Boolean)
})

const filteredUnassignedPelerins = computed(() => {
  const query = assignSearch.value.trim().toLowerCase()
  if (!query) return unassignedPelerins.value

  return unassignedPelerins.value.filter((p) => {
    const prenom = p.utilisateur?.prenom ?? ''
    const nom = p.utilisateur?.nom ?? ''
    const full = `${prenom} ${nom}`.trim().toLowerCase()
    return full.includes(query)
  })
})

const assignSelectedLabel = computed(() => {
  const count = selectedAssignPelerinIds.value.length
  if (count === 0) return 'Selectionner des pelerins'
  if (count === 1) {
    const id = selectedAssignPelerinIds.value[0]
    const p = unassignedPelerins.value.find((item) => item.id === id)
    if (!p) return '1 pelerin selectionne'
    return `${p.utilisateur?.prenom ?? ''} ${p.utilisateur?.nom ?? ''}`.trim() || '1 pelerin selectionne'
  }
  return `${count} pelerins selectionnes`
})

watch(modal, (value) => {
  if (value !== 'assign') {
    assignDropdownOpen.value = false
    assignSearch.value = ''
    return
  }

  if (!Array.isArray(form.value?.pelerinIds)) {
    form.value = { ...(form.value ?? {}), pelerinIds: [] }
  }
})

const navItems = [
  { view: 'dashboard', label: "Vue d'ensemble", badge: null, iconName: 'grid' },
  { view: 'pelerins', label: 'Pelerins', badge: 'pelerins', iconName: 'users' },
  { view: 'guides', label: 'Guides', badge: 'guides', iconName: 'user' },
  { view: 'groupes', label: 'Groupes', badge: 'groupes', iconName: 'home' },
]

function getGroupSymbol(typeVoyage) {
  return typeVoyage === 'HAJJ' ? 'HJ' : 'UM'
}

function toggleTheme() {
  isDark.value = !isDark.value
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

async function openPelerinDetail(pelerin) {
  selectedPelerinDetail.value = pelerin
  pelerinDetailError.value = ''
  pelerinDetailLoading.value = true

  try {
    selectedPelerinDetail.value = await getPelerinDetails(pelerin.id)
  } catch (error) {
    pelerinDetailError.value = error.response?.data?.message || 'Impossible de charger les details du pelerin.'
  } finally {
    pelerinDetailLoading.value = false
  }
}

function closePelerinDetail() {
  selectedPelerinDetail.value = null
  pelerinDetailError.value = ''
}

watch(isDark, (value) => {
  try {
    localStorage.setItem(THEME_STORAGE_KEY, String(value))
  } catch {}
})

onMounted(() => {
  try {
    const saved = localStorage.getItem(THEME_STORAGE_KEY)
    if (saved === 'true' || saved === 'false') {
      isDark.value = saved === 'true'
    }
  } catch {}

  loadAll()
})
</script>
