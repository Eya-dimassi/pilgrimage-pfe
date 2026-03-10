<template>
  <div class="modal-bg" :class="{ open: show }" @click.self="emit('close')">
    <div class="modal-box">
      <button class="modal-close" type="button" @click="emit('close')">✕</button>

      <div class="modal-title">Demande d'accès</div>
      <p class="modal-sub">Notre équipe vous contactera sous 24h · Sans engagement</p>

      <form @submit.prevent="handleSubmit">
        <div class="mf-row">
          <input class="fi" v-model="form.nomAgence" placeholder="Nom de l'agence" required />
          <input class="fi" v-model="form.telephone" placeholder="Téléphone" required />
        </div>

        <input class="fi fi-full" type="email" v-model="form.email" placeholder="Email professionnel" required />
        <input class="fi fi-full" type="password" v-model="form.motDePasse" placeholder="Mot de passe" required />
        <input class="fi fi-full" v-model="form.adresse" placeholder="Adresse" />
        <input class="fi fi-full" v-model="form.siteWeb" placeholder="Site web (optionnel)" />

        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="emit('close')">Annuler</button>
          <button type="submit" class="btn-send" :disabled="loading">
            {{ loading ? 'Envoi...' : 'Envoyer →' }}
          </button>
        </div>

        <p v-if="error" class="modal-error">{{ error }}</p>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { register } from '@/services/auth.service'

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['close', 'submit'])

const loading = ref(false)
const error = ref('')

const initialForm = () => ({
  nomAgence: '',
  telephone: '',
  email: '',
  motDePasse: '',
  adresse: '',
  siteWeb: '',
})

const form = ref(initialForm())

const handleSubmit = async () => {
  error.value = ''
  loading.value = true

  try {
    const data = await register(form.value)

    form.value = initialForm()
    emit('submit', data)
    emit('close')
  } catch (err) {
    error.value = err?.response?.data?.message || err?.message || "Erreur lors de l'envoi"
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.modal-error {
  color: #e53e3e;
  font-size: 0.8rem;
  margin-top: 0.5rem;
}
</style>