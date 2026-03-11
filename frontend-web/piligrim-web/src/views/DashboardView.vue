<!--<template>
  <div class="min-h-screen bg-[#0d0f1a] text-white flex flex-col items-center justify-center">
    <div class="text-5xl mb-4">🏢</div>
   <h1 class="text-2xl font-bold mb-2">Tableau de bord Agence</h1>
    <p class="text-gray-400 mb-6">Bienvenue, {{ user?.prenom }} {{ user?.nom }}</p>
    <button 
      @click="handleLogout"
      class="px-6 py-2 bg-yellow-600 hover:bg-yellow-400 text-black font-bold rounded-lg transition"
    >
      Se déconnecter
    </button>
  </div>
</template>
-->
<template>
  <div class="min-h-screen bg-gradient-to-br from-[#0d0f1a] to-[#1b1e2e] text-white">
    <!-- Sidebar -->
    <aside class="fixed left-0 top-0 h-screen w-64 bg-[#0d0f1a] border-r border-gray-800 overflow-y-auto">
      <!-- Logo -->
      <div class="p-6 border-b border-gray-800">
        <h1 class="text-xl font-bold text-white flex items-center gap-2">
          <span class="text-2xl">🕌</span>
          HAJJ&Umrah
        </h1>
        <p class="text-xs text-gray-500 mt-1">Agence Dashboard</p>
      </div>

      <!-- Menu -->
      <nav class="p-4 space-y-2">
        <div class="mb-4">
          <p class="text-xs text-gray-500 uppercase font-semibold mb-2 px-3">Navigation</p>
          
          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-blue-600/20 text-blue-400 hover:bg-blue-600/30 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
            </svg>
            <span class="font-medium">Vue d'ensemble</span>
          </a>

          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-gray-800/50 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
            <span>Mes Pèlerins</span>
          </a>

          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-gray-800/50 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
            <span>Mes Groupes</span>
          </a>

          <router-link 
      to="/agence/guides" 
      class="nav-link"
      active-class="active"
    >
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z">
        </path>
      </svg>
      <span>Mes Guides</span>
    </router-link>

          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-gray-800/50 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
            </svg>
            <span>Planning Hajj</span>
          </a>

          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-gray-800/50 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
            <span>Localisation GPS</span>
          </a>
        </div>

        <div>
          <p class="text-xs text-gray-500 uppercase font-semibold mb-2 px-3">Paramètres</p>
          
          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-gray-800/50 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path>
            </svg>
            <span>Alertes</span>
            <span class="ml-auto bg-red-500 text-white text-xs px-2 py-0.5 rounded-full">3</span>
          </a>

          <a href="#" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-gray-800/50 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
            <span>Configuration</span>
          </a>
        </div>
      </nav>
    </aside>

    <!-- Main Content -->
    <main class="ml-64 p-6">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h2 class="text-2xl font-bold">Vue d'ensemble</h2>
          <p class="text-gray-400 text-sm mt-1">Tableau de bord de gestion</p>
        </div>
        <div class="flex items-center gap-4">
          <button class="p-2 hover:bg-gray-800 rounded-lg transition relative">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path>
            </svg>
            <span class="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
          </button>
          <div class="flex items-center gap-3">
            <div>
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
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <!-- Total Pèlerins -->
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-start justify-between mb-4">
            <div class="p-3 bg-blue-500/20 rounded-xl">
              <svg class="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
              </svg>
            </div>
            <div class="flex items-center gap-1 text-green-400 text-sm">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
              </svg>
              <span>+12%</span>
            </div>
          </div>
          <div>
            <p class="text-gray-400 text-sm mb-1">Total Pèlerins</p>
            <p class="text-3xl font-bold">245</p>
            <p class="text-xs text-gray-500 mt-2">Saison 2024-2025</p>
          </div>
        </div>

        <!-- Groupes Actifs -->
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-start justify-between mb-4">
            <div class="p-3 bg-purple-500/20 rounded-xl">
              <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"></path>
              </svg>
            </div>
            <div class="flex items-center gap-1 text-blue-400 text-sm">
              <span>5 actifs</span>
            </div>
          </div>
          <div>
            <p class="text-gray-400 text-sm mb-1">Groupes</p>
            <p class="text-3xl font-bold">12</p>
            <p class="text-xs text-gray-500 mt-2">7 en préparation</p>
          </div>
        </div>

        <!-- Guides -->
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-start justify-between mb-4">
            <div class="p-3 bg-green-500/20 rounded-xl">
              <svg class="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>
              </svg>
            </div>
            <div class="flex items-center gap-1 text-green-400 text-sm">
              <span>8 disponibles</span>
            </div>
          </div>
          <div>
            <p class="text-gray-400 text-sm mb-1">Guides</p>
            <p class="text-3xl font-bold">8</p>
            <p class="text-xs text-gray-500 mt-2">Tous certifiés</p>
          </div>
        </div>

        <!-- Alertes -->
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-start justify-between mb-4">
            <div class="p-3 bg-red-500/20 rounded-xl">
              <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
              </svg>
            </div>
            <div class="flex items-center gap-1 text-red-400 text-sm">
              <span>3 urgentes</span>
            </div>
          </div>
          <div>
            <p class="text-gray-400 text-sm mb-1">Alertes</p>
            <p class="text-3xl font-bold">3</p>
            <p class="text-xs text-gray-500 mt-2">À traiter aujourd'hui</p>
          </div>
        </div>
      </div>

      <!-- Charts Row -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <!-- Répartition Pèlerins par Groupe -->
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-semibold">Répartition par Groupe</h3>
          </div>
          
          <div class="flex items-center justify-center mb-6">
            <div class="relative w-48 h-48">
              <svg viewBox="0 0 100 100" class="transform -rotate-90">
                <circle cx="50" cy="50" r="40" fill="none" stroke="#10B981" stroke-width="20" stroke-dasharray="75 251.2" />
                <circle cx="50" cy="50" r="40" fill="none" stroke="#FCD34D" stroke-width="20" stroke-dasharray="62.8 251.2" stroke-dashoffset="-75" />
                <circle cx="50" cy="50" r="40" fill="none" stroke="#3B82F6" stroke-width="20" stroke-dasharray="50.24 251.2" stroke-dashoffset="-137.8" />
                <circle cx="50" cy="50" r="40" fill="none" stroke="#F97316" stroke-width="20" stroke-dasharray="37.68 251.2" stroke-dashoffset="-188.04" />
                <circle cx="50" cy="50" r="40" fill="none" stroke="#A78BFA" stroke-width="20" stroke-dasharray="25.12 251.2" stroke-dashoffset="-225.72" />
              </svg>
              <div class="absolute inset-0 flex flex-col items-center justify-center">
                <p class="text-3xl font-bold">245</p>
                <p class="text-xs text-gray-400">Pèlerins</p>
              </div>
            </div>
          </div>

          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                <span class="text-sm text-gray-400">Al-Baraka</span>
              </div>
              <span class="text-sm font-semibold">52</span>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="w-3 h-3 bg-yellow-400 rounded-full"></div>
                <span class="text-sm text-gray-400">Al-Firdaws</span>
              </div>
              <span class="text-sm font-semibold">48</span>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                <span class="text-sm text-gray-400">Al-Rahman</span>
              </div>
              <span class="text-sm font-semibold">45</span>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="w-3 h-3 bg-orange-500 rounded-full"></div>
                <span class="text-sm text-gray-400">Al-Karim</span>
              </div>
              <span class="text-sm font-semibold">38</span>
            </div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="w-3 h-3 bg-purple-400 rounded-full"></div>
                <span class="text-sm text-gray-400">Al-Nur</span>
              </div>
              <span class="text-sm font-semibold">62</span>
            </div>
          </div>
        </div>

        <!-- Progression des Étapes -->
        <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800 lg:col-span-2">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-semibold">Progression des Étapes Hajj</h3>
            <select class="bg-[#252a3f] border border-gray-700 rounded-lg px-3 py-1.5 text-sm">
              <option>Groupe Al-Baraka</option>
              <option>Groupe Al-Firdaws</option>
              <option>Groupe Al-Rahman</option>
            </select>
          </div>

          <div class="space-y-4">
            <div>
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm text-gray-400">1. Ihram</span>
                <span class="text-sm font-semibold text-green-400">✓ Complété</span>
              </div>
              <div class="w-full bg-gray-700 rounded-full h-2">
                <div class="bg-green-500 h-2 rounded-full" style="width: 100%"></div>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm text-gray-400">2. Arrivée à la Mecque</span>
                <span class="text-sm font-semibold text-green-400">✓ Complété</span>
              </div>
              <div class="w-full bg-gray-700 rounded-full h-2">
                <div class="bg-green-500 h-2 rounded-full" style="width: 100%"></div>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm text-gray-400">3. Tawaf Al-Qudum</span>
                <span class="text-sm font-semibold text-green-400">✓ Complété</span>
              </div>
              <div class="w-full bg-gray-700 rounded-full h-2">
                <div class="bg-green-500 h-2 rounded-full" style="width: 100%"></div>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm text-gray-400">4. Sa'i</span>
                <span class="text-sm font-semibold text-blue-400">En cours (78%)</span>
              </div>
              <div class="w-full bg-gray-700 rounded-full h-2">
                <div class="bg-blue-500 h-2 rounded-full" style="width: 78%"></div>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm text-gray-400">5. Jour d'Arafat</span>
                <span class="text-sm font-semibold text-gray-500">À venir</span>
              </div>
              <div class="w-full bg-gray-700 rounded-full h-2">
                <div class="bg-gray-600 h-2 rounded-full" style="width: 0%"></div>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm text-gray-400">6. Muzdalifa</span>
                <span class="text-sm font-semibold text-gray-500">À venir</span>
              </div>
              <div class="w-full bg-gray-700 rounded-full h-2">
                <div class="bg-gray-600 h-2 rounded-full" style="width: 0%"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Alertes Section -->
      <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800 mb-6">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-lg font-semibold flex items-center gap-2">
            <span class="w-2 h-2 bg-red-500 rounded-full animate-pulse"></span>
            Alertes Actives
          </h3>
          <a href="#" class="text-blue-400 text-sm hover:underline">Voir toutes →</a>
        </div>

        <div class="space-y-3">
          <div class="bg-red-500/10 border border-red-500/30 rounded-xl p-4 flex items-start gap-4">
            <div class="p-2 bg-red-500/20 rounded-lg">
              <svg class="w-5 h-5 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
              </svg>
            </div>
            <div class="flex-1">
              <div class="flex items-start justify-between mb-1">
                <h4 class="font-semibold text-red-400">Pèlerin éloigné du groupe</h4>
                <span class="text-xs text-gray-400">Il y a 5 min</span>
              </div>
              <p class="text-sm text-gray-300">Ahmed Mansouri (Groupe Al-Baraka) s'est éloigné de plus de 500m du groupe.</p>
              <div class="flex gap-2 mt-3">
                <button class="px-3 py-1.5 bg-red-500 text-white rounded-lg text-sm font-medium hover:bg-red-600 transition">
                  Localiser
                </button>
                <button class="px-3 py-1.5 bg-gray-700 text-white rounded-lg text-sm hover:bg-gray-600 transition">
                  Contacter
                </button>
              </div>
            </div>
          </div>

          <div class="bg-yellow-500/10 border border-yellow-500/30 rounded-xl p-4 flex items-start gap-4">
            <div class="p-2 bg-yellow-500/20 rounded-lg">
              <svg class="w-5 h-5 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <div class="flex-1">
              <div class="flex items-start justify-between mb-1">
                <h4 class="font-semibold text-yellow-400">Documents manquants</h4>
                <span class="text-xs text-gray-400">Il y a 2h</span>
              </div>
              <p class="text-sm text-gray-300">3 pèlerins n'ont pas encore fourni leurs documents de voyage.</p>
              <button class="mt-3 px-3 py-1.5 bg-yellow-500 text-gray-900 rounded-lg text-sm font-medium hover:bg-yellow-400 transition">
                Voir les pèlerins
              </button>
            </div>
          </div>

          <div class="bg-blue-500/10 border border-blue-500/30 rounded-xl p-4 flex items-start gap-4">
            <div class="p-2 bg-blue-500/20 rounded-lg">
              <svg class="w-5 h-5 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
              </svg>
            </div>
            <div class="flex-1">
              <div class="flex items-start justify-between mb-1">
                <h4 class="font-semibold text-blue-400">Rappel : Départ Groupe Al-Firdaws</h4>
                <span class="text-xs text-gray-400">Demain</span>
              </div>
              <p class="text-sm text-gray-300">Le groupe Al-Firdaws part demain à 14h00. 48 pèlerins confirmés.</p>
              <button class="mt-3 px-3 py-1.5 bg-blue-500 text-white rounded-lg text-sm font-medium hover:bg-blue-600 transition">
                Voir le planning
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Liste Récente -->
      <div class="bg-[#1b1e2e] rounded-2xl p-6 border border-gray-800">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-lg font-semibold">Derniers Pèlerins Ajoutés</h3>
          <a href="#" class="text-blue-400 text-sm hover:underline">Voir tous les pèlerins →</a>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-gray-800">
                <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Pèlerin</th>
                <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Groupe</th>
                <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Guide</th>
                <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Date Départ</th>
                <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Statut</th>
                <th class="text-left py-3 px-4 text-sm font-semibold text-gray-400">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr class="border-b border-gray-800/50 hover:bg-gray-800/30 transition">
                <td class="py-4 px-4">
                  <div class="flex items-center gap-3">
                    <img src="https://ui-avatars.com/api/?name=Ahmed+Mansouri&background=4F46E5&color=fff" class="w-10 h-10 rounded-full" alt="">
                    <div>
                      <p class="font-medium">Ahmed Mansouri</p>
                      <p class="text-xs text-gray-400">ahmed.m@email.com</p>
                    </div>
                  </div>
                </td>
                <td class="py-4 px-4 text-gray-400">Al-Baraka</td>
                <td class="py-4 px-4 text-gray-400">Hassan Ali</td>
                <td class="py-4 px-4 text-gray-400">15 Avr 2024</td>
                <td class="py-4 px-4">
                  <span class="px-3 py-1 bg-green-500/20 text-green-400 rounded-full text-sm font-medium">Actif</span>
                </td>
                <td class="py-4 px-4">
                  <button class="p-2 hover:bg-gray-700 rounded-lg transition">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                    </svg>
                  </button>
                </td>
              </tr>
              <tr class="border-b border-gray-800/50 hover:bg-gray-800/30 transition">
                <td class="py-4 px-4">
                  <div class="flex items-center gap-3">
                    <img src="https://ui-avatars.com/api/?name=Fatima+Zahra&background=10B981&color=fff" class="w-10 h-10 rounded-full" alt="">
                    <div>
                      <p class="font-medium">Fatima Zahra</p>
                      <p class="text-xs text-gray-400">fatima.z@email.com</p>
                    </div>
                  </div>
                </td>
                <td class="py-4 px-4 text-gray-400">Al-Firdaws</td>
                <td class="py-4 px-4 text-gray-400">Amina Benali</td>
                <td class="py-4 px-4 text-gray-400">15 Avr 2024</td>
                <td class="py-4 px-4">
                  <span class="px-3 py-1 bg-green-500/20 text-green-400 rounded-full text-sm font-medium">Actif</span>
                </td>
                <td class="py-4 px-4">
                  <button class="p-2 hover:bg-gray-700 rounded-lg transition">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                    </svg>
                  </button>
                </td>
              </tr>
              <tr class="border-b border-gray-800/50 hover:bg-gray-800/30 transition">
                <td class="py-4 px-4">
                  <div class="flex items-center gap-3">
                    <img src="https://ui-avatars.com/api/?name=Omar+Belkacem&background=F59E0B&color=fff" class="w-10 h-10 rounded-full" alt="">
                    <div>
                      <p class="font-medium">Omar Belkacem</p>
                      <p class="text-xs text-gray-400">omar.b@email.com</p>
                    </div>
                  </div>
                </td>
                <td class="py-4 px-4 text-gray-400">Al-Rahman</td>
                <td class="py-4 px-4 text-gray-400">Youssef Ahmed</td>
                <td class="py-4 px-4 text-gray-400">20 Avr 2024</td>
                <td class="py-4 px-4">
                  <span class="px-3 py-1 bg-yellow-500/20 text-yellow-400 rounded-full text-sm font-medium">En préparation</span>
                </td>
                <td class="py-4 px-4">
                  <button class="p-2 hover:bg-gray-700 rounded-lg transition">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                    </svg>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router'

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const handleLogout = () => {
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('user')
  router.push('/')
}
const stats = ref({
  totalPelerins: 245,
  groupesActifs: 12,
  totalGuides: 8,
  alertes: 3
});
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>