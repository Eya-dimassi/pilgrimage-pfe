<template>
  <DashboardModalShell :title="title" :error="error" @close="$emit('close')">
    <div class="form-grid">
      <template v-if="editType !== 'groupe'">
        <div class="form-field"><label>Prenom</label><input v-model="form.prenom" /></div>
        <div class="form-field"><label>Nom</label><input v-model="form.nom" /></div>
        <div class="form-field full">
          <label>Telephone</label>
          <PhoneNumberField v-model="form.telephone" :id="`${editType}-edit-phone`" />
        </div>
      </template>
      <template v-if="editType === 'pelerin'">
        <div class="form-field">
          <label>Nationalite</label>
          <CountryAutocomplete v-model="form.nationalite" :id="`${editType}-edit-country`" />
        </div>
        <div class="form-field"><label>No Passeport</label><input v-model="form.numeroPasseport" /></div>
      </template>
      <template v-if="editType === 'guide'">
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
      </template>
      <template v-if="editType === 'groupe'">
        <div class="form-field full"><label>Nom</label><input v-model="form.nom" /></div>
        <div class="form-field"><label>Annee</label><input v-model="form.annee" type="number" /></div>
        <div class="form-field">
          <label>Type</label>
          <select v-model="form.typeVoyage">
            <option value="HAJJ">Hajj</option>
            <option value="UMRAH">Umrah</option>
          </select>
        </div>
        <div class="form-field full"><label>Description</label><input v-model="form.description" /></div>
        <div class="form-field full">
          <label>Guide</label>
          <select v-model="form.guideId">
            <option value="">Sans guide</option>
            <option v-for="guide in guides" :key="guide.id" :value="guide.id">
              {{ guide.utilisateur?.prenom }} {{ guide.utilisateur?.nom }}
            </option>
          </select>
        </div>
      </template>
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
import { computed } from 'vue'
import CountryAutocomplete from '@/components/forms/CountryAutocomplete.vue'
import PhoneNumberField from '@/components/forms/PhoneNumberField.vue'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'

const props = defineProps({
  form: { type: Object, required: true },
  editType: { type: String, required: true },
  guides: { type: Array, required: true },
  error: { type: String, default: '' },
  loading: { type: Boolean, default: false },
})

defineEmits(['close', 'submit'])

const title = computed(() => (
  props.editType === 'pelerin'
    ? 'Modifier le pelerin'
    : props.editType === 'guide'
      ? 'Modifier le guide'
      : 'Modifier le groupe'
))
</script>
