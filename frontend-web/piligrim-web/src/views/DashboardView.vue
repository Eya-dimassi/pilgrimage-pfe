<template>
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
</script>