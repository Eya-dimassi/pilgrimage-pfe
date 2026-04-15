<template>
  <div class="modal-bg" :class="{ open: show }" @click.self="emit('close')">
    <div class="modal-box login-modal-box">
      <button class="modal-close" type="button" @click="emit('close')">
        <AppIcon name="x" :size="14" :stroke-width="2.5" />
      </button>

      <div class="login-header">
        <BrandMark :size="64" />
        <h2 class="modal-title">Connexion</h2>
        <p class="modal-sub">{{ brand.loginDescription }}</p>
      </div>

      <form @submit.prevent="handleLogin">
        <div class="field-group">
          <label class="field-label">Email</label>
          <input
            v-model="email"
            class="fi fi-full"
            type="email"
            placeholder="exemple@agence.com"
            required
            autocomplete="email"
          />
        </div>

        <div class="field-group">
          <div class="field-label-row">
            <label class="field-label">Mot de passe</label>
            <button type="button" class="forgot-link" @click="goToForgotPassword">
              Mot de passe oublie ?
            </button>
          </div>

          <div class="password-wrap">
            <input
              v-model="password"
              class="fi fi-full password-input"
              :type="showPassword ? 'text' : 'password'"
              placeholder="********"
              required
              autocomplete="current-password"
            />
            <button type="button" class="pw-toggle" @click="showPassword = !showPassword">
              <AppIcon v-if="!showPassword" name="eye" :size="16" :stroke-width="2" />
              <AppIcon v-else name="eye-off" :size="16" :stroke-width="2" />
            </button>
          </div>
        </div>

        <p v-if="errorMessage" class="login-error">
          <AppIcon name="alert" :size="13" :stroke-width="2" />
          {{ errorMessage }}
        </p>

        <button type="submit" class="btn-form-submit login-submit" :disabled="loading">
          <span v-if="!loading">Se connecter -></span>
          <span v-else class="login-loading">
            <AppIcon name="spinner" :size="14" :stroke-width="2.5" spin />
            Connexion...
          </span>
        </button>
      </form>

      <div class="login-divider">
        <span>Pas encore client ?</span>
      </div>

      <button class="btn-signup-alt" type="button" @click="emit('switch-to-signup')">
        creer un compte 
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

import { brand } from '@/content/brand'
import { login, saveSession } from '@/services/auth.service'
import AppIcon from './AppIcon.vue'
import BrandMark from './BrandMark.vue'

defineProps({
  show: { type: Boolean, default: false },
})

const emit = defineEmits(['close', 'switch-to-signup'])

const router = useRouter()
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const errorMessage = ref('')
const loading = ref(false)

const goToForgotPassword = () => {
  emit('close')
  router.push('/forgot-password')
}

const handleLogin = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    const data = await login(email.value, password.value)
    const role = data.utilisateur.role

    if (role !== 'AGENCE' && role !== 'SUPER_ADMIN') {
      errorMessage.value = 'Ce portail est reserve aux agences et administrateurs'
      return
    }

    saveSession(data)
    emit('close')

    if (role === 'AGENCE') router.replace('/dashboard')
    else if (role === 'SUPER_ADMIN') router.replace('/admin')
  } catch (error) {
    errorMessage.value = error?.response?.data?.message || 'Email ou mot de passe incorrect'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-modal-box { max-width: 440px; }

.login-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 1.75rem;
}

.field-group { margin-bottom: 1rem; }

.field-label-row {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 0.45rem;
}

.field-label {
  display: block; font-size: 0.8rem; font-weight: 500;
  color: var(--text-muted); margin-bottom: 0.45rem; letter-spacing: -0.01em;
}
.field-label-row .field-label { margin-bottom: 0; }

.forgot-link {
  font-size: 0.78rem; color: var(--gold);
  background: none; border: none; cursor: pointer; padding: 0; transition: opacity 0.18s;
}
.forgot-link:hover { opacity: 0.7; }

.password-wrap { position: relative; }
.password-input { padding-right: 2.75rem; margin-bottom: 0; }

.pw-toggle {
  position: absolute; right: 0.9rem; top: 50%; transform: translateY(-50%);
  background: none; border: none; cursor: pointer;
  color: var(--text-faint); display: flex; align-items: center; transition: color 0.18s;
}
.pw-toggle:hover { color: var(--text); }

.login-error {
  display: flex; align-items: center; gap: 0.4rem;
  font-size: 0.8rem; color: #e53e3e;
  background: rgba(229, 62, 62, 0.07);
  border: 1px solid rgba(229, 62, 62, 0.18);
  border-radius: 10px; padding: 0.6rem 0.85rem; margin-bottom: 0.75rem;
}

.login-submit { margin-top: 0.5rem; }

.login-loading {
  display: flex; align-items: center; justify-content: center; gap: 0.5rem;
}

.login-divider {
  display: flex; align-items: center; gap: 0.75rem;
  margin: 1.25rem 0 1rem; color: var(--text-faint); font-size: 0.78rem;
}
.login-divider::before,
.login-divider::after {
  content: ''; flex: 1; height: 1px; background: var(--border);
}

.btn-signup-alt {
  width: 100%; font-family: 'DM Sans', sans-serif;
  font-size: 0.875rem; font-weight: 400; padding: 0.8rem;
  border-radius: 13px; border: 1px solid var(--border);
  background: var(--off); color: var(--text-muted);
  cursor: pointer; transition: all 0.2s; letter-spacing: -0.01em;
}
.btn-signup-alt:hover {
  border-color: var(--gold); color: var(--gold); background: var(--gold-soft);
}
</style>
