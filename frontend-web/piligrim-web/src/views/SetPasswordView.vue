<template>
  <div class="sp-root">
    <div class="sp-card">
      <div class="sp-logo">
        <div>
          <div class="sp-logo-name">SmartHajj</div>
          <div class="sp-logo-sub">Reinitialisation du mot de passe</div>
        </div>
      </div>

      <div v-if="success" class="sp-state">
        <h1 class="sp-title">Mot de passe mis a jour</h1>
        <p class="sp-text">Vous pouvez maintenant vous reconnecter avec votre nouveau mot de passe.</p>
        <button class="sp-btn" type="button" @click="router.push('/')">Retour a la connexion</button>
      </div>

      <div v-else-if="tokenError" class="sp-state">
        <h1 class="sp-title">Lien invalide</h1>
        <p class="sp-text">{{ tokenError }}</p>
        <button class="sp-link" type="button" @click="router.push('/forgot-password')">
          Demander un nouveau lien
        </button>
      </div>

      <form v-else @submit.prevent="handleSubmit">
        <h1 class="sp-title">Definir un nouveau mot de passe</h1>
        <p class="sp-text">Choisissez un mot de passe securise pour finaliser la reinitialisation.</p>

        <label class="sp-label" for="password">Nouveau mot de passe</label>
        <div class="sp-password-wrap">
          <input
            id="password"
            v-model="password"
            class="sp-input"
            :type="showPassword ? 'text' : 'password'"
            placeholder="Minimum 8 caracteres"
            required
          />
          <button class="sp-toggle" type="button" @click="showPassword = !showPassword">
            {{ showPassword ? 'Masquer' : 'Afficher' }}
          </button>
        </div>

        <div v-if="password" class="sp-strength">
          <div class="sp-strength-bar">
            <div class="sp-strength-fill" :style="{ width: `${strengthPct}%`, backgroundColor: strengthColor }"></div>
          </div>
          <span :style="{ color: strengthColor }">{{ strengthLabel }}</span>
        </div>

        <label class="sp-label" for="confirm">Confirmer le mot de passe</label>
        <input
          id="confirm"
          v-model="confirm"
          class="sp-input"
          :class="{ 'sp-input-error': confirm && confirm !== password }"
          :type="showPassword ? 'text' : 'password'"
          placeholder="Repetez le mot de passe"
          required
        />

        <p v-if="error" class="sp-error">{{ error }}</p>

        <button class="sp-btn" type="submit" :disabled="loading || !isValid">
          {{ loading ? 'Mise a jour...' : 'Enregistrer le mot de passe' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import axios from 'axios'

const route = useRoute()
const router = useRouter()

const token = ref(typeof route.query.token === 'string' ? route.query.token : '')
const password = ref('')
const confirm = ref('')
const showPassword = ref(false)
const loading = ref(false)
const success = ref(false)
const error = ref('')
const tokenError = ref(token.value ? '' : 'Le lien de reinitialisation est invalide ou incomplet.')

const strengthPct = computed(() => {
  const value = password.value
  let score = 0

  if (value.length >= 8) score += 25
  if (value.length >= 12) score += 25
  if (/[A-Z]/.test(value)) score += 25
  if (/[0-9!@#$%^&*]/.test(value)) score += 25

  return score
})

const strengthLabel = computed(() => {
  if (strengthPct.value <= 25) return 'Faible'
  if (strengthPct.value <= 50) return 'Moyen'
  if (strengthPct.value <= 75) return 'Bon'
  return 'Fort'
})

const strengthColor = computed(() => {
  if (strengthPct.value <= 25) return '#f87171'
  if (strengthPct.value <= 50) return '#fb923c'
  if (strengthPct.value <= 75) return '#c9a84c'
  return '#4ade80'
})

const isValid = computed(() => (
  token.value &&
  password.value.length >= 8 &&
  password.value === confirm.value
))

async function handleSubmit() {
  if (!token.value) {
    tokenError.value = 'Le lien de reinitialisation est invalide ou incomplet.'
    return
  }

  if (password.value.length < 8) {
    error.value = 'Le mot de passe doit contenir au moins 8 caracteres.'
    return
  }

  if (password.value !== confirm.value) {
    error.value = 'Les mots de passe ne correspondent pas.'
    return
  }

  loading.value = true
  error.value = ''

  try {
    await axios.post(
      `${import.meta.env.VITE_API_URL || 'http://localhost:3000'}/auth/set-password`,
      {
        token: token.value,
        newPassword: password.value,
      }
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

.sp-root {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background:
    radial-gradient(circle at top right, rgba(201, 168, 76, 0.14), transparent 32%),
    linear-gradient(160deg, #0d0c09 0%, #16130d 100%);
  font-family: 'DM Sans', sans-serif;
}

.sp-card {
  width: 100%;
  max-width: 460px;
  padding: 40px;
  border-radius: 24px;
  background: rgba(21, 20, 16, 0.96);
  border: 1px solid rgba(201, 168, 76, 0.15);
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.45);
}

.sp-logo {
  margin-bottom: 28px;
}

.sp-logo-name {
  font-family: 'Syne', sans-serif;
  font-size: 18px;
  font-weight: 800;
  color: #c9a84c;
}

.sp-logo-sub {
  margin-top: 4px;
  font-size: 12px;
  color: #86785e;
}

.sp-title {
  margin: 0 0 10px;
  font-family: 'Syne', sans-serif;
  font-size: 28px;
  font-weight: 800;
  color: #f3efe5;
}

.sp-text {
  margin: 0 0 24px;
  color: #b3a894;
  line-height: 1.6;
}

.sp-label {
  display: block;
  margin: 18px 0 8px;
  color: #d2c5ae;
  font-size: 13px;
  font-weight: 600;
}

.sp-password-wrap {
  position: relative;
}

.sp-input {
  width: 100%;
  padding: 14px 16px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
  background: #1d1a14;
  color: #f7f1e6;
  outline: none;
  box-sizing: border-box;
}

.sp-input:focus {
  border-color: #c9a84c;
  box-shadow: 0 0 0 3px rgba(201, 168, 76, 0.12);
}

.sp-input-error {
  border-color: #f87171;
}

.sp-toggle {
  position: absolute;
  top: 50%;
  right: 14px;
  transform: translateY(-50%);
  border: none;
  background: transparent;
  color: #c9a84c;
  cursor: pointer;
}

.sp-strength {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
}

.sp-strength-bar {
  flex: 1;
  height: 5px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.08);
  overflow: hidden;
}

.sp-strength-fill {
  height: 100%;
  transition: width 0.2s ease;
}

.sp-error {
  margin-top: 14px;
  padding: 10px 12px;
  border-radius: 10px;
  background: rgba(220, 38, 38, 0.12);
  color: #fda4a4;
  font-size: 13px;
}

.sp-btn,
.sp-link {
  width: 100%;
  margin-top: 18px;
  padding: 13px 16px;
  border-radius: 14px;
  font-family: 'DM Sans', sans-serif;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}

.sp-btn {
  border: none;
  background: #c9a84c;
  color: #16120b;
}

.sp-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.sp-link {
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: transparent;
  color: #d6cab6;
}
</style>
