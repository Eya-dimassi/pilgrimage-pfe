<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#0d0f1a] to-[#1b1e2e]">

    <div class="w-[400px] bg-[#1b1e2e]/90 p-10 rounded-2xl shadow-2xl text-center text-white">

      <div class="text-5xl mb-5">
        🕌
      </div>

      <h1 class="text-2xl font-semibold mb-1">Hajj & Umrah</h1>
      <p class="text-gray-400 text-sm mb-8">
        Connexion à votre espace spirituel
      </p>

      <form @submit.prevent="handleLogin" class="space-y-5">

        <!-- Email -->
        <div class="text-left">
          <label class="text-sm text-gray-300">Email</label>
          <input
            type="email"
            v-model="email"
            placeholder="exemple@email.com"
            required
            class="w-full mt-2 px-4 py-3 rounded-lg bg-[#252a3f] text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
          />
        </div>

        <!-- Password -->
<div class="text-left">
  <label class="text-sm text-gray-300">Mot de passe</label>
  <div class="relative mt-2">
    <input
      :type="showPassword ? 'text' : 'password'"
      v-model="password"
      required
      class="w-full px-4 py-3 rounded-lg bg-[#252a3f] text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
    />
    <button
      type="button"
      @click="showPassword = !showPassword"
      class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-yellow-500"
    >
      <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none"
        viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M2.458 12C3.732 7.943 7.523 5 12 5c4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
      </svg>
      <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none"
        viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M13.875 18.825A10.05 10.05 0 0112 19c-4.477 0-8.268-2.943-9.542-7a10.057 10.057 0 012.651-3.364M9.879 9.879a3 3 0 014.242 4.242M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3l18 18" />
      </svg>
    </button>
  </div>
</div>
<p v-if="errorMessage" class="text-red-400 text-sm text-center">
          {{ errorMessage }}
        </p>
        <!-- Button -->
        <button
  type="submit"
  :disabled="loading"
  class="w-full py-3 rounded-xl bg-yellow-600 hover:bg-yellow-400 text-black font-bold transition transform hover:-translate-y-1 disabled:opacity-50 disabled:cursor-not-allowed"
>
  {{ loading ? 'Connexion...' : 'Se connecter' }}
</button>

        <router-link
          to="/forgot-password"
          class="block mt-4 text-yellow-500 hover:underline text-sm"
        >
          Mot de passe oublié ?
        </router-link>

      </form>

    </div>

  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { login } from '@/services/auth.service'

const router = useRouter()
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const errorMessage = ref('')
const loading = ref(false)

const handleLogin = async () => {
  try {
    loading.value = true
    errorMessage.value = ''

    const data = await login(email.value, password.value)

    // save tokens
    localStorage.setItem('accessToken', data.accessToken)
    localStorage.setItem('refreshToken', data.refreshToken)
    localStorage.setItem('user', JSON.stringify(data.utilisateur))

    // redirect based on role
    const role = data.utilisateur.role

    if (role === 'AGENCE') {
      router.push('/dashboard')
    } else if (role === 'SUPER_ADMIN') {
      router.push('/admin')
    } else {
      // guides and pilgrims use the mobile app
      errorMessage.value = 'Ce portail est réservé aux agences et administrateurs'
    }

  } catch (error) {
   
    errorMessage.value = 'Email ou mot de passe incorrect'
  } finally {
    loading.value = false
  }
}
</script>