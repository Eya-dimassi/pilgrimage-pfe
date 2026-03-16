<template>
  <div class="sp-root">
    <div class="sp-card">
      <!-- Logo -->
      <div class="sp-logo">
        <span class="sp-logo-icon">🕌</span>
        <div>
          <div class="sp-logo-name">SmartHajj</div>
          <div class="sp-logo-sub">Activation du compte </div>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="sp-loading">
        <div class="sp-spinner-large"></div>
        <p class="sp-desc">Vérification du lien d'activation...</p>
      </div>

      <!-- Success -->
      <div v-else-if="success" class="sp-success">
        <div class="sp-success-icon">✅</div>
        <h2 class="sp-title">Compte activé !</h2>
        <p class="sp-desc">Votre mot de passe a été défini avec succès. Vous pouvez maintenant vous connecter.</p>
        <button @click="$router.push('/login')" class="sp-btn">Se connecter</button>
      </div>

      <!-- Invalid token -->
      <div v-else-if="tokenError" class="sp-error-state">
        <div class="sp-error-icon">⚠️</div>
        <h2 class="sp-title">Lien invalide ou expiré</h2>
        <p class="sp-desc">{{ tokenError }}</p>
        <button @click="$router.push('/login')" class="sp-btn sp-btn-secondary">Retour à la connexion</button>
      </div>

      <!-- Form -->
      <div v-else>
        <!-- Welcome message -->
        <div class="sp-welcome">
          <h2 class="sp-title">Bienvenue {{ guideName }} !</h2>
          <p class="sp-desc">Définissez votre mot de passe pour activer votre compte.</p>
          <div class="sp-email-display">
            <span class="sp-email-label">Email :</span>
            <span class="sp-email-value">{{ guideEmail }}</span>
          </div>
        </div>

        <!-- Password field -->
        <div class="sp-field">
          <label>Nouveau mot de passe</label>
          <div class="sp-input-wrap">
            <input
              v-model="password"
              :type="showPwd ? 'text' : 'password'"
              placeholder="Minimum 8 caractères"
              @input="validatePassword"
            />
            <button class="sp-eye" @click="showPwd = !showPwd" type="button">
              {{ showPwd ? '🙈' : '👁️' }}
            </button>
          </div>
          
          <!-- Password strength -->
          <div class="sp-strength" v-if="password">
            <div class="sp-strength-bar">
              <div class="sp-strength-fill" :style="{ width: strengthPct + '%', background: strengthColor }"></div>
            </div>
            <span :style="{ color: strengthColor }">{{ strengthLabel }}</span>
          </div>

          <!-- Requirements checklist -->
          <div class="sp-requirements" v-if="password">
            <div class="sp-req-item" :class="{ active: password.length >= 8 }">
              <span class="sp-req-icon">{{ password.length >= 8 ? '✓' : '○' }}</span>
              <span>Au moins 8 caractères</span>
            </div>
            <div class="sp-req-item" :class="{ active: /[A-Z]/.test(password) }">
              <span class="sp-req-icon">{{ /[A-Z]/.test(password) ? '✓' : '○' }}</span>
              <span>Une lettre majuscule</span>
            </div>
            <div class="sp-req-item" :class="{ active: /[0-9]/.test(password) }">
              <span class="sp-req-icon">{{ /[0-9]/.test(password) ? '✓' : '○' }}</span>
              <span>Un chiffre</span>
            </div>
          </div>
        </div>

        <!-- Confirm password field -->
        <div class="sp-field">
          <label>Confirmer le mot de passe</label>
          <input
            v-model="confirm"
            :type="showPwd ? 'text' : 'password'"
            placeholder="Répétez le mot de passe"
            :class="{ 'sp-input-error': confirm && confirm !== password }"
            @input="validateConfirm"
          />
          <span v-if="confirmError" class="sp-field-err">{{ confirmError }}</span>
        </div>

        <!-- Global error -->
        <p v-if="error" class="sp-error">{{ error }}</p>

        <!-- Submit button -->
        <button @click="handleSubmit" :disabled="submitting || !isValid" class="sp-btn">
          <span v-if="submitting" class="sp-spinner"></span>
          {{ submitting ? 'Activation...' : 'Activer mon compte' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import axios from 'axios'

const route = useRoute()
const router = useRouter()

// State
const token = ref('')
const password = ref('')
const confirm = ref('')
const loading = ref(true)
const submitting = ref(false)
const error = ref('')
const confirmError = ref('')
const success = ref(false)
const tokenError = ref('')
const showPwd = ref(false)
const guideName = ref('')
const guideEmail = ref('')

// Verify token on mount
onMounted(async () => {
  token.value = route.query.token
  
  if (!token.value) {
    tokenError.value = 'Aucun token d\'activation fourni.'
    loading.value = false
    return
  }

  try {
    const response = await axios.post(
      `${import.meta.env.VITE_API_URL || 'http://localhost:3000'}/auth/verify-activation-token`,
      { token: token.value }
    )
    
    guideName.value = response.data.nom
    guideEmail.value = response.data.email
    loading.value = false
  } catch (err) {
    console.error('Erreur vérification token:', err)
    tokenError.value = err.response?.data?.message || 'Le lien d\'activation est invalide ou a expiré.'
    loading.value = false
  }
})

// Password strength
const strengthPct = computed(() => {
  const p = password.value
  if (!p) return 0
  let score = 0
  if (p.length >= 8) score += 25
  if (p.length >= 12) score += 25
  if (/[A-Z]/.test(p)) score += 25
  if (/[0-9!@#$%^&*]/.test(p)) score += 25
  return score
})

const strengthLabel = computed(() => {
  const s = strengthPct.value
  if (s <= 25) return 'Faible'
  if (s <= 50) return 'Moyen'
  if (s <= 75) return 'Bon'
  return 'Fort'
})

const strengthColor = computed(() => {
  const s = strengthPct.value
  if (s <= 25) return '#f87171'
  if (s <= 50) return '#fb923c'
  if (s <= 75) return '#C9A84C'
  return '#4ade80'
})

// Validation
const isValid = computed(() => {
  return password.value.length >= 8 &&
         password.value === confirm.value &&
         /[A-Z]/.test(password.value) &&
         /[0-9]/.test(password.value)
})

function validatePassword() {
  error.value = ''
}

function validateConfirm() {
  confirmError.value = ''
  if (confirm.value && confirm.value !== password.value) {
    confirmError.value = 'Les mots de passe ne correspondent pas'
  }
}

// Submit
async function handleSubmit() {
  error.value = ''
  confirmError.value = ''
  
  if (password.value.length < 8) {
    error.value = 'Le mot de passe doit contenir au moins 8 caractères.'
    return
  }
  
  if (password.value !== confirm.value) {
    confirmError.value = 'Les mots de passe ne correspondent pas.'
    return
  }

  submitting.value = true
  
  try {
    await axios.post(
      `${import.meta.env.VITE_API_URL || 'http://localhost:3000'}/auth/set-password`,
      {
        token: token.value,
        newPassword: password.value
      }
    )
    
    success.value = true
  } catch (err) {
    console.error('Erreur activation:', err)
    error.value = err.response?.data?.message || 'Une erreur est survenue lors de l\'activation du compte.'
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=DM+Sans:wght@400;500&display=swap');

.sp-root {
  min-height: 100vh;
  background: #0d0c09;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  font-family: 'DM Sans', sans-serif;
}

.sp-root::before {
  content: '';
  position: fixed;
  inset: 0;
  background: radial-gradient(ellipse at 30% 20%, rgba(201,168,76,0.06) 0%, transparent 60%),
              radial-gradient(ellipse at 70% 80%, rgba(201,168,76,0.04) 0%, transparent 60%);
  pointer-events: none;
}

.sp-card {
  background: #151410;
  border: 1px solid rgba(201,168,76,0.15);
  border-radius: 24px;
  padding: 40px;
  width: 100%;
  max-width: 440px;
  box-shadow: 0 24px 80px rgba(0,0,0,0.5);
  position: relative;
  z-index: 1;
}

/* Logo */
.sp-logo {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 32px;
}
.sp-logo-icon { font-size: 28px; }
.sp-logo-name {
  font-family: 'Syne', sans-serif;
  font-weight: 800;
  font-size: 16px;
  color: #C9A84C;
  letter-spacing: 0.5px;
}
.sp-logo-sub {
  font-size: 11px;
  color: #5a5040;
  margin-top: 1px;
}

/* Titles */
.sp-title {
  font-family: 'Syne', sans-serif;
  font-weight: 800;
  font-size: 22px;
  color: #f0ede6;
  margin-bottom: 8px;
}
.sp-desc {
  font-size: 14px;
  color: #8a8070;
  line-height: 1.55;
  margin-bottom: 24px;
}

/* Welcome section */
.sp-welcome {
  margin-bottom: 28px;
}
.sp-email-display {
  margin-top: 16px;
  padding: 12px 16px;
  background: rgba(201,168,76,0.08);
  border: 1px solid rgba(201,168,76,0.2);
  border-radius: 10px;
  font-size: 13px;
}
.sp-email-label {
  color: #8a8070;
  margin-right: 8px;
}
.sp-email-value {
  color: #C9A84C;
  font-weight: 600;
}

/* Fields */
.sp-field {
  margin-bottom: 20px;
}
.sp-field label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: #8a8070;
  letter-spacing: 0.3px;
  margin-bottom: 8px;
  text-transform: uppercase;
}

.sp-field input,
.sp-input-wrap input {
  width: 100%;
  padding: 12px 16px;
  background: #1c1a15;
  border: 1px solid rgba(255,255,255,0.07);
  border-radius: 12px;
  color: #f0ede6;
  font-size: 14px;
  font-family: 'DM Sans', sans-serif;
  outline: none;
  transition: border-color 0.15s;
  box-sizing: border-box;
}
.sp-field input:focus,
.sp-input-wrap input:focus {
  border-color: #C9A84C;
  box-shadow: 0 0 0 3px rgba(201,168,76,0.1);
}
.sp-field input::placeholder,
.sp-input-wrap input::placeholder {
  color: #5a5040;
}
.sp-input-error {
  border-color: #f87171 !important;
}

.sp-input-wrap {
  position: relative;
}
.sp-input-wrap input {
  padding-right: 44px;
}
.sp-eye {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  font-size: 16px;
  line-height: 1;
}

/* Strength bar */
.sp-strength {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 10px;
}
.sp-strength-bar {
  flex: 1;
  height: 4px;
  background: rgba(255,255,255,0.06);
  border-radius: 4px;
  overflow: hidden;
}
.sp-strength-fill {
  height: 100%;
  border-radius: 4px;
  transition: width 0.3s, background 0.3s;
}
.sp-strength span {
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

/* Requirements */
.sp-requirements {
  margin-top: 12px;
  padding: 12px;
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.05);
  border-radius: 10px;
}
.sp-req-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #5a5040;
  margin-bottom: 6px;
  transition: color 0.2s;
}
.sp-req-item:last-child {
  margin-bottom: 0;
}
.sp-req-item.active {
  color: #4ade80;
}
.sp-req-icon {
  font-weight: 700;
  font-size: 14px;
}

.sp-field-err {
  font-size: 12px;
  color: #f87171;
  margin-top: 6px;
  display: block;
}

/* Error */
.sp-error {
  color: #f87171;
  font-size: 13px;
  margin-bottom: 16px;
  padding: 10px 14px;
  background: rgba(248,113,113,0.08);
  border: 1px solid rgba(248,113,113,0.2);
  border-radius: 10px;
}

/* Button */
.sp-btn {
  width: 100%;
  padding: 13px;
  background: #C9A84C;
  border: none;
  border-radius: 12px;
  color: #0d0c09;
  font-size: 14px;
  font-weight: 700;
  font-family: 'DM Sans', sans-serif;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 8px;
}
.sp-btn:hover:not(:disabled) {
  background: #e0bb5a;
}
.sp-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.sp-btn-secondary {
  background: rgba(255,255,255,0.08);
  color: #f0ede6;
}
.sp-btn-secondary:hover:not(:disabled) {
  background: rgba(255,255,255,0.12);
}

.sp-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(0,0,0,0.2);
  border-top-color: #0d0c09;
  border-radius: 50%;
  animation: sp-spin 0.7s linear infinite;
}
@keyframes sp-spin {
  to { transform: rotate(360deg); }
}

.sp-spinner-large {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(201,168,76,0.2);
  border-top-color: #C9A84C;
  border-radius: 50%;
  animation: sp-spin 0.8s linear infinite;
  margin: 0 auto 16px;
}

/* Loading state */
.sp-loading {
  text-align: center;
  padding: 40px 20px;
}

/* Success / Error states */
.sp-success, .sp-error-state {
  text-align: center;
  padding: 12px 0;
}
.sp-success-icon, .sp-error-icon {
  font-size: 48px;
  margin-bottom: 16px;
}
.sp-success .sp-desc, .sp-error-state .sp-desc {
  margin-bottom: 28px;
}
</style>