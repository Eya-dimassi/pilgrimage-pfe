<template>
  <div class="sp-root">
    <div class="sp-card">
      <div class="sp-logo">
        <BrandMark :size="40" />
        <div>
          <div class="sp-logo-name">{{ brand.name }}</div>
          <div class="sp-logo-sub">Activation du compte</div>
        </div>
      </div>

      <div v-if="loading" class="sp-loading">
        <div class="sp-spinner-large"></div>
        <p class="sp-desc">Verification du lien d'activation...</p>
      </div>

      <div v-else-if="success" class="sp-state">
        <AppIcon class="sp-state-icon sp-state-icon-success" name="check" :size="34" :stroke-width="2.8" />
        <h2 class="sp-title">Compte active !</h2>
        <p class="sp-desc">Votre mot de passe a ete defini avec succes. Vous pouvez maintenant vous connecter.</p>
        <button type="button" class="sp-btn" @click="router.push('/')">Se connecter</button>
      </div>

      <div v-else-if="tokenError" class="sp-state">
        <AppIcon class="sp-state-icon sp-state-icon-error" name="alert" :size="34" :stroke-width="2.2" />
        <h2 class="sp-title">Lien invalide ou expire</h2>
        <p class="sp-desc">{{ tokenError }}</p>
        <button type="button" class="sp-btn sp-btn-secondary" @click="router.push('/')">Retour a la connexion</button>
      </div>

      <form v-else @submit.prevent="handleSubmit">
        <div class="sp-welcome">
          <h2 class="sp-title">Bienvenue {{ guideName }} !</h2>
          <p class="sp-desc">Definissez votre mot de passe pour activer votre compte.</p>
          <div class="sp-email-display">
            <span class="sp-email-label">Email :</span>
            <span class="sp-email-value">{{ guideEmail }}</span>
          </div>
        </div>

        <div class="sp-field">
          <label for="password">Nouveau mot de passe</label>
          <div class="sp-input-wrap">
            <input
              id="password"
              v-model="password"
              :type="showPwd ? 'text' : 'password'"
              placeholder="Minimum 8 caracteres"
            />
            <button class="sp-eye" type="button" @click="showPwd = !showPwd">
              {{ showPwd ? 'Masquer' : 'Afficher' }}
            </button>
          </div>

          <div v-if="password" class="sp-strength">
            <div class="sp-strength-bar">
              <div class="sp-strength-fill" :style="{ width: `${strengthPct}%`, background: strengthColor }"></div>
            </div>
            <span :style="{ color: strengthColor }">{{ strengthLabel }}</span>
          </div>

          <div v-if="password" class="sp-requirements">
            <div class="sp-req-item" :class="{ active: password.length >= 8 }">
              <span class="sp-req-icon">{{ password.length >= 8 ? 'OK' : '...' }}</span>
              <span>Au moins 8 caracteres</span>
            </div>
            <div class="sp-req-item" :class="{ active: hasUppercase(password) }">
              <span class="sp-req-icon">{{ hasUppercase(password) ? 'OK' : '...' }}</span>
              <span>Une lettre majuscule</span>
            </div>
            <div class="sp-req-item" :class="{ active: hasDigit(password) }">
              <span class="sp-req-icon">{{ hasDigit(password) ? 'OK' : '...' }}</span>
              <span>Un chiffre</span>
            </div>
          </div>
        </div>

        <div class="sp-field">
          <label for="confirm">Confirmer le mot de passe</label>
          <input
            id="confirm"
            v-model="confirm"
            :type="showPwd ? 'text' : 'password'"
            placeholder="Repetez le mot de passe"
            :class="{ 'sp-input-error': confirm && confirm !== password }"
            @input="validateConfirm"
          />
          <span v-if="confirmError" class="sp-field-err">{{ confirmError }}</span>
        </div>

        <p v-if="error" class="sp-error">{{ error }}</p>

        <button class="sp-btn" type="submit" :disabled="submitting || !isValid">
          <span v-if="submitting" class="sp-spinner"></span>
          {{ submitting ? 'Activation...' : 'Activer mon compte' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppIcon from '@/components/AppIcon.vue'
import BrandMark from '@/components/BrandMark.vue'
import { brand } from '@/content/brand'
import { getPasswordStrength, hasDigit, hasUppercase, isStrongPassword, normalizeQueryToken, validatePasswordConfirmation } from '@/composables/usePasswordRules'
import { setPassword, verifyActivationToken } from '@/services/auth.service'

const route = useRoute()
const router = useRouter()

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

const passwordStrength = computed(() => getPasswordStrength(password.value))
const strengthPct = computed(() => passwordStrength.value.pct)
const strengthLabel = computed(() => passwordStrength.value.label)
const strengthColor = computed(() => passwordStrength.value.color)
const isValid = computed(() => isStrongPassword(password.value) && password.value === confirm.value)

onMounted(async () => {
  token.value = normalizeQueryToken(route.query.token)

  if (!token.value) {
    tokenError.value = 'Aucun token d\'activation fourni.'
    loading.value = false
    return
  }

  try {
    const data = await verifyActivationToken(token.value)
    guideName.value = data.nom
    guideEmail.value = data.email
  } catch (err) {
    tokenError.value = err.response?.data?.message || 'Le lien d\'activation est invalide ou a expire.'
  } finally {
    loading.value = false
  }
})

function validateConfirm() {
  confirmError.value = ''

  if (confirm.value && confirm.value !== password.value) {
    confirmError.value = 'Les mots de passe ne correspondent pas.'
  }
}

async function handleSubmit() {
  error.value = ''
  confirmError.value = ''

  const validationError = validatePasswordConfirmation(password.value, confirm.value)
  if (validationError) {
    if (validationError.includes('correspondent')) {
      confirmError.value = validationError
    } else {
      error.value = validationError
    }
    return
  }

  submitting.value = true

  try {
    await setPassword(token.value, password.value)
    success.value = true
    window.setTimeout(() => router.push('/'), 2000)
  } catch (err) {
    error.value = err.response?.data?.message || 'Une erreur est survenue lors de l\'activation du compte.'
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped src="@/assets/styles/auth/activate-account.css"></style>
