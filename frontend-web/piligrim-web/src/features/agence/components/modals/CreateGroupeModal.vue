<template>
  <DashboardModalShell title="Nouveau groupe" :error="error" @close="$emit('close')">
    <div class="form-grid">
      <div class="form-field full"><label>Nom *</label><input v-model="form.nom" placeholder="Groupe Hajj 2025" /></div>
      <div class="form-field"><label>Annee *</label><input v-model="form.annee" type="number" placeholder="2025" /></div>
      <div class="form-field">
        <label>Type *</label>
        <select v-model="form.typeVoyage">
          <option value="HAJJ">Hajj</option>
          <option value="UMRAH">Umrah</option>
        </select>
      </div>
      <div class="form-field full"><label>Description</label><input v-model="form.description" placeholder="Description optionnelle" /></div>
      <div class="form-field full">
        <label>Guide (optionnel)</label>
        <select v-model="form.guideId">
          <option value="">Sans guide</option>
          <option v-for="guide in guides" :key="guide.id" :value="guide.id">
            {{ guide.utilisateur?.prenom }} {{ guide.utilisateur?.nom }}
          </option>
        </select>
      </div>
    </div>
    <template #actions>
      <button class="btn-secondary" @click="$emit('close')">Annuler</button>
      <button class="btn-primary" :disabled="loading" @click="$emit('submit')">
        {{ loading ? 'Creation...' : 'Creer le groupe' }}
      </button>
    </template>
  </DashboardModalShell>
</template>

<script setup>
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'

defineProps({
  form: { type: Object, required: true },
  guides: { type: Array, required: true },
  error: { type: String, default: '' },
  loading: { type: Boolean, default: false },
})

defineEmits(['close', 'submit'])
</script>
