<template>
  <div class="view-section planning-shell">
    <div class="planning-topbar">
      <div class="planning-group-picker">
        <label for="planning-group">Groupe</label>
        <select id="planning-group" v-model="selectedGroupId">
          <option v-for="groupe in groupes" :key="groupe.id" :value="groupe.id">
            {{ groupe.nom }} · {{ groupe.typeVoyage }} · {{ groupe.annee }}
          </option>
        </select>
      </div>

      <div v-if="selectedGroup" class="planning-summary">
        <span class="group-type-badge" :class="selectedGroup.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
          {{ selectedGroup.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra' }}
        </span>
        <span class="planning-summary-text">{{ tripRangeLabel }}</span>
      </div>
    </div>

    <div v-if="loading" class="state-center planning-state">
      <div class="spinner"></div>
      <p>Chargement du planning...</p>
    </div>

    <div v-else-if="error" class="state-center planning-state">
      <p class="error-text">{{ error }}</p>
      <button class="btn-primary" @click="loadPlanning">Reessayer</button>
    </div>

    <div v-else-if="!selectedGroup" class="empty-state planning-empty-card">
      <AppIcon name="layers" :size="42" :stroke-width="1.5" style="opacity: 0.24; margin-bottom: 12px" />
      <p class="planning-empty-title">Aucun groupe disponible</p>
      <p class="planning-empty-copy">Créez d'abord un groupe pour préparer son planning.</p>
    </div>

    <div v-else-if="!hasTripDates" class="empty-state planning-empty-card">
      <AppIcon name="alert" :size="42" :stroke-width="1.5" style="opacity: 0.24; margin-bottom: 12px" />
      <p class="planning-empty-title">Dates du voyage manquantes</p>
      <p class="planning-empty-copy">Définissez la date de départ et de retour du groupe pour activer le planning du voyage.</p>
    </div>

    <div v-else class="planning-workspace">
      <aside class="planning-sidebar">
        <div class="planning-sidebar-header">
          <div class="planning-group-card">
            <div class="planning-group-card-top">
              <h2 class="planning-group-title">{{ selectedGroup.nom }}</h2>
              <span class="group-type-badge" :class="selectedGroup.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
                {{ selectedGroup.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra' }}
              </span>
            </div>
            <p class="planning-group-range">{{ tripRangeLabel }} · {{ tripDurationLabel }}</p>
            <p class="planning-group-count">{{ plannedDaysCount }} journée(s) planifiée(s)</p>
          </div>
        </div>

        <div class="planning-sidebar-actions">
          <button
            class="planning-action-button is-primary"
            :disabled="saving || hajjGenerationBlocked"
            :title="hajjGenerationBlocked ? 'Renseignez d’abord la date du 8 Dhul Hijja' : ''"
            @click="generateTemplate"
          >
            <AppIcon name="sparkles" :size="16" />
            <span>Générer le modèle</span>
          </button>
          <button class="planning-action-button" :disabled="saving || !selectedDateKey" title="Créer une journée" @click="openDayModal()">
            <AppIcon name="calendar-plus" :size="16" />
            <span>Créer une journée</span>
          </button>
          <button
            class="planning-action-button"
            :disabled="saving || !plannedDaysCount"
            title="Décaler toutes les journées"
            @click="shiftPlanning()"
          >
            <AppIcon name="arrow-right-left" :size="16" />
            <span>Décaler le planning</span>
          </button>
          <button
            class="planning-action-button is-danger"
            :disabled="saving || !plannedDaysCount"
            title="Supprimer le planning"
            @click="deleteWholePlanning()"
          >
            <AppIcon name="trash" :size="16" />
            <span>Supprimer le planning</span>
          </button>
        </div>

        <div class="planning-sidebar-legend">
          <button
            type="button"
            :class="['planning-filter-chip', { active: dayFilter === 'all' }]"
            @click="dayFilter = 'all'"
          >
            Toutes
            <span>{{ tripDays.length }}</span>
          </button>
          <button
            type="button"
            :class="['planning-filter-chip', 'is-filled', { active: dayFilter === 'filled' }]"
            @click="dayFilter = 'filled'"
          >
            <span class="planning-legend-dot is-filled"></span>
            Journées remplies
            <span>{{ filledTripDaysCount }}</span>
          </button>
          <button
            type="button"
            :class="['planning-filter-chip', 'is-empty', { active: dayFilter === 'empty' }]"
            @click="dayFilter = 'empty'"
          >
            <span class="planning-legend-dot is-empty"></span>
            Journées vides
            <span>{{ emptyTripDaysCount }}</span>
          </button>
        </div>

        <div v-if="!filteredTripDays.length" class="planning-sidebar-empty">
          Aucune journée ne correspond à ce filtre.
        </div>

        <div v-else class="planning-day-list">
          <button
            v-for="day in filteredTripDays"
            :key="day.dateKey"
            :class="[
              'planning-day-item',
              {
                active: selectedDateKey === day.dateKey,
                empty: !planningByDate[day.dateKey],
                filled: !!planningByDate[day.dateKey],
              },
            ]"
            @click="selectedDateKey = day.dateKey"
          >
            <div class="planning-day-item-top">
              <span class="planning-day-number">{{ day.primaryDayLabel }}</span>
              <span class="planning-day-marker" :class="{ filled: !!planningByDate[day.dateKey] }"></span>
            </div>
            <div class="planning-day-date">{{ day.shortDateLong }}</div>
            <div v-if="day.secondaryDayLabel" class="planning-day-subline">{{ day.secondaryDayLabel }}</div>
            <div class="planning-day-preview">
              {{ formatSidebarDayTitle(planningByDate[day.dateKey]?.titre, day.dayNumber) }}
            </div>
            <div v-if="planningByDate[day.dateKey]" class="planning-day-meta">
              {{ planningByDate[day.dateKey].evenements?.length || 0 }} événement(s)
            </div>
          </button>
        </div>
      </aside>

      <section class="planning-main">
        <div class="planning-main-header">
          <div class="planning-main-copy">
            <p class="planning-main-kicker">{{ selectedDayHeading }}</p>
            <h3 class="planning-main-title">
              {{ selectedPlanning?.titre || suggestedDayTitle }}
            </h3>
            <p class="planning-main-subtitle">
              {{ selectedDayDateLabel }}
            </p>
          </div>

          <div class="planning-main-actions">
            <button
              v-if="selectedPlanning"
              class="planning-icon-button"
              title="Modifier la journée"
              @click="openDayModal(selectedPlanning)"
            >
              <AppIcon name="edit" :size="16" />
            </button>
            <button
              v-if="selectedPlanning"
              class="planning-icon-button is-danger"
              title="Supprimer la journée"
              @click="deleteDay(selectedPlanning)"
            >
              <AppIcon name="trash" :size="16" />
            </button>
            <button
              class="planning-icon-button is-primary"
              title="Ajouter un événement"
              @click="selectedPlanning ? openEventModal() : createSelectedDayQuick()"
            >
              <AppIcon name="plus" :size="16" />
            </button>
          </div>
        </div>

        <div class="planning-progress-row">
          <span class="planning-progress-label">{{ selectedDayProgressLabel }}</span>
          <div class="planning-progress-track">
            <div class="planning-progress-fill" :style="{ width: progressPercent }"></div>
          </div>
          <span class="planning-progress-meta">
            {{ selectedDayProgressPercent }} · {{ formatEventCount(selectedPlanning?.evenements?.length || 0) }}
          </span>
        </div>

        <div v-if="missingHajjStartDate" class="planning-hajj-setup">
          <div class="planning-hajj-setup-copy">
            <p class="planning-hajj-setup-title">Date du 8 Dhul Hijja requise</p>
            <p class="planning-hajj-setup-text">
              Pour générer le planning Hajj, indiquez ici la date grégorienne correspondant au début des jours fixes du Hajj.
            </p>
          </div>

          <div class="planning-hajj-setup-form">
            <div class="form-field">
              <label>8 Dhul Hijja</label>
              <input v-model="hajjStartDateInput" type="date" />
            </div>
            <button class="btn-primary" :disabled="saving || !hajjStartDateInput" @click="saveHajjStartDate">
              {{ saving ? 'Enregistrement...' : 'Enregistrer la date' }}
            </button>
          </div>
        </div>

        <div v-if="!selectedPlanning" class="planning-main-empty">
          <AppIcon name="calendar" :size="40" :stroke-width="1.5" style="opacity: 0.22; margin-bottom: 12px" />
          <p class="planning-empty-title">Aucun planning pour cette journée</p>
          <p class="planning-empty-copy">Ajoutez directement un événement et la journée sera créée automatiquement pour cette date.</p>
          <button class="btn-primary" @click="createSelectedDayQuick()">Ajouter un événement</button>
        </div>

        <template v-else>
          <div v-if="selectedPlanning.evenements?.length" class="planning-event-list">
            <article
              v-for="event in selectedPlanning.evenements"
              :key="event.id"
              class="planning-event-card"
            >
              <div class="planning-event-content">
                <h4 class="planning-event-title">{{ event.titre }}</h4>
                <div class="planning-event-location">
                  <template v-if="splitLieux(event.lieu).length">
                    <span v-for="lieu in splitLieux(event.lieu)" :key="lieu" class="planning-location-chip">
                      {{ lieu }}
                    </span>
                  </template>
                  <span v-else>Lieu à préciser</span>
                </div>
                <div class="planning-event-badges">
                  <span :class="['planning-type-pill', `is-${event.type.toLowerCase()}`]">
                    {{ formatEventType(event.type) }}
                  </span>
                  <span v-if="formatEventTime(event.heureDebutPrevue)" class="planning-time-pill">
                    Rendez-vous · {{ formatEventTime(event.heureDebutPrevue) }}
                  </span>
                </div>
                <p v-if="event.description" class="planning-event-description">{{ event.description }}</p>
              </div>

              <div class="planning-event-actions">
                <button class="act-btn" title="Modifier" @click="openEventModal(event)">
                  <AppIcon name="edit" :size="14" />
                </button>
                <button class="act-btn act-btn-danger" title="Supprimer" @click="deleteEvent(event)">
                  <AppIcon name="trash" :size="14" />
                </button>
              </div>
            </article>

            <button class="planning-add-inline" @click="openEventModal()">
              + Ajouter un événement à cette journée
            </button>
          </div>

          <div v-else class="planning-main-empty">
            <AppIcon name="calendar" :size="40" :stroke-width="1.5" style="opacity: 0.22; margin-bottom: 12px" />
            <p class="planning-empty-title">Aucun événement pour cette journée</p>
            <p class="planning-empty-copy">Ajoutez les lieux, activités et l heure de rendez-vous prévue pour ce jour.</p>
            <button class="btn-primary" @click="openEventModal()">Ajouter un événement</button>
          </div>
        </template>
      </section>
    </div>

    <DashboardModalShell
      v-if="showDayModal"
      :title="editingDayId ? 'Modifier la journée' : 'Créer une journée de planning'"
      :error="modalError"
      @close="closeDayModal"
    >
      <div class="form-grid">
        <div class="form-field">
          <label>Date</label>
          <input v-model="dayForm.date" type="date" />
        </div>
        <div class="form-field full">
          <label>Titre</label>
          <input v-model="dayForm.titre" :placeholder="suggestedDayTitle" />
        </div>
      </div>
      <template #actions>
        <button class="btn-secondary" @click="closeDayModal">Annuler</button>
        <button class="btn-primary" :disabled="saving" @click="submitDay">
          {{ saving ? 'Sauvegarde...' : 'Sauvegarder' }}
        </button>
      </template>
    </DashboardModalShell>

    <DashboardModalShell
      v-if="showEventModal"
      :title="editingEventId ? 'Modifier l’événement' : 'Ajouter un événement'"
      :error="modalError"
      @close="closeEventModal"
    >
      <div class="form-grid">
        <div class="form-field">
          <label>Type</label>
          <select v-model="eventForm.type">
            <option value="PRIERE">Prière</option>
            <option value="TRANSPORT">Transport</option>
            <option value="VISITE">Visite</option>
            <option value="REPAS">Repas</option>
            <option value="RITE">Rite</option>
            <option value="REPOS">Repos</option>
            <option value="AUTRE">Autre</option>
          </select>
        </div>
        <div class="form-field full">
          <label>Titre</label>
          <input v-model="eventForm.titre" placeholder="Départ vers Mina" />
        </div>
        <div class="form-field">
          <label>Lieu principal</label>
          <select v-model="eventForm.lieu">
            <option value="">Choisir un lieu</option>
            <option v-for="location in EVENT_LOCATION_OPTIONS" :key="location" :value="location">
              {{ location }}
            </option>
          </select>
        </div>
        <div class="form-field">
          <label>Heure de rendez-vous</label>
          <input v-model="eventForm.heure" type="time" />
        </div>
        <div class="form-field full">
          <label>Description</label>
          <input v-model="eventForm.description" placeholder="Détails pratiques ou rappel pour le groupe" />
        </div>
      </div>
      <template #actions>
        <button class="btn-secondary" @click="closeEventModal">Annuler</button>
        <button class="btn-primary" :disabled="saving || !selectedPlanning" @click="submitEvent">
          {{ saving ? 'Sauvegarde...' : 'Sauvegarder' }}
        </button>
      </template>
    </DashboardModalShell>

    <div v-if="toast.show" :class="['toast', toast.type]">{{ toast.message }}</div>
  </div>
</template>

<script setup>
import { computed, nextTick, ref, watch } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'
import {
  createAgencePlanningDay,
  deleteAgencePlanning,
  createAgencePlanningEvent,
  deleteAgencePlanningDay,
  deleteAgencePlanningEvent,
  fetchAgencePlanning,
  generateAgencePlanningTemplate,
  shiftAgencePlanning,
  updateAgenceGroupe,
  updateAgencePlanningDay,
  updateAgencePlanningEvent,
} from '@/features/agence/services/agence.service'

const EVENT_TYPE_LABELS = {
  PRIERE: 'Prière',
  TRANSPORT: 'Transport',
  VISITE: 'Visite',
  REPAS: 'Repas',
  RITE: 'Rite',
  REPOS: 'Repos',
  AUTRE: 'Autre',
}

const EVENT_LOCATION_OPTIONS = [
  'MAKKAH',
  'MINA',
  'ARAFAT',
  'MUZDALIFAH',
  'MEDINA',
]

const props = defineProps({
  groupes: {
    type: Array,
    default: () => [],
  },
  preselectedGroupId: {
    type: String,
    default: '',
  },
})

function toDateKey(value) {
  const date = parsePlanningDate(value)
  if (Number.isNaN(date.getTime())) return ''
  const astDate = new Date(date.getTime() + 3 * 60 * 60 * 1000)
  const year = astDate.getUTCFullYear()
  const month = String(astDate.getUTCMonth() + 1).padStart(2, '0')
  const day = String(astDate.getUTCDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function parsePlanningDate(value) {
  if (value instanceof Date) return new Date(value.getTime())
  const raw = String(value ?? '').trim()
  if (!raw) return new Date('')
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
    return new Date(`${raw}T00:00:00`)
  }
  return new Date(raw)
}

function formatShortDate(value) {
  const date = parsePlanningDate(value)
  return date.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' })
}

function formatEventType(value) {
  return EVENT_TYPE_LABELS[value] ?? value
}

function formatEventTime(value) {
  if (!value) return ''
  const date = parsePlanningDate(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
}

function splitLieux(value) {
  if (!value) return []
  return String(value)
    .split('•')
    .map((item) => item.trim())
    .filter(Boolean)
}

function formatEventCount(value) {
  return value > 1 ? `${value} événements` : `${value} événement`
}

function formatDateTimeLocal(value) {
  if (!value) return ''
  const date = parsePlanningDate(value)
  if (Number.isNaN(date.getTime())) return ''
  const tzOffset = date.getTimezoneOffset() * 60000
  return new Date(date.getTime() - tzOffset).toISOString().slice(0, 16)
}

function getPreferredDateKey(plannings, availableDays, fallbackDateKey = '') {
  const availableKeys = new Set(availableDays.map((day) => day.dateKey))
  const currentStillValid = fallbackDateKey && availableKeys.has(fallbackDateKey)
  if (currentStillValid) return fallbackDateKey

  const firstPlannedDateKey = (plannings ?? [])
    .map((planning) => toDateKey(planning.date))
    .find((dateKey) => availableKeys.has(dateKey))

  return firstPlannedDateKey ?? availableDays[0]?.dateKey ?? ''
}

const loading = ref(false)
const saving = ref(false)
const error = ref('')
const modalError = ref('')
const selectedGroupId = ref('')
const hajjStartDateInput = ref('')
const planningData = ref({ groupe: null, plannings: [], tripDays: [] })
const selectedDateKey = ref('')
const dayFilter = ref('all')
const showDayModal = ref(false)
const showEventModal = ref(false)
const editingDayId = ref('')
const editingEventId = ref('')
const dayForm = ref({ date: '', titre: '' })
const eventForm = ref({
  type: 'TRANSPORT',
  titre: '',
  description: '',
  lieu: '',
  heure: '',
})
const toast = ref({ show: false, message: '', type: 'success' })

const selectedGroup = computed(() => {
  if (planningData.value.groupe?.id === selectedGroupId.value) {
    return planningData.value.groupe
  }
  return props.groupes.find((group) => group.id === selectedGroupId.value) ?? null
})
const hasTripDates = computed(() => Boolean(selectedGroup.value?.dateDepart && selectedGroup.value?.dateRetour))
const missingHajjStartDate = computed(() => selectedGroup.value?.typeVoyage === 'HAJJ' && !selectedGroup.value?.hajjStartDate)
const hajjGenerationBlocked = computed(() => missingHajjStartDate.value)
const tripDays = computed(() => planningData.value.tripDays ?? [])
const planningByDate = computed(() =>
  Object.fromEntries((planningData.value.plannings ?? []).map((planning) => [toDateKey(planning.date), planning]))
)
const filledTripDaysCount = computed(() => tripDays.value.filter((day) => Boolean(planningByDate.value[day.dateKey])).length)
const emptyTripDaysCount = computed(() => Math.max(0, tripDays.value.length - filledTripDaysCount.value))
const filteredTripDays = computed(() => {
  if (dayFilter.value === 'filled') {
    return tripDays.value.filter((day) => Boolean(planningByDate.value[day.dateKey]))
  }
  if (dayFilter.value === 'empty') {
    return tripDays.value.filter((day) => !planningByDate.value[day.dateKey])
  }
  return tripDays.value
})
const selectedPlanning = computed(() => planningByDate.value[selectedDateKey.value] ?? null)
const selectedDay = computed(() => tripDays.value.find((item) => item.dateKey === selectedDateKey.value) ?? null)
const plannedDaysCount = computed(() => Object.keys(planningByDate.value).length)
const selectedDayHeading = computed(() => selectedDay.value?.primaryDayLabel ?? 'Sélectionnez une date')
const selectedDayDateLabel = computed(() => {
  if (!selectedDay.value) return 'Sélectionnez une date'
  return selectedDay.value.secondaryDayLabel
    ? `${selectedDay.value.label} · ${selectedDay.value.secondaryDayLabel}`
    : selectedDay.value.label
})
const tripDurationLabel = computed(() => {
  if (!tripDays.value.length) return 'A définir'
  return tripDays.value.length > 1 ? `${tripDays.value.length} jours` : '1 jour'
})
const groupStatusLabel = computed(() => {
  switch (selectedGroup.value?.status) {
    case 'EN_COURS':
      return 'En cours'
    case 'TERMINE':
      return 'Terminé'
    case 'ANNULE':
      return 'Annulé'
    case 'PLANIFIE':
    default:
      return 'Planifié'
  }
})
const tripRangeLabel = computed(() => {
  if (!selectedGroup.value?.dateDepart || !selectedGroup.value?.dateRetour) return 'Dates à définir'
  return `${formatShortDate(selectedGroup.value.dateDepart)} → ${formatShortDate(selectedGroup.value.dateRetour)}`
})
const suggestedDayTitle = computed(() => {
  if (!selectedDay.value) return 'Journée du voyage'
  return selectedDay.value.primaryDayLabel
})
const progressPercent = computed(() => {
  if (!selectedDay.value || !tripDays.value.length) return '0%'
  return `${Math.max(6, (selectedDay.value.dayNumber / tripDays.value.length) * 100)}%`
})
const selectedDayProgressPercent = computed(() => {
  if (!selectedDay.value || !tripDays.value.length) return '0%'
  return `${Math.round((selectedDay.value.dayNumber / tripDays.value.length) * 100)}%`
})
const selectedDayProgressLabel = computed(() => {
  if (!selectedDay.value) return 'Sélectionnez une date'
  return 'Progression du voyage'
})

function showToast(message, type = 'success') {
  toast.value = { show: true, message, type }
  window.setTimeout(() => {
    toast.value.show = false
  }, 6000)
}

function formatSidebarDayTitle(title, dayNumber) {
  if (!title) return 'Journée à définir'
  const cleaned = title.replace(new RegExp(`^Jour\\s+${dayNumber}\\s*[-·]\\s*`, 'i'), '').trim()
  return cleaned || title
}

async function saveHajjStartDate() {
  if (!selectedGroup.value || !hajjStartDateInput.value) return

  saving.value = true

  try {
    const updated = await updateAgenceGroupe(selectedGroup.value.id, {
      hajjStartDate: hajjStartDateInput.value,
    })

    const target = props.groupes.find((group) => group.id === selectedGroup.value?.id)
    if (target) {
      Object.assign(target, updated)
    }

    showToast('Date du 8 Dhul Hijja enregistrée')
  } catch (err) {
    showToast(err.response?.data?.message || err.message, 'error')
  } finally {
    saving.value = false
  }
}

async function loadPlanning() {
  if (!selectedGroupId.value) return

  loading.value = true
  error.value = ''

  try {
    planningData.value = await fetchAgencePlanning(selectedGroupId.value)
    const target = props.groupes.find((group) => group.id === selectedGroupId.value)
    if (target && planningData.value.groupe) {
      Object.assign(target, planningData.value.groupe)
    }

    const availableDays = planningData.value.tripDays ?? []
    selectedDateKey.value = getPreferredDateKey(planningData.value.plannings, availableDays, selectedDateKey.value)
  } catch (err) {
    error.value = err.response?.data?.message || err.message
  } finally {
    loading.value = false
  }
}

function openDayModal(planning = null) {
  modalError.value = ''
  editingDayId.value = planning?.id ?? ''
  dayForm.value = {
    date: planning ? toDateKey(planning.date) : selectedDateKey.value,
    titre: planning?.titre ?? (planning ? '' : suggestedDayTitle.value),
  }
  showDayModal.value = true
}

function closeDayModal() {
  showDayModal.value = false
  editingDayId.value = ''
  modalError.value = ''
}

function openEventModal(event = null) {
  modalError.value = ''
  editingEventId.value = event?.id ?? ''
  eventForm.value = {
    type: event?.type ?? 'TRANSPORT',
    titre: event?.titre ?? '',
    description: event?.description ?? '',
    lieu: event?.lieu ?? '',
    heure: event?.heureDebutPrevue ? formatDateTimeLocal(event.heureDebutPrevue).slice(11, 16) : '',
  }
  showEventModal.value = true
}

function closeEventModal() {
  showEventModal.value = false
  editingEventId.value = ''
  modalError.value = ''
}

function upsertPlanningDayLocally(planning) {
  if (!planning) return

  const nextPlannings = [...(planningData.value.plannings ?? [])]
  const index = nextPlannings.findIndex((item) => item.id === planning.id)

  if (index >= 0) {
    nextPlannings[index] = planning
  } else {
    nextPlannings.push(planning)
  }

  nextPlannings.sort((left, right) => parsePlanningDate(left.date) - parsePlanningDate(right.date))
  planningData.value = {
    ...planningData.value,
    plannings: nextPlannings,
  }
}

async function submitDay() {
  if (!dayForm.value.date) {
    modalError.value = 'La date est requise'
    return
  }

  saving.value = true
  modalError.value = ''

  try {
    if (editingDayId.value) {
      const updatedPlanning = await updateAgencePlanningDay(editingDayId.value, dayForm.value)
      upsertPlanningDayLocally(updatedPlanning)
      selectedDateKey.value = toDateKey(updatedPlanning.date)
      showToast('Journée mise à jour')
    } else {
      const createdPlanning = await createAgencePlanningDay(selectedGroupId.value, dayForm.value)
      upsertPlanningDayLocally(createdPlanning)
      selectedDateKey.value = toDateKey(createdPlanning.date)
      showToast('Journée créée')
    }

    closeDayModal()
    await loadPlanning()
  } catch (err) {
    modalError.value = err.response?.data?.message || err.message
  } finally {
    saving.value = false
  }
}

async function createSelectedDayQuick() {
  if (!selectedGroupId.value || !selectedDateKey.value) {
    showToast('Sélectionnez d’abord une journée du voyage', 'error')
    return
  }

  if (selectedPlanning.value) {
    openEventModal()
    return
  }

  saving.value = true
  modalError.value = ''

  try {
    const createdPlanning = await createAgencePlanningDay(selectedGroupId.value, {
      date: selectedDateKey.value,
      titre: suggestedDayTitle.value,
    })

    upsertPlanningDayLocally(createdPlanning)
    selectedDateKey.value = toDateKey(createdPlanning.date)
    await loadPlanning()
    await nextTick()
    showToast('Journée créée, ajoutez maintenant votre événement')
    const readyPlanning = planningData.value.plannings?.find((planning) => planning.id === createdPlanning.id) ?? selectedPlanning.value
    if (!readyPlanning) {
      showToast("La journée a bien été créée, mais elle n'est pas encore sélectionnée.", 'error')
      return
    }
    openEventModal()
  } catch (err) {
    showToast(err.response?.data?.message || err.message, 'error')
  } finally {
    saving.value = false
  }
}

async function submitEvent() {
  if (!selectedPlanning.value) {
    modalError.value = "Créez d'abord la journée de planning"
    return
  }

  if (!eventForm.value.titre) {
    modalError.value = 'Le titre est requis'
    return
  }

  if (!eventForm.value.heure) {
    modalError.value = "L'heure de rendez-vous est requise"
    return
  }

  saving.value = true
  modalError.value = ''

  try {
    const heureDebutPrevue = `${selectedDateKey.value}T${eventForm.value.heure}:00`
    const payload = {
      type: eventForm.value.type,
      titre: eventForm.value.titre,
      description: eventForm.value.description,
      lieu: eventForm.value.lieu,
      heureDebutPrevue,
    }

    if (editingEventId.value) {
      await updateAgencePlanningEvent(editingEventId.value, payload)
      showToast('Événement mis à jour')
    } else {
      await createAgencePlanningEvent(selectedPlanning.value.id, payload)
      showToast('Événement ajouté')
    }

    closeEventModal()
    await loadPlanning()
  } catch (err) {
    modalError.value = err.response?.data?.message || err.message
  } finally {
    saving.value = false
  }
}

async function deleteDay(planning) {
  if (!window.confirm('Supprimer cette journée de planning ?')) return

  try {
    await deleteAgencePlanningDay(planning.id)
    showToast('Journée supprimée')
    await loadPlanning()
  } catch (err) {
    showToast(err.response?.data?.message || err.message, 'error')
  }
}

async function deleteWholePlanning() {
  if (!selectedGroupId.value || !plannedDaysCount.value) return

  const confirmed = window.confirm(
    `Supprimer tout le planning de ce groupe ? ${plannedDaysCount.value} journée(s) seront supprimée(s).`
  )

  if (!confirmed) return

  try {
    const result = await deleteAgencePlanning(selectedGroupId.value)
    showToast(`${result.deletedDays || 0} journée(s) supprimée(s)`)
    await loadPlanning()
  } catch (err) {
    showToast(err.response?.data?.message || err.message, 'error')
  }
}

async function shiftPlanning() {
  if (!selectedGroupId.value || !plannedDaysCount.value) return

  const rawValue = window.prompt(
    'Décaler toutes les journées du voyage de combien de jour(s) ? Utilisez 1, -1, 2, etc.',
    '1'
  )

  if (rawValue == null) return

  const offsetDays = Number.parseInt(rawValue, 10)
  if (!Number.isInteger(offsetDays) || offsetDays === 0) {
    showToast('Entrez un nombre entier non nul', 'error')
    return
  }

  saving.value = true

  try {
    const result = await shiftAgencePlanning(selectedGroupId.value, { offsetDays })
    await loadPlanning()
    showToast(`${result.shiftedDays || 0} journée(s) décalée(s) de ${offsetDays} jour(s)`)
  } catch (err) {
    showToast(err.response?.data?.message || err.message, 'error')
  } finally {
    saving.value = false
  }
}

async function deleteEvent(event) {
  if (!window.confirm('Supprimer cet événement ?')) return

  try {
    await deleteAgencePlanningEvent(event.id)
    showToast('Événement supprimé')
    await loadPlanning()
  } catch (err) {
    showToast(err.response?.data?.message || err.message, 'error')
  }
}

async function generateTemplate() {
  if (!selectedGroupId.value || !selectedGroup.value) return

  const confirmed = window.confirm(
    `Générer le modèle ${selectedGroup.value.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra'} pour ce groupe ? Les journées déjà créées seront conservées.`
  )

  if (!confirmed) return

  saving.value = true

  try {
    const result = await generateAgencePlanningTemplate(selectedGroupId.value)
    await loadPlanning()

    showToast(
      `${result.createdDays} jour(s) et ${result.createdEvents} événement(s) générés${result.skippedDays ? ` · ${result.skippedDays} jour(s) conservés` : ''}`
    )
  } catch (err) {
    showToast(err.response?.data?.message || err.message, 'error')
  } finally {
    saving.value = false
  }
}

watch(
  () => props.groupes,
  (groupes) => {
    if (!selectedGroupId.value && groupes?.length) {
      selectedGroupId.value = groupes[0].id
    }
    if (selectedGroupId.value && !groupes.find((group) => group.id === selectedGroupId.value)) {
      selectedGroupId.value = groupes[0]?.id ?? ''
    }
  },
  { immediate: true, deep: true },
)

watch(
  () => props.preselectedGroupId,
  (groupId) => {
    if (!groupId) return
    if (groupId === selectedGroupId.value) return
    if (!props.groupes.some((group) => group.id === groupId)) return
    selectedGroupId.value = groupId
  },
  { immediate: true },
)

watch(
  [filteredTripDays, dayFilter],
  () => {
    if (!filteredTripDays.value.length) return
    const stillVisible = filteredTripDays.value.some((day) => day.dateKey === selectedDateKey.value)
    if (!stillVisible) {
      selectedDateKey.value = filteredTripDays.value[0].dateKey
    }
  },
  { immediate: true },
)

watch(
  () => selectedGroup.value?.hajjStartDate,
  (value) => {
    hajjStartDateInput.value = value ? toDateKey(value) : ''
  },
  { immediate: true },
)

watch(selectedGroupId, () => {
  selectedDateKey.value = ''
  planningData.value = { groupe: null, plannings: [], tripDays: [] }
  if (selectedGroupId.value) {
    loadPlanning()
  }
})
</script>

<style scoped>
.planning-shell {
  gap: 18px;
}

.planning-topbar {
  display: flex;
  flex-wrap: wrap;
  align-items: end;
  justify-content: space-between;
  gap: 14px;
}

.planning-group-picker {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 280px;
}

.planning-group-picker label {
  font-size: 11px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  color: var(--text2);
}

.planning-group-picker select {
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--bg2);
  color: var(--text);
  font-size: 13.5px;
  font-family: 'DM Sans', sans-serif;
}

.planning-summary {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.planning-summary-text {
  font-size: 13px;
  color: var(--text2);
}

.planning-workspace {
  display: grid;
  grid-template-columns: 300px minmax(0, 1fr);
  gap: 18px;
  height: calc(100vh - 220px);
  min-height: 620px;
}

.planning-sidebar,
.planning-main {
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: 18px;
  box-shadow: var(--shadow);
}

.planning-sidebar {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-height: 0;
}

.planning-sidebar-header {
  padding: 22px 20px 16px;
  border-bottom: 1px solid var(--border);
}

.planning-group-card {
  padding: 18px 18px 16px;
  border-radius: 18px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.88), rgba(255, 255, 255, 0.62));
  border: 1px solid rgba(201, 168, 76, 0.12);
}

.planning-group-card-top {
  display: flex;
  align-items: start;
  justify-content: space-between;
  gap: 12px;
}

.planning-group-title {
  margin: 0;
  font-family: 'Syne', sans-serif;
  font-size: 24px;
  line-height: 1.05;
}

.planning-group-range,
.planning-group-count {
  margin: 10px 0 0;
  font-size: 13px;
  color: var(--text2);
  font-weight: 600;
}

.planning-group-count {
  margin-top: 6px;
}

.planning-sidebar-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px 20px 10px;
}

.planning-action-button {
  width: 100%;
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  justify-content: flex-start;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.44);
  color: var(--text);
  cursor: pointer;
  padding: 0 14px;
  font-size: 14px;
  font-weight: 700;
  transition: transform 0.16s ease, border-color 0.16s ease, background 0.16s ease, color 0.16s ease;
}

.planning-action-button:hover:not(:disabled) {
  transform: translateY(-1px);
  border-color: rgba(201, 168, 76, 0.28);
  background: rgba(201, 168, 76, 0.08);
}

.planning-action-button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.planning-action-button.is-primary {
  background: rgba(201, 168, 76, 0.9);
  border-color: rgba(201, 168, 76, 0.9);
  color: white;
}

.planning-action-button.is-danger {
  color: var(--red);
}

.planning-action-button.is-danger:hover:not(:disabled) {
  border-color: rgba(248, 113, 113, 0.32);
  background: rgba(248, 113, 113, 0.08);
}

.planning-icon-button {
  width: 40px;
  height: 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--bg3);
  color: var(--text);
  cursor: pointer;
  transition: transform 0.16s ease, border-color 0.16s ease, background 0.16s ease, color 0.16s ease;
}

