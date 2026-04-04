<template>
  <div class="admin-shell">
    <AppSidebar
      :collapsed="sidebarCollapsed"
      :nav-items="navItems"
      :current-view="currentView"
      :get-badge="getAdminBadge"
      :user-initials="userInitials"
      :user="user"
      user-role=""
      header-title="Bienvenue"
      :header-subtitle="`${user?.nom ?? ''}`.trim() || 'Admin'"
      profile-position="none"
      footer-variant="card"
      logout-position="bottom"
      @navigate="currentView = $event"
      @logout="handleLogout"
    />

    <div :class="['main-area', { 'main-area--sidebar-collapsed': sidebarCollapsed }]">
      <AppTopbar
        v-model="searchQuery"
        searchable
        :is-dark="isDark"
        :avatar-text="userInitials"
        :user="user"
        user-role="Super Admin"
        search-placeholder="Rechercher une agence..."
        @refresh="loadAgences"
        @toggle-theme="toggleDark"
        @toggle-sidebar="sidebarCollapsed = !sidebarCollapsed"
        @open-profile="openProfile"
        @edit-profile="openProfile"
        @logout="handleLogout"
      />

      <main class="page-content">
        <div class="page-header">
          <h1 class="page-title">{{ currentView === 'dashboard' ? "Vue d'ensemble" : 'Gestion des Agences' }}</h1>
        </div>

        <AdminDashboard v-if="currentView === 'dashboard'" @go-agences="currentView = 'agences'" />
        <AdminAgences v-if="currentView === 'agences'" :search="searchQuery" />
      </main>
    </div>

    <AdminProfileModal
      v-if="showProfile"
      :form="profileForm"
      :user="user"
      :loading="profileLoading"
      :error="profileError"
      role-label="Super Admin"
      @close="showProfile = false"
      @submit="saveProfile"
    />

    <Teleport to="body">
      <div class="ad-toast" :class="[{ 'ad-toast--show': showToast }, `ad-toast--${toastType}`]">
        <AppIcon v-if="toastType === 'success'" name="check" :size="15" :stroke-width="2.5" />
        <AppIcon v-else name="x" :size="15" :stroke-width="2.5" />
        {{ toastMessage }}
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import AppIcon from '@/components/AppIcon.vue'
import AppSidebar from '@/components/layout/AppSidebar.vue'
import AppTopbar from '@/components/layout/AppTopbar.vue'
import { useAdmin } from '@/features/admin/composables/useAdmin'
import { useAdminToast } from '@/features/admin/composables/useAdminToast'
import AdminDashboard from './AdminDashboard.vue'
import AdminAgences from './AdminAgences.vue'
import AdminProfileModal from './AdminProfileModal.vue'
import { getMe, logout, updateMe } from '@/services/auth.service'
import '@/assets/styles/admin.css'

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const { pendingCount, loadAgences, isDark, toggleDark, applyDark } = useAdmin()
const { showToast, toastMessage, toastType } = useAdminToast()

const currentView = ref('dashboard')
const searchQuery = ref('')
const showProfile = ref(false)
const sidebarCollapsed = ref(false)
const profileForm = ref({
  prenom: '',
  nom: '',
  email: '',
  telephone: '',
})
const profileLoading = ref(false)
const profileError = ref('')

const navItems = [
  { view: 'dashboard', label: "Vue d'ensemble", iconName: 'home' },
  { view: 'agences', label: 'Agences', iconName: 'building', badge: 'agences' },
]

const userInitials = computed(() =>
  ((user.value?.prenom?.[0] ?? '') + (user.value?.nom?.[0] ?? '')).toUpperCase() || 'A'
)

function getAdminBadge(type) {
  return type === 'agences' ? pendingCount.value : 0
}

async function handleLogout() {
  try {
    await logout()
  } finally {
    router.push('/')
  }
}

async function openProfile() {
  profileLoading.value = true
  profileError.value = ''

  try {
    const data = await getMe()
    user.value = data
    localStorage.setItem('user', JSON.stringify(data))
    profileForm.value = {
      prenom: data.prenom || '',
      nom: data.nom || '',
      email: data.email || '',
      telephone: data.telephone || '',
    }
    showProfile.value = true
  } catch (error) {
    profileError.value = error.response?.data?.message || 'Impossible de charger le profil.'
    showProfile.value = true
  } finally {
    profileLoading.value = false
  }
}

async function saveProfile() {
  profileLoading.value = true
  profileError.value = ''

  try {
    const data = await updateMe(profileForm.value)
    user.value = data
    showProfile.value = false
  } catch (error) {
    profileError.value = error.response?.data?.message || 'Impossible de mettre a jour le profil.'
  } finally {
    profileLoading.value = false
  }
}

onMounted(() => {
  applyDark(localStorage.getItem('admin-dark') === 'true')
  loadAgences()
})
</script>
