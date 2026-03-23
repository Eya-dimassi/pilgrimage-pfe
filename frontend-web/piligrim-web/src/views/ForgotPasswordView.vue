<template>
  <div class="fp-root">
    <div class="fp-card">
      <div class="fp-logo">
        <div>
          <div class="fp-logo-name">SmartHajj</div>
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
          {{ loading ? 'Envoi...' : 'Envoyer le lien' }}
        </button>
        <button class="fp-link" type="button" @click="router.push('/')">Retour a la connexion</button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const router = useRouter()

const email = ref('')
const loading = ref(false)
const success = ref(false)
const error = ref('')

async function handleSubmit() {
  loading.value = true
  error.value = ''

  try {
    await axios.post(
      `${import.meta.env.VITE_API_URL || 'http://localhost:3000'}/auth/forgot-password`,
      { email: email.value }
    )
    success.value = true
  } catch (err) {
    error.value = err.response?.data?.message || 'Une erreur est survenue.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=DM+Sans:wght@400;500&display=swap');

.fp-root {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background:
    radial-gradient(circle at top left, rgba(201, 168, 76, 0.14), transparent 30%),
    linear-gradient(160deg, #0d0c09 0%, #16130d 100%);
  font-family: 'DM Sans', sans-serif;
}

.fp-card {
  width: 100%;
  max-width: 440px;
  padding: 40px;
  border-radius: 24px;
  background: rgba(21, 20, 16, 0.96);
  border: 1px solid rgba(201, 168, 76, 0.15);
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.45);
}

.fp-logo {
  margin-bottom: 28px;
}

.fp-logo-name {
  font-family: 'Syne', sans-serif;
  font-size: 18px;
  font-weight: 800;
  color: #c9a84c;
}

.fp-logo-sub {
  margin-top: 4px;
  font-size: 12px;
  color: #86785e;
}

.fp-title {
  margin: 0 0 10px;
  font-family: 'Syne', sans-serif;
  font-size: 28px;
  font-weight: 800;
  color: #f3efe5;
}

.fp-text {
  margin: 0 0 24px;
  color: #b3a894;
  line-height: 1.6;
}

.fp-label {
  display: block;
  margin-bottom: 8px;
  color: #d2c5ae;
  font-size: 13px;
  font-weight: 600;
}

.fp-input {
  width: 100%;
  padding: 14px 16px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
  background: #1d1a14;
  color: #f7f1e6;
  outline: none;
  box-sizing: border-box;
}

.fp-input:focus {
  border-color: #c9a84c;
  box-shadow: 0 0 0 3px rgba(201, 168, 76, 0.12);
}

.fp-error {
  margin: 14px 0 0;
  padding: 10px 12px;
  border-radius: 10px;
  background: rgba(220, 38, 38, 0.12);
  color: #fda4a4;
  font-size: 13px;
}

.fp-btn,
.fp-link {
  width: 100%;
  margin-top: 16px;
  padding: 13px 16px;
  border-radius: 14px;
  font-family: 'DM Sans', sans-serif;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}

.fp-btn {
  border: none;
  background: #c9a84c;
  color: #16120b;
}

.fp-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.fp-link {
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: transparent;
  color: #d6cab6;
}

.fp-state strong {
  color: #f3efe5;
}
</style>
