<template>
  <DashboardModalShell title="Nouveau pelerin" :error="error" @close="$emit('close')">
    <div class="form-grid">
      <div class="form-field"><label>Prenom *</label><input v-model="form.prenom" placeholder="Prenom" /></div>
      <div class="form-field"><label>Nom *</label><input v-model="form.nom" placeholder="Nom" /></div>
      <div class="form-field"><label>Email *</label><input v-model="form.email" type="email" placeholder="email@exemple.com" /></div>
      <div class="form-field full">
        <label>Telephone</label>
        <PhoneNumberField v-model="form.telephone" id="create-pelerin-phone" />
      </div>
      <div class="form-field"><label>Date de naissance</label><input v-model="form.dateNaissance" type="date" /></div>
      <div class="form-field"><label>No Passeport</label><input v-model="form.numeroPasseport" placeholder="AB123456" /></div>
      <div class="form-field full">
        <label>Nationalite</label>
        <CountryAutocomplete v-model="form.nationalite" id="create-pelerin-country" placeholder="Rechercher un pays" />
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
import CountryAutocomplete from '@/components/forms/CountryAutocomplete.vue'
import PhoneNumberField from '@/components/forms/PhoneNumberField.vue'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'

defineProps({
  form: { type: Object, required: true },
  error: { type: String, default: '' },
  loading: { type: Boolean, default: false },
})

defineEmits(['close', 'submit'])
</script>
