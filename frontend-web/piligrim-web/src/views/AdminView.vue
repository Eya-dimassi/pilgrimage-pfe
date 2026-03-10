<template>
  <div class="admin-shell">

    <!-- Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-logo">
        <div class="logo-mark">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="8" width="18" height="13" rx="1"/>
            <path d="M7 8V6a5 5 0 0 1 10 0v2"/>
            <line x1="12" y1="12" x2="12" y2="16"/>
          </svg>
        </div>
        <span class="logo-name">SmartHajj</span>
      </div>

      <nav class="sidebar-nav">
        <p class="nav-section-label">Navigation</p>

        <a href="#" class="nav-item" :class="{ active: currentView === 'dashboard' }"
          @click.prevent="currentView = 'dashboard'">
          <svg class="nav-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
          </svg>
          Vue d'ensemble
        </a>

        <a href="#" class="nav-item" :class="{ active: currentView === 'agences' }"
          @click.prevent="currentView = 'agences'">
          <svg class="nav-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
          </svg>
          Agences
          <span v-if="pendingCount > 0" class="nav-badge">{{ pendingCount }}</span>
        </a>

        <p class="nav-section-label" style="margin-top: 2rem">Compte</p>

        <button class="nav-item nav-logout" @click="handleLogout">
          <svg class="nav-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
          </svg>
          Se déconnecter
        </button>
      </nav>

      <div class="sidebar-profile">
        <div class="profile-avatar">{{ userInitials }}</div>
        <div class="profile-info">
          <p class="profile-name">{{ user?.prenom }} {{ user?.nom }}</p>
          <p class="profile-role">Super Admin</p>
        </div>
      </div>
    </aside>

    <!-- Main -->
    <div class="main-area">

      <!-- Topbar -->
      <header class="topbar">
        <div class="topbar-search">
          <svg width="15" height="15" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" stroke-width="2">
            <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
          </svg>
          <input v-model="searchQuery" type="text" placeholder="Rechercher une agence..." class="search-input"/>
        </div>
        <div class="topbar-right">
          <!-- Dark mode toggle -->
          <button class="topbar-btn" @click="toggleDark" :title="isDark ? 'Mode clair' : 'Mode sombre'">
            <svg v-if="isDark" width="15" height="15" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" stroke-width="2">
              <circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>
            </svg>
            <svg v-else width="15" height="15" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" stroke-width="2">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
            </svg>
          </button>
          <!-- Refresh -->
          <button class="topbar-btn" @click="loadAgences" title="Actualiser">
            <svg width="15" height="15" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" stroke-width="2">
              <path d="M3 12a9 9 0 019-9 9.75 9.75 0 016.74 2.74L21 8M21 3v5h-5M21 12a9 9 0 01-9 9 9.75 9.75 0 01-6.74-2.74L3 16M3 21v-5h5"/>
            </svg>
          </button>
          <div class="topbar-avatar">{{ userInitials }}</div>
        </div>
      </header>

      <!-- Dynamic content -->
      <main class="page-content">
        <div class="page-header">
          <h1 class="page-title">{{ currentView === 'dashboard' ? "Vue d'ensemble" : 'Gestion des Agences' }}</h1>
          <p class="page-sub">{{ currentView === 'dashboard' ? 'Tableau de bord administrateur' : 'Approuver, refuser ou suspendre des agences' }}</p>
        </div>

        <AdminDashboard v-if="currentView === 'dashboard'" @go-agences="currentView = 'agences'" />
        <AdminAgences   v-if="currentView === 'agences'"   :search="searchQuery" />
      </main>
    </div>

    <!-- Global toast -->
    <Teleport to="body">
      <div class="ad-toast" :class="[{ 'ad-toast--show': showToast }, `ad-toast--${toastType}`]">
        <svg v-if="toastType === 'success'" width="15" height="15" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
        <svg v-else width="15" height="15" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>
        {{ toastMessage }}
      </div>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAdmin } from '@/composables/useAdmin'
import { useAdminToast } from '@/composables/useAdminToast'
import AdminDashboard from './AdminDashboard.vue'
import AdminAgences from './AdminAgences.vue'
import api from '@/services/api'
import '@/assets/styles/admin.css'
const router = useRouter()
const user   = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const { pendingCount, loadAgences, isDark, toggleDark, applyDark } = useAdmin()
const { showToast, toastMessage, toastType } = useAdminToast()

const currentView = ref('dashboard')
const searchQuery = ref('')

const userInitials = computed(() =>
  ((user.value?.prenom?.[0] ?? '') + (user.value?.nom?.[0] ?? '')).toUpperCase() || 'SA'
)

async function handleLogout() {
  try { await api.post('/auth/logout', { refreshToken: localStorage.getItem('refreshToken') }) } catch {}
  finally {
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('user')
    router.push('/')
  }
}

onMounted(() => {
  // Restore dark mode preference
  applyDark(localStorage.getItem('admin-dark') === 'true')
  loadAgences()
})
</script>