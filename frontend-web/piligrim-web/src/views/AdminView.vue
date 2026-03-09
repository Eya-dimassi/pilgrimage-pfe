<!-- <template>
  <div class="min-h-screen bg-[#0d0f1a] text-white flex flex-col items-center justify-center">
    <div class="text-5xl mb-4">👑</div>
    <h1 class="text-2xl font-bold mb-2">Panneau Super Admin</h1>
    <p class="text-gray-400 mb-6">Bienvenue, {{ user?.prenom }} {{ user?.nom }}</p>
    <button
      @click="handleLogout"
      class="px-6 py-2 bg-yellow-600 hover:bg-yellow-400 text-black font-bold rounded-lg transition"
    >
      Se déconnecter
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const handleLogout = () => {
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('user')
  router.push('/')
}
</script>-->
<template>
  <div class="min-h-screen bg-gradient-to-br from-[#0d0f1a] to-[#1b1e2e] text-white">
    <!-- Sidebar -->
    <aside class="fixed left-0 top-0 h-screen w-64 bg-[#0d0f1a] border-r border-gray-800 overflow-y-auto">
      <!-- Logo -->
      <div class="p-6 border-b border-gray-800">
        <h1 class="text-xl font-bold text-white flex items-center gap-2">
          <span class="text-2xl">👑</span>
          SUPER ADMIN
        </h1>
        <p class="text-xs text-gray-500 mt-1">Gestion globale</p>
      </div>

      <!-- Menu -->
      <nav class="p-4 space-y-2">
        <div class="mb-4">
          <p class="text-xs text-gray-500 uppercase font-semibold mb-2 px-3">Navigation</p>
          
          <a href="#" @click.prevent="currentView = 'dashboard'" :class="currentView === 'dashboard' ? 'bg-blue-600/20 text-blue-400' : 'text-gray-400 hover:bg-gray-800/50'" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
            </svg>
            <span class="font-medium">Vue d'ensemble</span>
          </a>

          <a href="#" @click.prevent="currentView = 'agences'" :class="currentView === 'agences' ? 'bg-blue-600/20 text-blue-400' : 'text-gray-400 hover:bg-gray-800/50'" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
            </svg>
            <span>Agences</span>
            <span v-if="stats.agencesPending > 0" class="ml-auto bg-orange-500 text-white text-xs px-2 py-0.5 rounded-full">{{ stats.agencesPending }}</span>
          </a>

          <a href="#" @click.prevent="currentView = 'utilisateurs'" :class="currentView === 'utilisateurs' ? 'bg-blue-600/20 text-blue-400' : 'text-gray-400 hover:bg-gray-800/50'" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>
            </svg>
            <span>Utilisateurs</span>
          </a>

          <a href="#" @click.prevent="currentView = 'stats'" :class="currentView === 'stats' ? 'bg-blue-600/20 text-blue-400' : 'text-gray-400 hover:bg-gray-800/50'" class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
            </svg>
            <span>Statistiques</span>
          </a>
        </div>

        <div>
          <p class="text-xs text-gray-500 uppercase font-semibold mb-2 px-3">Système</p>
          
          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-gray-800/50 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
            <span>Paramètres</span>
          </a>
        </div>
      </nav>
    </aside>

    <!-- Main Content -->
    <main class="ml-64 p-6">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h2 class="text-2xl font-bold">{{ getViewTitle() }}</h2>
          <p class="text-gray-400 text-sm mt-1">{{ getViewSubtitle() }}</p>
        </div>
        <div class="flex items-center gap-4">
          <button class="p-2 hover:bg-gray-800 rounded-lg transition relative">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path>
            </svg>
            <span v-if="stats.agencesPending > 0" class="absolute top-1 right-1 w-2 h-2 bg-orange-500 rounded-full"></span>
          </button>
          <div class="flex items-center gap-3">
            <p class="text-gray-400 mb-6">Bienvenue, {{ user?.prenom }} {{ user?.nom }}</p>
    <button
      @click="handleLogout"
      class="px-6 py-2 bg-yellow-600 hover:bg-yellow-400 text-black font-bold rounded-lg transition"
    >
      Se déconnecter
    </button>
          </div>
        </div>
      </div>

      <!-- Dashboard View -->
      <div v-if="currentView === 'dashboard'">
        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <!-- Total Agences -->
          <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
            <div class="flex items-start justify-between mb-4">
              <div class="p-3 bg-blue-500/20 rounded-xl">
                <svg class="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                </svg>
              </div>
            </div>
            <div>
              <p class="text-gray-400 text-sm mb-1">Total Agences</p>
              <p class="text-3xl font-bold">{{ stats.totalAgences }}</p>
              <p class="text-xs text-green-400 mt-2">{{ stats.agencesApproved }} approuvées</p>
            </div>
          </div>

          <!-- Agences en Attente -->
          <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
            <div class="flex items-start justify-between mb-4">
              <div class="p-3 bg-orange-500/20 rounded-xl">
                <svg class="w-6 h-6 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </div>
              <span v-if="stats.agencesPending > 0" class="px-2 py-1 bg-orange-500/20 text-orange-400 rounded-full text-xs font-medium">
                Action requise
              </span>
            </div>
            <div>
              <p class="text-gray-400 text-sm mb-1">En Attente</p>
              <p class="text-3xl font-bold text-orange-400">{{ stats.agencesPending }}</p>
              <p class="text-xs text-gray-500 mt-2">À traiter</p>
            </div>
          </div>

          <!-- Total Utilisateurs -->
          <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
            <div class="flex items-start justify-between mb-4">
              <div class="p-3 bg-purple-500/20 rounded-xl">
                <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>
                </svg>
              </div>
            </div>
            <div>
              <p class="text-gray-400 text-sm mb-1">Utilisateurs</p>
              <p class="text-3xl font-bold">{{ stats.totalUtilisateurs }}</p>
              <p class="text-xs text-gray-500 mt-2">{{ stats.utilisateursActifs }} actifs</p>
            </div>
          </div>

          <!-- Total Pèlerins -->
          <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
            <div class="flex items-start justify-between mb-4">
              <div class="p-3 bg-green-500/20 rounded-xl">
                <svg class="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                </svg>
              </div>
            </div>
            <div>
              <p class="text-gray-400 text-sm mb-1">Pèlerins</p>
              <p class="text-3xl font-bold">{{ stats.totalPelerins }}</p>
              <p class="text-xs text-gray-500 mt-2">Sur la plateforme</p>
            </div>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Agences Récentes -->
          <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
            <h3 class="text-lg font-semibold mb-4">Dernières Inscriptions Agences</h3>
            <div class="space-y-3">
              <div v-for="agence in recentAgences" :key="agence.id" class="flex items-center justify-between p-3 bg-gray-800/30 rounded-lg">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center">
                    <span class="text-blue-400 text-lg">🏢</span>
                  </div>
                  <div>
                    <p class="font-medium">{{ agence.nomAgence }}</p>
                    <p class="text-xs text-gray-400">{{ agence.email }}</p>
                  </div>
                </div>
                <span 
                  class="px-3 py-1 rounded-full text-xs font-medium"
                  :class="{
                    'bg-orange-500/20 text-orange-400': agence.status === 'PENDING',
                    'bg-green-500/20 text-green-400': agence.status === 'APPROVED',
                    'bg-red-500/20 text-red-400': agence.status === 'REJECTED',
                    'bg-gray-500/20 text-gray-400': agence.status === 'SUSPENDED'
                  }"
                >
                  {{ getStatusLabel(agence.status) }}
                </span>
              </div>
            </div>
          </div>

          <!-- Actions Rapides -->
          <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
            <h3 class="text-lg font-semibold mb-4">Actions Rapides</h3>
            <div class="grid grid-cols-2 gap-3">
              <button @click="currentView = 'agences'" class="p-4 bg-blue-500/10 hover:bg-blue-500/20 border border-blue-500/30 rounded-xl transition text-left">
                <div class="text-2xl mb-2">🏢</div>
                <div class="font-semibold text-sm">Gérer Agences</div>
                <div class="text-xs text-gray-400">{{ stats.agencesPending }} en attente</div>
              </button>
              <button @click="currentView = 'utilisateurs'" class="p-4 bg-purple-500/10 hover:bg-purple-500/20 border border-purple-500/30 rounded-xl transition text-left">
                <div class="text-2xl mb-2">👥</div>
                <div class="font-semibold text-sm">Utilisateurs</div>
                <div class="text-xs text-gray-400">{{ stats.totalUtilisateurs }} comptes</div>
              </button>
              <button @click="currentView = 'stats'" class="p-4 bg-green-500/10 hover:bg-green-500/20 border border-green-500/30 rounded-xl transition text-left">
                <div class="text-2xl mb-2">📊</div>
                <div class="font-semibold text-sm">Rapports</div>
                <div class="text-xs text-gray-400">Voir statistiques</div>
              </button>
              <button class="p-4 bg-orange-500/10 hover:bg-orange-500/20 border border-orange-500/30 rounded-xl transition text-left">
                <div class="text-2xl mb-2">⚙️</div>
                <div class="font-semibold text-sm">Paramètres</div>
                <div class="text-xs text-gray-400">Configuration</div>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Agences View -->
      <div v-if="currentView === 'agences'">
        <!-- Filters -->
        <div class="bg-[#1b1e2e] rounded-2xl p-4 border border-gray-800 mb-6">
          <div class="flex flex-wrap gap-3">
            <button 
              @click="agenceFilter = 'ALL'"
              :class="agenceFilter === 'ALL' ? 'bg-blue-500 text-white' : 'bg-gray-800 text-gray-400'"
              class="px-4 py-2 rounded-lg font-medium transition"
            >
              Toutes ({{ stats.totalAgences }})
            </button>
            <button 
              @click="agenceFilter = 'PENDING'"
              :class="agenceFilter === 'PENDING' ? 'bg-orange-500 text-white' : 'bg-gray-800 text-gray-400'"
              class="px-4 py-2 rounded-lg font-medium transition"
            >
              En Attente ({{ stats.agencesPending }})
            </button>
            <button 
              @click="agenceFilter = 'APPROVED'"
              :class="agenceFilter === 'APPROVED' ? 'bg-green-500 text-white' : 'bg-gray-800 text-gray-400'"
              class="px-4 py-2 rounded-lg font-medium transition"
            >
              Approuvées ({{ stats.agencesApproved }})
            </button>
            <button 
              @click="agenceFilter = 'REJECTED'"
              :class="agenceFilter === 'REJECTED' ? 'bg-red-500 text-white' : 'bg-gray-800 text-gray-400'"
              class="px-4 py-2 rounded-lg font-medium transition"
            >
              Refusées ({{ stats.agencesRejected }})
            </button>
            <button 
              @click="agenceFilter = 'SUSPENDED'"
              :class="agenceFilter === 'SUSPENDED' ? 'bg-gray-600 text-white' : 'bg-gray-800 text-gray-400'"
              class="px-4 py-2 rounded-lg font-medium transition"
            >
              Suspendues ({{ stats.agencesSuspended }})
            </button>
          </div>
        </div>

        <!-- Agences Table -->
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b border-gray-800">
                  <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Agence</th>
                  <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Contact</th>
                  <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Statut</th>
                  <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Date</th>
                  <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Stats</th>
                  <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="agence in filteredAgences" 
                  :key="agence.id"
                  class="border-b border-gray-800/50 hover:bg-gray-800/30 transition"
                >
                  <td class="py-4 px-4">
                    <div class="flex items-center gap-3">
                      <div class="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center">
                        <span class="text-blue-400">🏢</span>
                      </div>
                      <div>
                        <p class="font-medium">{{ agence.nomAgence }}</p>
                        <p class="text-xs text-gray-400">ID: {{ agence.id }}</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-4">
                    <div>
                      <p class="text-sm">{{ agence.nom }}</p>
                      <p class="text-xs text-gray-400">{{ agence.email }}</p>
                      <p class="text-xs text-gray-400">{{ agence.telephone }}</p>
                    </div>
                  </td>
                  <td class="py-4 px-4">
                    <span 
                      class="px-3 py-1 rounded-full text-sm font-medium"
                      :class="{
                        'bg-orange-500/20 text-orange-400': agence.status === 'PENDING',
                        'bg-green-500/20 text-green-400': agence.status === 'APPROVED',
                        'bg-red-500/20 text-red-400': agence.status === 'REJECTED',
                        'bg-gray-500/20 text-gray-400': agence.status === 'SUSPENDED'
                      }"
                    >
                      {{ getStatusLabel(agence.status) }}
                    </span>
                  </td>
                  <td class="py-4 px-4 text-gray-400 text-sm">
                    {{ agence.date }}
                  </td>
                  <td class="py-4 px-4">
                    <div class="flex gap-2 text-xs">
                      <span class="px-2 py-1 bg-purple-500/20 text-purple-400 rounded">{{ agence.pelerins }} pèlerins</span>
                      <span class="px-2 py-1 bg-blue-500/20 text-blue-400 rounded">{{ agence.groupes }} groupes</span>
                    </div>
                  </td>
                  <td class="py-4 px-4">
                    <div class="flex gap-2">
                      <button 
                        v-if="agence.status === 'PENDING'"
                        @click="openApproveModal(agence)"
                        class="p-2 bg-green-500/20 text-green-400 rounded-lg hover:bg-green-500/30 transition"
                        title="Approuver"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                      </button>
                      <button 
                        v-if="agence.status === 'PENDING'"
                        @click="openRejectModal(agence)"
                        class="p-2 bg-red-500/20 text-red-400 rounded-lg hover:bg-red-500/30 transition"
                        title="Refuser"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                      </button>
                      <button 
                        v-if="agence.status === 'APPROVED'"
                        @click="openSuspendModal(agence)"
                        class="p-2 bg-gray-500/20 text-gray-400 rounded-lg hover:bg-gray-500/30 transition"
                        title="Suspendre"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"></path>
                        </svg>
                      </button>
                      <button 
                        class="p-2 bg-blue-500/20 text-blue-400 rounded-lg hover:bg-blue-500/30 transition"
                        title="Détails"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
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

      <!-- Utilisateurs View -->
      <div v-if="currentView === 'utilisateurs'">
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <p class="text-gray-400 text-center py-8">Section Utilisateurs - À venir</p>
        </div>
      </div>

      <!-- Stats View -->
      <div v-if="currentView === 'stats'">
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <p class="text-gray-400 text-center py-8">Section Statistiques - À venir</p>
        </div>
      </div>
    </main>

    <!-- Modal Approve -->
    <div v-if="showApproveModal" class="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center z-50 p-4" @click.self="closeModals">
      <div class="bg-[#1b1e2e] rounded-2xl max-w-md w-full p-6 border border-gray-800">
        <h3 class="text-xl font-bold mb-4">Approuver l'agence</h3>
        <p class="text-gray-400 mb-6">
          Êtes-vous sûr de vouloir approuver l'agence <strong class="text-white">{{ selectedAgence?.nomAgence }}</strong> ?
        </p>
        <p class="text-sm text-gray-500 mb-6">
          ✅ Le compte sera activé<br>
          ✅ Un email de confirmation sera envoyé<br>
          ✅ L'agence pourra se connecter
        </p>
        <div class="flex gap-3">
          <button @click="closeModals" class="flex-1 px-4 py-3 bg-gray-800 hover:bg-gray-700 rounded-lg font-medium transition">
            Annuler
          </button>
          <button @click="approveAgence" class="flex-1 px-4 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg font-medium transition">
            Approuver
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Reject -->
    <div v-if="showRejectModal" class="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center z-50 p-4" @click.self="closeModals">
      <div class="bg-[#1b1e2e] rounded-2xl max-w-md w-full p-6 border border-gray-800">
        <h3 class="text-xl font-bold mb-4">Refuser l'agence</h3>
        <p class="text-gray-400 mb-4">
          Agence : <strong class="text-white">{{ selectedAgence?.nomAgence }}</strong>
        </p>
        <div class="mb-6">
          <label class="block text-sm font-semibold text-gray-300 mb-2">Raison du refus *</label>
          <textarea 
            v-model="rejectReason" 
            rows="4" 
            class="w-full px-4 py-3 rounded-lg bg-black border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-red-500"
            placeholder="Expliquez pourquoi cette agence est refusée..."
          ></textarea>
        </div>
        <div class="flex gap-3">
          <button @click="closeModals" class="flex-1 px-4 py-3 bg-gray-800 hover:bg-gray-700 rounded-lg font-medium transition">
            Annuler
          </button>
          <button @click="rejectAgence" :disabled="!rejectReason || rejectReason.length < 10" class="flex-1 px-4 py-3 bg-red-500 hover:bg-red-600 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-lg font-medium transition">
            Refuser
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Suspend -->
    <div v-if="showSuspendModal" class="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center z-50 p-4" @click.self="closeModals">
      <div class="bg-[#1b1e2e] rounded-2xl max-w-md w-full p-6 border border-gray-800">
        <h3 class="text-xl font-bold mb-4">Suspendre l'agence</h3>
        <p class="text-gray-400 mb-6">
          Êtes-vous sûr de vouloir suspendre l'agence <strong class="text-white">{{ selectedAgence?.nomAgence }}</strong> ?
        </p>
        <p class="text-sm text-gray-500 mb-6">
          ⚠️ Le compte sera désactivé<br>
          ⚠️ L'agence ne pourra plus se connecter<br>
          ⚠️ Les pèlerins de cette agence ne seront pas affectés
        </p>
        <div class="flex gap-3">
          <button @click="closeModals" class="flex-1 px-4 py-3 bg-gray-800 hover:bg-gray-700 rounded-lg font-medium transition">
            Annuler
          </button>
          <button @click="suspendAgence" class="flex-1 px-4 py-3 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium transition">
            Suspendre
          </button>
        </div>
      </div>
    </div>

    <!-- Toast -->
    <div v-if="showToast" class="fixed bottom-8 right-8 px-6 py-4 rounded-xl shadow-2xl flex items-center gap-3 z-50"
         :class="{
           'bg-green-500 text-white': toastType === 'success',
           'bg-red-500 text-white': toastType === 'error'
         }">
      <svg v-if="toastType === 'success'" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
      </svg>
      <div>
        <div class="font-bold">{{ toastMessage }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router'

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const handleLogout = () => {
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('user')
  router.push('/')
}
// État local avec données mockées
const currentView = ref('dashboard');
const agenceFilter = ref('ALL');
const selectedAgence = ref(null);
const showApproveModal = ref(false);
const showRejectModal = ref(false);
const showSuspendModal = ref(false);
const rejectReason = ref('');
const showToast = ref(false);
const toastMessage = ref('');
const toastType = ref('success');

// Données mockées
const stats = ref({
  totalAgences: 12,
  agencesPending: 3,
  agencesApproved: 7,
  agencesRejected: 1,
  agencesSuspended: 1,
  totalUtilisateurs: 156,
  utilisateursActifs: 142,
  totalPelerins: 245,
  totalGroupes: 18,
  totalGuides: 12
});

const agences = ref([
  {
    id: '1a2b3c4d',
    nomAgence: 'Agence Al-Baraka',
    nom: 'Hassan Mohamed',
    email: 'contact@albaraka.com',
    telephone: '+33 6 12 34 56 78',
    status: 'PENDING',
    date: '2 Mar 2025',
    pelerins: 0,
    groupes: 0
  },
  {
    id: '5e6f7g8h',
    nomAgence: 'Voyages Al-Firdaws',
    nom: 'Fatima Benali',
    email: 'info@alfirdaws.com',
    telephone: '+33 6 23 45 67 89',
    status: 'PENDING',
    date: '1 Mar 2025',
    pelerins: 0,
    groupes: 0
  },
  {
    id: '9i0j1k2l',
    nomAgence: 'Hajj Services Plus',
    nom: 'Ahmed Mansouri',
    email: 'contact@hajjservices.com',
    telephone: '+33 6 34 56 78 90',
    status: 'PENDING',
    date: '28 Fév 2025',
    pelerins: 0,
    groupes: 0
  },
  {
    id: '3m4n5o6p',
    nomAgence: 'Al-Rahman Travel',
    nom: 'Omar Belkacem',
    email: 'contact@alrahman.com',
    telephone: '+33 6 45 67 89 01',
    status: 'APPROVED',
    date: '25 Fév 2025',
    pelerins: 52,
    groupes: 3
  },
  {
    id: '7q8r9s0t',
    nomAgence: 'Omra Express',
    nom: 'Aisha Benali',
    email: 'info@omraexpress.com',
    telephone: '+33 6 56 78 90 12',
    status: 'APPROVED',
    date: '20 Fév 2025',
    pelerins: 68,
    groupes: 4
  },
  {
    id: '1u2v3w4x',
    nomAgence: 'Mecca Tours',
    nom: 'Youssef Ahmed',
    email: 'contact@meccatours.com',
    telephone: '+33 6 67 89 01 23',
    status: 'APPROVED',
    date: '15 Fév 2025',
    pelerins: 125,
    groupes: 6
  },
  {
    id: '5y6z7a8b',
    nomAgence: 'Hajj & Umrah France',
    nom: 'Salima Trabelsi',
    email: 'contact@hajjumrahfr.com',
    telephone: '+33 6 78 90 12 34',
    status: 'REJECTED',
    date: '10 Fév 2025',
    pelerins: 0,
    groupes: 0
  },
  {
    id: '9c0d1e2f',
    nomAgence: 'Paradise Voyages',
    nom: 'Karim Zidane',
    email: 'info@paradise.com',
    telephone: '+33 6 89 01 23 45',
    status: 'SUSPENDED',
    date: '5 Fév 2025',
    pelerins: 0,
    groupes: 0
  }
]);

// Computed
const recentAgences = computed(() => agences.value.slice(0, 5));

const filteredAgences = computed(() => {
  if (agenceFilter.value === 'ALL') return agences.value;
  return agences.value.filter(a => a.status === agenceFilter.value);
});

// Méthodes
function getViewTitle() {
  const titles = {
    dashboard: 'Vue d\'ensemble',
    agences: 'Gestion des Agences',
    utilisateurs: 'Gestion des Utilisateurs',
    stats: 'Statistiques Globales'
  };
  return titles[currentView.value];
}

function getViewSubtitle() {
  const subtitles = {
    dashboard: 'Tableau de bord administrateur',
    agences: 'Approuver, refuser ou suspendre des agences',
    utilisateurs: 'Gérer tous les comptes utilisateurs',
    stats: 'Analyse et rapports détaillés'
  };
  return subtitles[currentView.value];
}

function getStatusLabel(status) {
  const labels = {
    PENDING: 'En attente',
    APPROVED: 'Approuvée',
    REJECTED: 'Refusée',
    SUSPENDED: 'Suspendue'
  };
  return labels[status];
}

function openApproveModal(agence) {
  selectedAgence.value = agence;
  showApproveModal.value = true;
}

function openRejectModal(agence) {
  selectedAgence.value = agence;
  showRejectModal.value = true;
  rejectReason.value = '';
}

function openSuspendModal(agence) {
  selectedAgence.value = agence;
  showSuspendModal.value = true;
}

function closeModals() {
  showApproveModal.value = false;
  showRejectModal.value = false;
  showSuspendModal.value = false;
  selectedAgence.value = null;
  rejectReason.value = '';
}

function approveAgence() {
  // Simuler l'approbation
  const agence = agences.value.find(a => a.id === selectedAgence.value.id);
  if (agence) {
    agence.status = 'APPROVED';
    stats.value.agencesPending--;
    stats.value.agencesApproved++;
  }
  toast('Agence approuvée avec succès', 'success');
  closeModals();
}

function rejectAgence() {
  // Simuler le refus
  const agence = agences.value.find(a => a.id === selectedAgence.value.id);
  if (agence) {
    agence.status = 'REJECTED';
    stats.value.agencesPending--;
    stats.value.agencesRejected++;
  }
  toast('Agence refusée', 'success');
  closeModals();
}

function suspendAgence() {
  // Simuler la suspension
  const agence = agences.value.find(a => a.id === selectedAgence.value.id);
  if (agence) {
    agence.status = 'SUSPENDED';
    stats.value.agencesApproved--;
    stats.value.agencesSuspended++;
  }
  toast('Agence suspendue', 'success');
  closeModals();
}

function toast(message, type = 'success') {
  toastMessage.value = message;
  toastType.value = type;
  showToast.value = true;
  setTimeout(() => {
    showToast.value = false;
  }, 3000);
}
</script>