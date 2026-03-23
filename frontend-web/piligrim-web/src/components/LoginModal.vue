<template>
  <div class="modal-bg" :class="{ open: show }" @click.self="emit('close')">
    <div class="modal-box login-modal-box">
      <button class="modal-close" type="button" @click="emit('close')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      </button>

      <div class="login-header">
        <div class="login-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--gold)" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="8" width="18" height="13" rx="1" />
            <path d="M7 8V6a5 5 0 0 1 10 0v2" />
            <line x1="12" y1="12" x2="12" y2="16" />
          </svg>
        </div>
        <h2 class="modal-title">Connexion</h2>
        <p class="modal-sub">Accédez à votre espace SmartHajj</p>
      </div>

      <form @submit.prevent="handleLogin">
        <div class="field-group">
          <label class="field-label">Email</label>
          <input
            class="fi fi-full"
            type="email"
            v-model="email"
            placeholder="exemple@agence.com"
            required
            autocomplete="email"
          />
        </div>

        <div class="field-group">
          <div class="field-label-row">
            <label class="field-label">Mot de passe</label>
            <button type="button" class="forgot-link" @click="goToForgotPassword">
              Mot de passe oublié ?
            </button>
          </div>
          <div class="password-wrap">
            <input
              class="fi fi-full password-input"
              :type="showPassword ? 'text' : 'password'"
              v-model="password"
              placeholder="••••••••"
              required
              autocomplete="current-password"
            />
            <button type="button" class="pw-toggle" @click="showPassword = !showPassword">
              <svg v-if="!showPassword" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                <circle cx="12" cy="12" r="3" />
              </svg>
              <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                <line x1="1" y1="1" x2="23" y2="23" />
              </svg>
            </button>
          </div>
        </div>

        <p v-if="errorMessage" class="login-error">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          {{ errorMessage }}
        </p>

        <button type="submit" class="btn-form-submit login-submit" :disabled="loading">
          <span v-if="!loading">Se connecter →</span>
          <span v-else class="login-loading">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" class="spin">
              <path d="M21 12a9 9 0 1 1-6.219-8.56" />
            </svg>
            Connexion...
          </span>
        </button>
      </form>

      <div class="login-divider">
        <span>Pas encore client ?</span>
      </div>

      <!-- ✅ emit name matches HomePageView's @switch-to-signup listener -->
      <button class="btn-signup-alt" type="button" @click="emit('switch-to-signup')">
        Demander un accès agence
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { login, saveSession } from '@/services/auth.service'

defineProps({
  show: { type: Boolean, default: false },
})

// ✅ kebab-case to match @switch-to-signup in HomePageView
const emit = defineEmits(['close', 'switch-to-signup'])

const router       = useRouter()
const email        = ref('')
const password     = ref('')
const showPassword = ref(false)
const errorMessage = ref('')
const loading      = ref(false)

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
      errorMessage.value = 'Ce portail est réservé aux agences et administrateurs'
      return
    }

    saveSession(data)
    emit('close')

    if (role === 'AGENCE')      router.push('/dashboard')
    else if (role === 'SUPER_ADMIN') router.push('/admin')
  } catch (error) {
    // Backend returns specific message for PENDING accounts — display it directly
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

.login-icon {
  width: 48px; height: 48px; border-radius: 14px;
  background: var(--gold-soft);
  border: 1px solid rgba(184, 150, 46, 0.2);
  display: flex; align-items: center; justify-content: center;
  margin-bottom: 1rem;
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
.spin { animation: spin 0.8s linear infinite; }

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