.planning-icon-button:hover:not(:disabled) {
  transform: translateY(-1px);
  border-color: rgba(201, 168, 76, 0.28);
  background: rgba(201, 168, 76, 0.08);
}

.planning-icon-button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.planning-icon-button.is-primary {
  background: rgba(201, 168, 76, 0.12);
  border-color: rgba(201, 168, 76, 0.28);
  color: var(--gold);
}

.planning-icon-button.is-danger {
  color: var(--red);
}

.planning-icon-button.is-danger:hover:not(:disabled) {
  border-color: rgba(248, 113, 113, 0.32);
  background: rgba(248, 113, 113, 0.08);
}

.planning-sidebar-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 0 20px 14px;
}

.planning-filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 5px 10px;
  border-radius: 999px;
  background: var(--bg3);
  border: 1px solid var(--border);
  color: var(--text2);
  font-size: 11.5px;
  font-weight: 600;
  cursor: pointer;
  transition: border-color 0.16s ease, background 0.16s ease, color 0.16s ease;
}

.planning-filter-chip span:last-child {
  font-weight: 800;
}

.planning-filter-chip:hover {
  border-color: rgba(201, 168, 76, 0.24);
}

.planning-filter-chip.active {
  background: rgba(201, 168, 76, 0.1);
  border-color: rgba(201, 168, 76, 0.28);
  color: var(--text);
}

