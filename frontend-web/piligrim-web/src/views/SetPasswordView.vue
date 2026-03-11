<template>
  <div class="sp-root">
    <div class="sp-card">
      <!-- Logo -->
      <div class="sp-logo">
        <span class="sp-logo-icon">🕌</span>
        <div>
          <div class="sp-logo-name">SmartHajj</div>
          <div class="sp-logo-sub">Activation du compte</div>
        </div>
      </div>

      <!-- Success -->
      <div v-if="success" class="sp-success">
        <div class="sp-success-icon">✅</div>
        <h2 class="sp-title">Compte activé !</h2>
        <p class="sp-desc">Votre mot de passe a été défini avec succès. Vous pouvez maintenant vous connecter.</p>
        <button @click="$router.push('/')" class="sp-btn">Se connecter</button>
      </div>

      <!-- Invalid token -->
      <div v-else-if="tokenError" class="sp-error-state">
        <div class="sp-error-icon">⚠️</div>
        <h2 class="sp-title">Lien invalide</h2>
        <p class="sp-desc">{{ tokenError }}</p>
      </div>

      <!-- Form -->
      <div v-else>
        <h2 class="sp-title">Définir votre mot de passe</h2>
        <p class="sp-desc">Choisissez un mot de passe sécurisé pour activer votre compte.</p>

        <div class="sp-field">
          <label>Nouveau mot de passe</label>
          <div class="sp-input-wrap">
            <input
              v-model="password"
              :type="showPwd ? 'text' : 'password'"
              placeholder="Minimum 8 caractères"
            />
            <button class="sp-eye" @click="showPwd = !showPwd" type="button">
              {{ showPwd ? '🙈' : '👁️' }}
            </button>
          </div>
          <div class="sp-strength" v-if="password">
            <div class="sp-strength-bar">
              <div class="sp-strength-fill" :style="{ width: strengthPct + '%', background: strengthColor }"></div>
            </div>
            <span :style="{ color: strengthColor }">{{ strengthLabel }}</span>
          </div>
        </div>

        <div class="sp-field">
          <label>Confirmer le mot de passe</label>
          <input
            v-model="confirm"
            :type="showPwd ? 'text' : 'password'"
            placeholder="Répétez le mot de passe"
            :class="{ 'sp-input-error': confirm && confirm !== password }"
          />
          <span v-if="confirm && confirm !== password" class="sp-field-err">Les mots de passe ne correspondent pas</span>
        </div>

        <p v-if="error" class="sp-error">{{ error }}</p>

        <button @click="handleSubmit" :disabled="loading" class="sp-btn">
          <span v-if="loading" class="sp-spinner"></span>
          {{ loading ? 'Activation...' : 'Activer mon compte' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const token = ref('')
const password = ref('')
const confirm = ref('')
const loading = ref(false)
const error = ref('')
const success = ref(false)
const tokenError = ref('')
const showPwd = ref(false)

onMounted(() => {
  token.value = route.query.token
  if (!token.value) tokenError.value = 'Lien d\'activation invalide ou expiré.'
})

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

async function handleSubmit() {
  error.value = ''
  if (password.value.length < 8) { error.value = 'Le mot de passe doit contenir au moins 8 caractères.'; return }
  if (password.value !== confirm.value) { error.value = 'Les mots de passe ne correspondent pas.'; return }

  loading.value = true
  try {
    const res = await fetch('http://localhost:3000/auth/set-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: token.value, newPassword: password.value }),
    })
    const data = await res.json()
    if (!res.ok) throw new Error(data.message)
    success.value = true
  } catch (err) {
    error.value = err.message || 'Une erreur est survenue.'
  } finally {
    loading.value = false
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

/* subtle gold grain background */
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
  max-width: 420px;
  box-shadow: 0 24px 80px rgba(0,0,0,0.5);
  position: relative;
  z-index: 1;
}

/* ── Logo ── */
.sp-logo { display: flex; align-items: center; gap: 12px; margin-bottom: 32px; }
.sp-logo-icon { font-size: 28px; }
.sp-logo-name { font-family: 'Syne', sans-serif; font-weight: 800; font-size: 16px; color: #C9A84C; letter-spacing: 0.5px; }
.sp-logo-sub  { font-size: 11px; color: #5a5040; margin-top: 1px; }

/* ── Titles ── */
.sp-title { font-family: 'Syne', sans-serif; font-weight: 800; font-size: 22px; color: #f0ede6; margin-bottom: 8px; }
.sp-desc  { font-size: 14px; color: #8a8070; line-height: 1.55; margin-bottom: 28px; }

/* ── Fields ── */
.sp-field { margin-bottom: 20px; }
.sp-field label { display: block; font-size: 12px; font-weight: 600; color: #8a8070; letter-spacing: 0.3px; margin-bottom: 8px; text-transform: uppercase; }

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
.sp-input-wrap input:focus { border-color: #C9A84C; box-shadow: 0 0 0 3px rgba(201,168,76,0.1); }
.sp-field input::placeholder,
.sp-input-wrap input::placeholder { color: #5a5040; }
.sp-input-error { border-color: #f87171 !important; }

.sp-input-wrap { position: relative; }
.sp-input-wrap input { padding-right: 44px; }
.sp-eye { position: absolute; right: 12px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; font-size: 16px; line-height: 1; }

/* ── Strength bar ── */
.sp-strength { margin-top: 8px; display: flex; align-items: center; gap: 10px; }
.sp-strength-bar { flex: 1; height: 4px; background: rgba(255,255,255,0.06); border-radius: 4px; overflow: hidden; }
.sp-strength-fill { height: 100%; border-radius: 4px; transition: width 0.3s, background 0.3s; }
.sp-strength span { font-size: 12px; font-weight: 600; white-space: nowrap; }

.sp-field-err { font-size: 12px; color: #f87171; margin-top: 6px; display: block; }

/* ── Error ── */
.sp-error { color: #f87171; font-size: 13px; margin-bottom: 16px; padding: 10px 14px; background: rgba(248,113,113,0.08); border: 1px solid rgba(248,113,113,0.2); border-radius: 10px; }

/* ── Button ── */
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
.sp-btn:hover:not(:disabled) { background: #e0bb5a; }
.sp-btn:disabled { opacity: 0.5; cursor: not-allowed; }

.sp-spinner {
  width: 16px; height: 16px;
  border: 2px solid rgba(0,0,0,0.2);
  border-top-color: #0d0c09;
  border-radius: 50%;
  animation: sp-spin 0.7s linear infinite;
}
@keyframes sp-spin { to { transform: rotate(360deg); } }

/* ── Success / Error states ── */
.sp-success, .sp-error-state { text-align: center; padding: 12px 0; }
.sp-success-icon, .sp-error-icon { font-size: 48px; margin-bottom: 16px; }
.sp-success .sp-desc, .sp-error-state .sp-desc { margin-bottom: 28px; }
</style>