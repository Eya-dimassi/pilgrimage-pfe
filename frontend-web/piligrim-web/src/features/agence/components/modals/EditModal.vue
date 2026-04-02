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
        <div class="form-field full">
          <label>Statut</label>
          <select v-model="form.status">
            <option value="PLANIFIE">Planifie</option>
            <option value="EN_COURS">En cours</option>
            <option value="TERMINE">Termine</option>
            <option value="ANNULE">Annule</option>
          </select>
        </div>
        <div class="form-field"><label>Date depart</label><input v-model="form.dateDepart" type="date" /></div>
        <div class="form-field"><label>Date retour</label><input v-model="form.dateRetour" type="date" /></div>
        <div class="form-field full"><label>Description</label><input v-model="form.description" /></div>
        <div class="form-field full">
          <label>Guides</label>

          <div class="multi-select" @click="guideDropdownOpen = !guideDropdownOpen">
            <div class="multi-select-value">{{ guideSelectedLabel }}</div>
            <AppIcon :name="guideDropdownOpen ? 'chevron-up' : 'chevron-down'" :size="14" />
          </div>

          <div v-if="guideDropdownOpen" class="multi-select-menu" @click.stop>
            <input v-model="guideSearch" class="multi-select-search" placeholder="Rechercher un guide..." />

            <div v-if="filteredGuides.length === 0" class="multi-select-empty">
              Aucun guide disponible
            </div>

            <label v-for="guide in filteredGuides" :key="guide.id" class="multi-select-option">
              <input type="checkbox" :value="guide.id" v-model="form.guideIds" />
              <span>{{ guide.utilisateur?.prenom }} {{ guide.utilisateur?.nom }}</span>
            </label>
          </div>
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
import { computed, ref } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
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

if (props.editType === 'groupe' && !Array.isArray(props.form.guideIds)) {
  props.form.guideIds = []
}

const guideDropdownOpen = ref(false)
const guideSearch = ref('')

const selectedGuideIds = computed(() => (Array.isArray(props.form.guideIds) ? props.form.guideIds.filter(Boolean) : []))

const filteredGuides = computed(() => {
  if (props.editType !== 'groupe') return []

  const query = guideSearch.value.trim().toLowerCase()
  if (!query) return props.guides

  return props.guides.filter((g) => {
    const full = `${g.utilisateur?.prenom ?? ''} ${g.utilisateur?.nom ?? ''}`.trim().toLowerCase()
    return full.includes(query)
  })
})

const guideSelectedLabel = computed(() => {
  if (props.editType !== 'groupe') return ''

  const count = selectedGuideIds.value.length
  if (count === 0) return 'Selectionner des guides'
  if (count === 1) {
    const id = selectedGuideIds.value[0]
    const g = props.guides.find((item) => item.id === id)
    if (!g) return '1 guide selectionne'
    return `${g.utilisateur?.prenom ?? ''} ${g.utilisateur?.nom ?? ''}`.trim() || '1 guide selectionne'
  }
  return `${count} guides selectionnes`
})
</script>