.planning-filter-chip.is-filled.active {
  background: rgba(201, 168, 76, 0.12);
  border-color: rgba(201, 168, 76, 0.32);
}

.planning-filter-chip.is-empty.active {
  background: rgba(92, 146, 255, 0.1);
  border-color: rgba(92, 146, 255, 0.24);
  color: var(--text);
}

.planning-legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 7px;
}

.planning-legend-dot.is-filled {
  background: var(--gold);
}

.planning-legend-dot.is-empty {
  background: #7ea5ff;
}

.planning-legend-dot.is-prayer {
  background: var(--blue);
}

.planning-day-list {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 6px 12px 12px;
}

.planning-sidebar-empty {
  margin: 0 20px 12px;
  padding: 12px 14px;
  border-radius: 12px;
  border: 1px dashed var(--border);
  color: var(--text2);
  font-size: 12.5px;
  text-align: center;
}

.planning-day-item {
  width: 100%;
  text-align: left;
  padding: 14px;
  border-radius: 14px;
  border: 1px solid transparent;
  background: transparent;
  color: var(--text);
  cursor: pointer;
  transition: background 0.16s ease, border-color 0.16s ease, transform 0.16s ease;
  margin-bottom: 6px;
}

.planning-day-item:hover {
  background: var(--bg3);
  border-color: rgba(201, 168, 76, 0.18);
}

