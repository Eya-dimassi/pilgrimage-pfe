<template>
  <form class="agency-access-form" novalidate @submit.prevent="handleSubmit">
    <div class="signup-grid">
      <div class="signup-field">
        <label class="signup-label" for="agency-name">Nom de l'agence</label>
        <div class="field-shell">
          <span class="field-icon" aria-hidden="true">
            <AppIcon name="building" :size="16" :stroke-width="1.8" />
          </span>
          <input
            id="agency-name"
            v-model="form.nomAgence"
            class="fi fi-inset"
            type="text"
            placeholder="Nom commercial"
            autocomplete="organization"
            @blur="validateField('nomAgence')"
            @input="validateField('nomAgence')"
          />
        </div>
        <p v-if="errors.nomAgence" class="field-error">{{ errors.nomAgence }}</p>
      </div>

      <div class="signup-field">
        <label class="signup-label" for="agency-email">Email professionnel</label>
        <div class="field-shell">
          <span class="field-icon" aria-hidden="true">
            <AppIcon name="mail" :size="16" :stroke-width="1.8" />
          </span>
          <input
            id="agency-email"
            v-model="form.email"
            class="fi fi-inset"
            type="email"
            placeholder="contact@votreagence.com"
            autocomplete="email"
            @blur="normalizeEmail"
            @input="validateField('email')"
          />
        </div>
        <p v-if="errors.email" class="field-error">{{ errors.email }}</p>
      </div>

      <div class="signup-field">
        <div class="signup-label-row">
          <label class="signup-label" for="agency-password">Mot de passe</label>
          <button type="button" class="inline-action" @click="showPassword = !showPassword">
            {{ showPassword ? 'Masquer' : 'Afficher' }}
          </button>
        </div>
        <div class="field-shell">
          <span class="field-icon" aria-hidden="true">
            <AppIcon name="lock" :size="16" :stroke-width="1.8" />
          </span>
          <input
            id="agency-password"
            v-model="form.motDePasse"
            class="fi fi-inset"
            :type="showPassword ? 'text' : 'password'"
            placeholder="8 caracteres minimum"
            autocomplete="new-password"
            @blur="validateField('motDePasse')"
            @input="validateField('motDePasse')"
          />
        </div>
        <p v-if="errors.motDePasse" class="field-error">{{ errors.motDePasse }}</p>
      </div>

      <div class="signup-field signup-field-full">
        <label class="signup-label" for="agency-phone">Telephone</label>
        <div class="field-shell">
          <span class="field-icon" aria-hidden="true">
            <AppIcon name="phone" :size="16" :stroke-width="1.8" />
          </span>
          <PhoneNumberField
            id="agency-phone"
            v-model="form.telephone"
            class="fi-phone"
            :default-dial-code="countries[0].dialCode"
            @update:model-value="validateField('telephone')"
          />
        </div>
        <p class="field-hint">Choisissez l'indicatif puis saisissez le numero local.</p>
        <p v-if="errors.telephone" class="field-error">{{ errors.telephone }}</p>
      </div>

      <div class="signup-field">
        <label class="signup-label" for="agency-address">Adresse</label>
        <div class="field-shell">
          <span class="field-icon" aria-hidden="true">
            <AppIcon name="map-pin" :size="16" :stroke-width="1.8" />
          </span>
          <input
            id="agency-address"
            v-model="form.adresse"
            class="fi fi-inset"
            type="text"
            placeholder="Ville, pays"
            autocomplete="street-address"
            @blur="validateField('adresse')"
            @input="validateField('adresse')"
          />
        </div>
        <p v-if="errors.adresse" class="field-error">{{ errors.adresse }}</p>
      </div>

      <div class="signup-field">
        <label class="signup-label" for="agency-website">Site web</label>
        <div class="field-shell">
          <span class="field-icon" aria-hidden="true">
            <AppIcon name="globe" :size="16" :stroke-width="1.8" />
          </span>
          <input
            id="agency-website"
            v-model="form.siteWeb"
            class="fi fi-inset"
            type="url"
            placeholder="https://www.votreagence.com"
            autocomplete="url"
            @blur="normalizeWebsiteField"
            @input="validateField('siteWeb')"
          />
        </div>
        <p v-if="errors.siteWeb" class="field-error">{{ errors.siteWeb }}</p>
      </div>
    </div>

    <div v-if="showCancel" class="modal-actions">
      <button type="button" class="btn-cancel" @click="emit('cancel')">{{ cancelLabel }}</button>
      <button type="submit" class="btn-send" :disabled="loading">
        {{ loading ? loadingLabel : submitLabel }}
      </button>
    </div>

    <button v-else type="submit" class="btn-form-submit signup-submit" :disabled="loading">
      {{ loading ? loadingLabel : submitLabel }}
    </button>

    <p v-if="error" class="form-feedback form-feedback-error">{{ error }}</p>
    <p v-if="successMessage" class="form-feedback form-feedback-success">{{ successMessage }}</p>
  </form>
