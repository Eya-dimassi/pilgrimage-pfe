<template>
  <DashboardModalShell title="Nouveau guide" :error="error" @close="$emit('close')">
    <div class="form-grid">
      <div class="form-field"><label>Prenom *</label><input v-model="form.prenom" placeholder="Prenom" /></div>
      <div class="form-field"><label>Nom *</label><input v-model="form.nom" placeholder="Nom" /></div>
      <div class="form-field"><label>Email *</label><input v-model="form.email" type="email" placeholder="email@exemple.com" /></div>
      <div class="form-field full">
        <label>Telephone</label>
        <PhoneNumberField v-model="form.telephone" id="create-guide-phone" />
      </div>
      <div class="form-field full">
        <label>Specialite</label>
        <select v-model="form.specialite">
          <option value="">Aucune specialite</option>
          <option value="Hajj">Hajj</option>
          <option value="Umrah">Umrah</option>
          <option value="Bilingue">Bilingue (Arabe/Francais)</option>
          <option value="Medical">Formation medicale</option>
          <option value="Senior">Guide senior (10+ ans)</option>
        </select>
      </div>
    </div>
    <template #actions>
      <button class="btn-secondary" @click="$emit('close')">Annuler</button>
      <button class="btn-primary" :disabled="loading" @click="$emit('submit')">
        {{ loading ? 'Creation...' : 'Creer et envoyer email' }}
      </button>
    </template>
  </DashboardModalShell>
</template>

<script setup>
import PhoneNumberField from '@/components/forms/PhoneNumberField.vue'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'

defineProps({
  form: { type: Object, required: true },
  error: { type: String, default: '' },
  loading: { type: Boolean, default: false },
})

defineEmits(['close', 'submit'])
</script>