.planning-day-item.active {
  background: rgba(201, 168, 76, 0.08);
  border-color: rgba(201, 168, 76, 0.28);
}

.planning-day-item.filled {
  background: linear-gradient(180deg, rgba(201, 168, 76, 0.05), transparent);
}

.planning-day-item.empty {
  opacity: 0.75;
}

.planning-day-item-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.planning-day-number {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--gold);
}

.planning-day-marker {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--border);
  flex-shrink: 0;
}

.planning-day-marker.filled {
  background: var(--gold);
}

.planning-day-date {
  margin-top: 6px;
  font-size: 14px;
  font-weight: 700;
  color: var(--text);
}

.planning-day-subline {
  margin-top: 4px;
  font-size: 11.5px;
  font-weight: 700;
  color: var(--text2);
}

.planning-day-preview {
  margin-top: 6px;
  font-size: 13px;
  font-weight: 700;
  color: var(--text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.planning-day-meta {
  margin-top: 8px;
  font-size: 12px;
  color: var(--text2);
}

.planning-main {
  padding: 24px 24px 22px;
  display: flex;
  flex-direction: column;
  gap: 18px;
  min-width: 0;
  min-height: 0;
  overflow-y: auto;
}

.planning-main-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: start;
  padding-bottom: 18px;
  border-bottom: 1px solid rgba(201, 168, 76, 0.12);
}

.planning-main-copy {
  min-width: 0;
}

.planning-main-kicker {
  margin: 0 0 6px;
  color: var(--gold);
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.planning-main-title {
  margin: 0;
  font-family: 'Syne', sans-serif;
  font-size: 34px;
  line-height: 0.98;
  max-width: 680px;
}

.planning-main-subtitle {
  margin: 10px 0 0;
  color: var(--text2);
  font-size: 15px;
}

.planning-main-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.planning-progress-row {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  gap: 12px;
  align-items: center;
}

.planning-progress-label,
.planning-progress-meta {
  font-size: 13px;
  font-weight: 700;
  color: var(--text2);
}

.planning-progress-track {
  height: 6px;
  border-radius: 999px;
  background: var(--bg3);
  overflow: hidden;
}

.planning-progress-fill {
  height: 100%;
  border-radius: 999px;
  background: linear-gradient(90deg, var(--gold), #e4bd58);
}

.planning-hajj-setup {
  display: flex;
  flex-wrap: wrap;
  align-items: end;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 20px;
  border-radius: 16px;
  border: 1px solid rgba(201, 168, 76, 0.22);
  background: rgba(201, 168, 76, 0.06);
}

.planning-hajj-setup-copy {
  max-width: 560px;
}

.planning-hajj-setup-title {
  margin: 0 0 6px;
  font-size: 15px;
  font-weight: 800;
  color: var(--text);
}

.planning-hajj-setup-text {
  margin: 0;
  color: var(--text2);
  font-size: 13px;
}

.planning-hajj-setup-form {
  display: flex;
  align-items: end;
  gap: 12px;
  flex-wrap: wrap;
}

.planning-hajj-setup-form .form-field {
  min-width: 190px;
  margin: 0;
}

.planning-main-empty {
  flex: 1;
  min-height: 300px;
  border: 1px dashed var(--border);
  border-radius: 18px;
  background: linear-gradient(180deg, rgba(201, 168, 76, 0.03), transparent);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 26px;
}

.planning-empty-title {
  margin: 0 0 6px;
  font-size: 16px;
  font-weight: 700;
}

.planning-empty-copy {
  margin: 0 0 16px;
  color: var(--text2);
  font-size: 13px;
  max-width: 420px;
}

.planning-event-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.planning-add-inline {
  width: 100%;
  min-height: 54px;
  border-radius: 16px;
  border: 1px dashed rgba(201, 168, 76, 0.28);
  background: transparent;
  color: var(--text2);
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: border-color 0.16s ease, color 0.16s ease, background 0.16s ease;
}

.planning-add-inline:hover {
  border-color: rgba(201, 168, 76, 0.48);
  color: var(--gold);
  background: rgba(201, 168, 76, 0.04);
}

.planning-event-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 18px;
  align-items: start;
  padding: 18px 18px;
  border-radius: 18px;
  border: 1px solid var(--border);
  background: var(--bg2);
  transition: border-color 0.16s ease, transform 0.16s ease, box-shadow 0.16s ease;
}

.planning-event-card:hover {
  border-color: rgba(201, 168, 76, 0.22);
  transform: translateY(-1px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.06);
}

.planning-event-content {
  min-width: 0;
}

.planning-event-title {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--text);
}

.planning-event-location {
  margin: 8px 0 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  color: var(--text2);
  font-size: 14px;
  font-weight: 600;
}

.planning-location-chip {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--border);
  color: var(--text2);
  font-size: 11.5px;
  font-weight: 700;
}

