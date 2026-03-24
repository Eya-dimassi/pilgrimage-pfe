<template>
  <div class="admin-shell">
    <AppSidebar
      :nav-items="navItems"
      :current-view="currentView"
      :get-badge="getAdminBadge"
      :user-initials="userInitials"
      :user="user"
      user-role="Super Admin"
      logo-variant="icon"
      logo-icon-name="lock"
      account-section-label="Compte"
      footer-variant="profile"
      @navigate="currentView = $event"
      @logout="handleLogout"
    />

    <div class="main-area">
      <AppTopbar
        v-model="searchQuery"
        searchable
        :is-dark="isDark"
        :avatar-text="userInitials"
        search-placeholder="Rechercher une agence..."
        @refresh="loadAgences"
        @toggle-theme="toggleDark"
      />

      <main class="page-content">
        <div class="page-header">
          <h1 class="page-title">{{ currentView === 'dashboard' ? "Vue d'ensemble" : 'Gestion des Agences' }}</h1>
          <p class="page-sub">
            {{ currentView === 'dashboard' ? 'Tableau de bord administrateur' : 'Approuver, refuser ou suspendre des agences' }}
          </p>
        </div>

        <AdminDashboard v-if="currentView === 'dashboard'" @go-agences="currentView = 'agences'" />
        <AdminAgences v-if="currentView === 'agences'" :search="searchQuery" />
      </main>
    </div>

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
import { logout } from '@/services/auth.service'
import '@/assets/styles/admin.css'

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const { pendingCount, loadAgences, isDark, toggleDark, applyDark } = useAdmin()
const { showToast, toastMessage, toastType } = useAdminToast()

const currentView = ref('dashboard')
const searchQuery = ref('')

const navItems = [
  { view: 'dashboard', label: "Vue d'ensemble", iconName: 'home' },
  { view: 'agences', label: 'Agences', iconName: 'building', badge: 'agences' },
]

const userInitials = computed(() =>
  ((user.value?.prenom?.[0] ?? '') + (user.value?.nom?.[0] ?? '')).toUpperCase() || 'SA'
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

onMounted(() => {
  applyDark(localStorage.getItem('admin-dark') === 'true')
  loadAgences()
})
</script>
