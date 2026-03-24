<template>
  <div class="fp-root">
    <div class="fp-card">
      <div class="fp-logo">
        <div>
          <div class="fp-logo-name">{{ brand.name }}</div>
          <div class="fp-logo-sub">Recuperation du mot de passe</div>
        </div>
      </div>

      <div v-if="success" class="fp-state">
        <h1 class="fp-title">Verifiez votre email</h1>
        <p class="fp-text">
          Si un compte existe pour <strong>{{ email }}</strong>, un lien de reinitialisation a ete envoye.
        </p>
        <button class="fp-btn" type="button" @click="router.push('/')">Retour a l'accueil</button>
      </div>

      <form v-else @submit.prevent="handleSubmit">
        <h1 class="fp-title">Mot de passe oublie ?</h1>
        <p class="fp-text">
          Entrez votre email et nous vous enverrons un lien pour definir un nouveau mot de passe.
        </p>

        <label class="fp-label" for="email">Email</label>
        <input
          id="email"
          v-model="email"
          class="fp-input"
          type="email"
          placeholder="exemple@agence.com"
          required
          autocomplete="email"
        />

        <p v-if="error" class="fp-error">{{ error }}</p>

        <button class="fp-btn" type="submit" :disabled="loading">
          {{ loading ? 'Envoi en cours...' : 'Envoyer le lien' }}
        </button>
        <button class="fp-link" type="button" @click="router.push('/')">Retour a la connexion</button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { brand } from '@/content/brand'
import { forgotPassword } from '@/services/auth.service'

const router = useRouter()

const email = ref('')
const loading = ref(false)
const success = ref(false)
const error = ref('')

async function handleSubmit() {
  const normalizedEmail = email.value.trim().toLowerCase()

  if (!normalizedEmail) {
    error.value = 'Veuillez saisir votre email.'
    return
  }

  loading.value = true
  error.value = ''

  try {
    await forgotPassword(normalizedEmail)
    email.value = normalizedEmail
    success.value = true
  } catch (err) {
    error.value = err.response?.data?.message || 'Une erreur est survenue.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped src="@/assets/styles/auth/forgot-password.css"></style>