</template>

<script setup>
import { ref } from 'vue'

import { countries } from '@/content/countries'
import { register } from '@/services/auth.service'
import AppIcon from './AppIcon.vue'
import PhoneNumberField from './forms/PhoneNumberField.vue'

const props = defineProps({
  submitLabel: {
    type: String,
    default: 'Envoyer ma demande ->',
  },
  loadingLabel: {
    type: String,
    default: 'Envoi...',
  },
  cancelLabel: {
    type: String,
    default: 'Annuler',
  },
  successText: {
    type: String,
    default: 'Demande envoyee avec succes. Notre equipe vous contactera sous 24h.',
  },
  showCancel: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['success', 'cancel'])

const createInitialForm = () => ({
  nomAgence: '',
  telephone: '',
  email: '',
  motDePasse: '',
  adresse: '',
  siteWeb: '',
})

const form = ref(createInitialForm())
const errors = ref({})
const loading = ref(false)
const successMessage = ref('')
const error = ref('')
const showPassword = ref(false)

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/i
const passwordPattern = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/
const phonePattern = /^\+\d{1,4}\s[\d\s()-]{5,20}$/

const normalizeWebsite = (value) => {
  if (!value?.trim()) return ''

  const withProtocol = /^https?:\/\//i.test(value.trim())
    ? value.trim()
    : `https://${value.trim()}`

  const url = new URL(withProtocol)

  if (!url.hostname.includes('.')) {
    throw new Error('Le site web doit contenir un domaine valide.')
  }

  return url.toString().replace(/\/$/, '')
}

const validators = {
  nomAgence: (value) => {
    if (!value.trim()) return "Le nom de l'agence est requis."
    if (value.trim().length < 2) return "Le nom de l'agence est trop court."
    return ''
  },
  telephone: (value) => {
    const normalized = value.trim()
    if (!normalized) return 'Le numero de telephone est requis.'
    if (!phonePattern.test(normalized)) {
      return 'Entrez un numero international valide, par exemple +216 20 123 456.'
    }
    return ''
  },
  email: (value) => {
    const normalized = value.trim().toLowerCase()
    if (!normalized) return "L'email professionnel est requis."
    if (!emailPattern.test(normalized)) return 'Entrez une adresse email valide.'
    return ''
  },
  motDePasse: (value) => {
    if (!value) return 'Le mot de passe est requis.'
    if (!passwordPattern.test(value)) {
      return 'Utilisez 8 caracteres minimum avec au moins une lettre et un chiffre.'
    }
    return ''
  },
  adresse: (value) => {
    if (!value.trim()) return ''
    if (value.trim().length < 4) return 'Precisez au moins la ville ou le pays.'
    return ''
  },
  siteWeb: (value) => {
    if (!value.trim()) return ''
    try {
      normalizeWebsite(value)
      return ''
    } catch {
      return 'Entrez une URL valide, par exemple https://www.votreagence.com.'
    }
  },
}

const validateField = (field) => {
  errors.value = {
    ...errors.value,
    [field]: validators[field](form.value[field] ?? ''),
  }
}

const validateAll = () => {
  const nextErrors = Object.fromEntries(
    Object.keys(validators).map((field) => [field, validators[field](form.value[field] ?? '')]),
  )

  errors.value = nextErrors
  return !Object.values(nextErrors).some(Boolean)
}

const normalizeEmail = () => {
  form.value.email = form.value.email.trim().toLowerCase()
  validateField('email')
}

const normalizeWebsiteField = () => {
  if (!form.value.siteWeb.trim()) {
    validateField('siteWeb')
    return
  }

  try {
    form.value.siteWeb = normalizeWebsite(form.value.siteWeb)
    validateField('siteWeb')
  } catch {
    validateField('siteWeb')
  }
}

const handleSubmit = async () => {
  successMessage.value = ''
  error.value = ''

  if (!validateAll()) {
    error.value = 'Corrigez les champs signales avant de continuer.'
    return
  }

  loading.value = true

  try {
    const payload = {
      nomAgence: form.value.nomAgence.trim(),
      telephone: form.value.telephone.trim(),
      email: form.value.email.trim().toLowerCase(),
      motDePasse: form.value.motDePasse,
      adresse: form.value.adresse.trim(),
      siteWeb: normalizeWebsite(form.value.siteWeb),
    }

    const data = await register(payload)

    successMessage.value = props.successText
    form.value = createInitialForm()
    errors.value = {}
    showPassword.value = false
    error.value = ''
    emit('success', data)
  } catch (err) {
    error.value =
      err?.response?.data?.message || err?.message || "Erreur lors de l'envoi"
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.agency-access-form {
  display: flex;
  flex-direction: column;
}

.signup-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
}

.signup-field {
  margin-bottom: 0.2rem;
}

.signup-field-full {
  grid-column: 1 / -1;
}

.signup-label-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.signup-label {
  display: block;
  margin-bottom: 0.42rem;
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--text-muted);
}

.field-shell {
  position: relative;
}

.field-icon {
  position: absolute;
  top: 50%;
  left: 0.95rem;
  transform: translateY(-50%);
  width: 16px;
  height: 16px;
  color: var(--text-faint);
  pointer-events: none;
}

.fi-inset {
  padding-left: 2.8rem;
}

.field-error,
.form-feedback {
  font-size: 0.76rem;
  line-height: 1.4;
  margin-top: 0.35rem;
}

.field-hint {
  font-size: 0.74rem;
  line-height: 1.35;
  margin-top: 0.35rem;
  color: var(--text-faint);
}

.field-error,
.form-feedback-error {
  color: #d64545;
}

.form-feedback-success {
  color: #2d7a4a;
}

.inline-action {
  border: none;
  background: none;
  color: var(--gold);
  font: inherit;
  font-size: 0.78rem;
  cursor: pointer;
}

.signup-submit {
  margin-top: 0.4rem;
}

.fi-phone :deep(.phone-field) {
  grid-template-columns: minmax(210px, 0.9fr) minmax(0, 1.35fr);
}

.fi-phone :deep(.phone-select),
.fi-phone :deep(.phone-input) {
  width: 100%;
  border-color: var(--border-soft);
  background: var(--surface);
  color: var(--text-main);
}

.fi-phone :deep(.phone-select) {
  padding-left: 2.8rem;
}

.fi-phone :deep(.phone-input:focus),
.fi-phone :deep(.phone-select:focus) {
  outline: none;
  border-color: rgba(201, 168, 76, 0.7);
  box-shadow: 0 0 0 4px rgba(201, 168, 76, 0.12);
}

@media (max-width: 768px) {
  .signup-grid {
    grid-template-columns: 1fr;
  }

  .signup-field-full {
    grid-column: auto;
  }
}
</style>