.planning-event-badges {
  margin-top: 12px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.planning-type-pill,
.planning-time-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 28px;
  padding: 4px 11px;
  border-radius: 999px;
  font-size: 11.5px;
  font-weight: 700;
  border: 1px solid transparent;
}

.planning-type-pill.is-priere {
  background: rgba(74, 158, 255, 0.12);
  color: var(--blue);
}

.planning-type-pill.is-transport {
  background: rgba(92, 146, 255, 0.12);
  color: #4d85ff;
}

.planning-type-pill.is-visite {
  background: rgba(80, 205, 137, 0.14);
  color: #248a4b;
}

.planning-type-pill.is-repas {
  background: rgba(255, 174, 102, 0.16);
  color: #b86a1a;
}

.planning-type-pill.is-repos {
  background: rgba(173, 183, 201, 0.16);
  color: #667287;
}

.planning-type-pill.is-rite {
  background: rgba(201, 168, 76, 0.16);
  color: #9b7b1d;
}

.planning-type-pill.is-autre {
  background: rgba(125, 125, 125, 0.12);
  color: var(--text2);
}

.planning-time-pill {
  background: rgba(201, 168, 76, 0.1);
  color: #8c6b12;
  border: 1px solid rgba(201, 168, 76, 0.18);
}


.planning-event-description {
  margin: 10px 0 0;
  font-size: 13px;
  color: var(--text2);
}

.planning-event-actions {
  display: flex;
  gap: 6px;
  opacity: 0;
  pointer-events: none;
  transform: translateY(4px);
  transition: opacity 0.16s ease, transform 0.16s ease;
}

.planning-event-card:hover .planning-event-actions {
  opacity: 1;
  pointer-events: auto;
  transform: translateY(0);
}

.planning-state,
.planning-empty-card {
  min-height: 240px;
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: 18px;
}

@media (max-width: 1080px) {
  .planning-workspace {
    grid-template-columns: 1fr;
    height: auto;
  }

  .planning-sidebar {
    max-height: 360px;
  }
}

@media (max-width: 920px) {
  .planning-main-header,
  .planning-progress-row {
    display: flex;
    flex-direction: column;
    align-items: stretch;
  }

  .planning-main-actions {
    justify-content: flex-start;
  }

  .planning-event-card {
    grid-template-columns: 1fr;
  }

  .planning-event-actions {
    opacity: 1;
    pointer-events: auto;
    transform: none;
  }
}
</style>

