<template>
  <DashboardModalShell title="Profil de l'agence" :error="error" @close="$emit('close')">
    <div class="form-grid">
      <div class="form-field full">
        <label>Nom de l'agence</label>
        <input v-model="form.nomAgence" placeholder="Nom de l'agence" />
      </div>
      <div class="form-field full">
        <label>Adresse</label>
        <input v-model="form.adresse" placeholder="Adresse" />
      </div>
      <div class="form-field">
        <label>Telephone</label>
        <input v-model="form.telephone" placeholder="+213..." />
      </div>
      <div class="form-field">
        <label>Site web</label>
        <input v-model="form.siteWeb" placeholder="https://..." />
      </div>
    </div>
    <template #actions>
      <button class="btn-secondary" @click="$emit('close')">Annuler</button>
      <button class="btn-primary" :disabled="loading" @click="$emit('submit')">
        {{ loading ? 'Sauvegarde...' : 'Sauvegarder' }}
      </button>
    </template>
  </DashboardModalShell>
</template>

<script setup>
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'

defineProps({
  form: { type: Object, required: true },
  error: { type: String, default: '' },
  loading: { type: Boolean, default: false },
})

defineEmits(['close', 'submit'])
</script>
