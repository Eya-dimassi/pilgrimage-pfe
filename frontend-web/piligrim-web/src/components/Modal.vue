<template>
  <div class="modal-bg" :class="{ open: show }" @click.self="emit('close')">
    <div class="modal-box">
      <button class="modal-close" type="button" @click="emit('close')">✕</button>

      <div class="modal-title">Demander l'acces</div>
      <p class="modal-sub">
        Une version plus compacte, plus propre, et plus rapide a remplir.
      </p>

      <AgencyAccessForm
        show-cancel
        submit-label="Envoyer →"
        loading-label="Envoi..."
        success-text="Demande envoyee avec succes. Notre equipe revient vers vous sous 24h."
        @cancel="emit('close')"
        @success="handleSubmitSuccess"
      />
    </div>
  </div>
</template>

<script setup>
import AgencyAccessForm from './AgencyAccessForm.vue'

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['close', 'submit'])

const handleSubmitSuccess = (data) => {
  emit('submit', data)
  emit('close')
}
</script>
