<template>
  <div class="sp-root">
    <div class="sp-card">
      <div class="sp-logo">
        <div>
          <div class="sp-logo-name">{{ brand.name }}</div>
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

        <div v-if="password" class="sp-requirements">
          <div class="sp-req-item" :class="{ active: password.length >= 8 }">Au moins 8 caracteres</div>
          <div class="sp-req-item" :class="{ active: hasUppercase(password) }">Une lettre majuscule</div>
          <div class="sp-req-item" :class="{ active: hasDigit(password) }">Un chiffre</div>
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
import { brand } from '@/content/brand'
import { getPasswordStrength, hasDigit, hasUppercase, isStrongPassword, normalizeQueryToken, validatePasswordConfirmation } from '@/composables/usePasswordRules'
import { setPassword } from '@/services/auth.service'

const route = useRoute()
const router = useRouter()

const token = ref(normalizeQueryToken(route.query.token))
const password = ref('')
const confirm = ref('')
const showPassword = ref(false)
const loading = ref(false)
const success = ref(false)
const error = ref('')
const tokenError = ref(token.value ? '' : 'Le lien de reinitialisation est invalide ou incomplet.')

const passwordStrength = computed(() => getPasswordStrength(password.value))
const strengthPct = computed(() => passwordStrength.value.pct)
const strengthLabel = computed(() => passwordStrength.value.label)
const strengthColor = computed(() => passwordStrength.value.color)

const isValid = computed(() => (
  token.value &&
  isStrongPassword(password.value) &&
  password.value === confirm.value
))

async function handleSubmit() {
  if (!token.value) {
    tokenError.value = 'Le lien de reinitialisation est invalide ou incomplet.'
    return
  }

  const validationError = validatePasswordConfirmation(password.value, confirm.value)
  if (validationError) {
    error.value = validationError
    return
  }

  loading.value = true
  error.value = ''

  try {
    await setPassword(token.value, password.value)
    success.value = true
    window.setTimeout(() => router.push('/'), 2000)
  } catch (err) {
    error.value = err.response?.data?.message || 'Une erreur est survenue.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped src="@/assets/styles/auth/set-password.css"></style>
