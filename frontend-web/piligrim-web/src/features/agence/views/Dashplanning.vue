<template>
  <div class="view-section planning-shell">
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

    <div v-else class="planning-page">
      <section class="planning-card planning-hero-card">
        <div class="planning-hero-top">
          <div class="planning-select-summary">
            <span class="group-type-badge" :class="selectedGroup.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
              {{ selectedGroup.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra' }}
            </span>
            <span class="planning-select-text">{{ groupStatusLabel }}</span>
          </div>

          <div class="planning-group-picker planning-group-picker--inline">
            <label for="planning-group">Groupe</label>
            <select id="planning-group" v-model="selectedGroupId">
              <option v-for="groupe in groupes" :key="groupe.id" :value="groupe.id">
                {{ groupe.nom }} · {{ groupe.typeVoyage }} · {{ groupe.annee }}
              </option>
            </select>
          </div>
        </div>

        <div class="planning-hero-copy">
          <p class="planning-hero-kicker">Planning du voyage</p>
          <div class="planning-hero-heading-row">
            <h2 class="planning-hero-title">{{ selectedGroup.nom }}</h2>
            <div class="planning-hero-subtitle planning-inline-meta">
              <span>{{ tripRangeLabel }}</span>
              <span>{{ selectedGroup.typeVoyage }}</span>
              <span>{{ totalPelerins }} pèlerin<span v-if="totalPelerins > 1">s</span></span>
            </div>
          </div>
        </div>

        <div class="planning-hero-actions">
          <button
            class="planning-action-button"
            :disabled="saving || hajjGenerationBlocked"
            :title="hajjGenerationBlocked ? 'Renseignez d’abord la date du 8 Dhul Hijja' : ''"
            @click="generateTemplate"
          >
            <AppIcon name="sparkles" :size="16" />
            <span>Générer modèle {{ selectedGroup.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra' }}</span>
          </button>
          <button
            class="planning-action-button"
            :disabled="saving || !selectedDateKey"
            @click="openDayModal()"
          >
            <AppIcon name="calendar-plus" :size="16" />
            <span>Créer une journée</span>
          </button>
          <button
            class="planning-action-button"
            :disabled="saving || !plannedDaysCount"
            @click="openShiftModal"
          >
            <AppIcon name="arrow-right-left" :size="16" />
            <span>Décaler</span>
          </button>
          <button
            class="planning-action-button planning-action-button--primary"
            :disabled="saving || !selectedDateKey"
            @click="selectedPlanning ? openEventModal() : createSelectedDayQuick()"
          >
            <AppIcon name="plus" :size="16" />
            <span>Ajouter un événement</span>
          </button>
        </div>
      </section>

      <section class="planning-card planning-days-card">
        <div class="planning-section-head">
          <h3><AppIcon name="calendar" :size="16" /> Jours du voyage</h3>
          <span>{{ tripRangeLabel }}</span>
        </div>

        <div v-if="!filteredTripDays.length" class="planning-inline-empty">
          Aucune journée disponible pour ce voyage.
        </div>

        <div v-else class="planning-day-rail">
          <button
            v-for="day in filteredTripDays"
            :key="day.dateKey"
            :class="[
              'planning-day-card',
              { active: selectedDateKey === day.dateKey },
              { empty: !(planningByDate[day.dateKey]?.evenements?.length) }
            ]"
            @click="selectedDateKey = day.dateKey"
          >
            <span class="planning-day-card-kicker">{{ day.primaryDayLabel }}</span>
            <div class="planning-day-card-date">
              <strong class="planning-day-card-number">{{ day.calendarDay }}</strong>
              <span class="planning-day-card-month">{{ getDayMonthShort(day) }}</span>
            </div>
            <strong class="planning-day-card-title">{{ getWeekdayLabel(day) }}</strong>
            <span class="planning-day-card-meta">{{ getDayLocationLabel(day) }}</span>
            <span class="planning-day-card-count">
              {{ formatEventCount(planningByDate[day.dateKey]?.evenements?.length ?? 0) }}
            </span>
          </button>
        </div>
      </section>

      <section class="planning-card planning-detail-card">
        <div class="planning-detail-head">
          <div class="planning-detail-copy">
            <p class="planning-detail-kicker">Jour sélectionné</p>
            <h3 class="planning-detail-title">{{ selectedPlanning?.titre || suggestedDayTitle }}</h3>
            <div class="planning-detail-subtitle planning-inline-meta">
              <span><AppIcon name="calendar" :size="14" /> {{ selectedDayDateLabel }}</span>
              <span><AppIcon name="map-pin" :size="14" /> {{ selectedDayPrimaryLieu }}</span>
              <span><AppIcon name="list" :size="14" /> {{ formatEventCount(selectedPlanning?.evenements?.length || 0) }}</span>
            </div>
          </div>

          <div v-if="selectedPlanning" class="planning-detail-actions">
            <button class="planning-secondary-button" @click="openDayModal(selectedPlanning)">
              <AppIcon name="edit" :size="15" />
              <span>Modifier la journée</span>
            </button>
            <button class="planning-secondary-button" @click="deleteDay(selectedPlanning)">
              <AppIcon name="trash" :size="15" />
              <span>Supprimer la journée</span>
            </button>
          </div>
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

        <template v-if="selectedPlanning">
          <div v-if="selectedPlanning.evenements?.length" class="planning-event-list">
            <article
              v-for="event in selectedPlanning.evenements"
              :key="event.id"
              class="planning-event-row"
              :class="`is-${event.type.toLowerCase()}`"
            >
              <div class="planning-event-time">
                <span class="planning-event-time-main">{{ formatEventTime(event.heureDebutPrevue) || '--:--' }}</span>
                <span class="planning-event-time-label">Rendez-vous</span>
              </div>

              <div class="planning-event-copy">
                <h4 class="planning-event-title">{{ event.titre }}</h4>
                <p class="planning-event-location-line">
                  <AppIcon name="map-pin" :size="13" />
                  {{ getEventFallbackDescription(event) }}
                </p>
                <p v-if="event.description" class="planning-event-description">
                  {{ event.description }}
                </p>
              </div>

              <div class="planning-event-side">
                <div class="planning-event-badges">
                  <span :class="['planning-type-pill', `is-${event.type.toLowerCase()}`]">
                    {{ formatEventType(event.type) }}
                  </span>
                  <span v-if="event.etape" class="planning-etape-pill">
                    {{ event.etape }}
                  </span>
                </div>

                <div class="planning-event-actions">
                  <button class="act-btn" title="Modifier" @click="openEventModal(event)">
                    <AppIcon name="edit" :size="14" />
                  </button>
                  <button class="act-btn act-btn-danger" title="Supprimer" @click="deleteEvent(event)">
                    <AppIcon name="trash" :size="14" />
                  </button>
                </div>
              </div>
            </article>
          </div>

          <div v-else class="planning-main-empty">
            <AppIcon name="calendar" :size="40" :stroke-width="1.5" style="opacity: 0.22; margin-bottom: 12px" />
            <p class="planning-empty-title">Aucun événement pour cette journée</p>
            <p class="planning-empty-copy">Ajoutez les lieux, activités et l’heure de rendez-vous prévue pour ce jour.</p>
          </div>

          <button class="planning-primary-wide" @click="openEventModal()">
            <AppIcon name="plus" :size="16" />
            Ajouter un événement
          </button>
        </template>

        <template v-else>
          <div class="planning-main-empty">
            <AppIcon name="calendar" :size="40" :stroke-width="1.5" style="opacity: 0.22; margin-bottom: 12px" />
            <p class="planning-empty-title">Aucun planning pour cette journée</p>
            <p class="planning-empty-copy">Ajoutez directement un événement et la journée sera créée automatiquement pour cette date.</p>
          </div>

          <button class="planning-primary-wide" @click="createSelectedDayQuick()">
            <AppIcon name="plus" :size="16" />
            Ajouter un événement
          </button>
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
      v-if="showShiftModal"
      title="Décaler le planning"
      :error="modalError"
      @close="closeShiftModal"
    >
      <div class="form-grid">
        <div class="form-field full">
          <label>Décalage en jours</label>
          <input v-model.number="shiftForm.offsetDays" type="number" min="-14" max="14" step="1" />
        </div>
      </div>
      <template #actions>
        <button class="btn-secondary" @click="closeShiftModal">Annuler</button>
        <button class="btn-primary" :disabled="saving" @click="submitShift">
          {{ saving ? 'Décalage...' : 'Décaler' }}
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
const showDayModal = ref(false)
const showEventModal = ref(false)
const showShiftModal = ref(false)
const editingDayId = ref('')
const editingEventId = ref('')
const dayForm = ref({ date: '', titre: '' })
const shiftForm = ref({ offsetDays: 1 })
const eventForm = ref({
  type: 'TRANSPORT',
  titre: '',
  description: '',
  lieu: '',
  heure: '',
})
const toast = ref({ show: false, message: '', type: 'success' })

const selectedGroup = computed(() => {
  const listedGroup = props.groupes.find((group) => group.id === selectedGroupId.value)
  if (planningData.value.groupe?.id === selectedGroupId.value) {
    return {
      ...(listedGroup ?? {}),
      ...planningData.value.groupe,
      _count: listedGroup?._count ?? planningData.value.groupe?._count,
      pelerins: listedGroup?.pelerins ?? planningData.value.groupe?.pelerins,
    }
  }
  return listedGroup ?? null
})
const hasTripDates = computed(() => Boolean(selectedGroup.value?.dateDepart && selectedGroup.value?.dateRetour))
const missingHajjStartDate = computed(() => selectedGroup.value?.typeVoyage === 'HAJJ' && !selectedGroup.value?.hajjStartDate)
const hajjGenerationBlocked = computed(() => missingHajjStartDate.value)
const tripDays = computed(() => planningData.value.tripDays ?? [])
const planningByDate = computed(() =>
  Object.fromEntries((planningData.value.plannings ?? []).map((planning) => [toDateKey(planning.date), planning]))
)
const filteredTripDays = computed(() => tripDays.value)

function getDayLocationLabel(day) {
  const firstEventLieu = planningByDate.value[day.dateKey]?.evenements?.[0]?.lieu
  const resolvedLieu = splitLieux(firstEventLieu)[0] || day.locationLabel
  return resolvedLieu || '—'
}
const selectedPlanning = computed(() => planningByDate.value[selectedDateKey.value] ?? null)
const selectedDay = computed(() => tripDays.value.find((item) => item.dateKey === selectedDateKey.value) ?? null)
const selectedDayDateLabel = computed(() => {
  if (!selectedDay.value) return 'Sélectionnez une date'
  return selectedDay.value.secondaryDayLabel
    ? `${selectedDay.value.label} · ${selectedDay.value.secondaryDayLabel}`
    : selectedDay.value.label
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
const plannedDaysCount = computed(() => planningData.value.plannings?.length ?? 0)
const suggestedDayTitle = computed(() => {
  if (!selectedDay.value) return 'Journée du voyage'
  return selectedDay.value.primaryDayLabel
})
const totalPelerins = computed(() => selectedGroup.value?._count?.pelerins ?? selectedGroup.value?.pelerins?.length ?? 0)
const selectedDayPrimaryLieu = computed(() => {
  const firstLieu = selectedPlanning.value?.evenements?.[0]?.lieu
  return splitLieux(firstLieu)[0] || 'Lieu à préciser'
})

function showToast(message, type = 'success') {
  toast.value = { show: true, message, type }
  window.setTimeout(() => {
    toast.value.show = false
  }, 6000)
}

function getEventFallbackDescription(event) {
  const lieux = splitLieux(event?.lieu)
  return lieux.length ? lieux.join(' → ') : 'Détails à préciser'
}

function getWeekdayLabel(day) {
  const date = parsePlanningDate(day?.date)
  if (Number.isNaN(date.getTime())) return day?.label ?? ''
  return date.toLocaleDateString('fr-FR', { weekday: 'long' })
}

function getDayMonthShort(day) {
  const date = parsePlanningDate(day?.date)
  if (Number.isNaN(date.getTime())) return day?.monthShort ?? ''
  return date.toLocaleDateString('fr-FR', { month: 'short' }).replace('.', '')
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

function openShiftModal() {
  modalError.value = ''
  shiftForm.value = { offsetDays: 1 }
  showShiftModal.value = true
}

function closeShiftModal() {
  showShiftModal.value = false
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

async function submitShift() {
  const offsetDays = Number(shiftForm.value.offsetDays)

  if (!Number.isInteger(offsetDays) || offsetDays === 0) {
    modalError.value = 'Le décalage doit être un entier non nul'
    return
  }

  saving.value = true
  modalError.value = ''

  try {
    const result = await shiftAgencePlanning(selectedGroupId.value, { offsetDays })
    closeShiftModal()
    await loadPlanning()
    showToast(`${result.shiftedDays} journée(s) décalée(s)`)
  } catch (err) {
    modalError.value = err.response?.data?.message || err.message
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
  filteredTripDays,
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
}, { immediate: true })
</script>

<style scoped>
.planning-shell {
  gap: 18px;
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
  letter-spacing: 0.08em;
  color: var(--text2);
}

.planning-group-picker select {
  min-height: 48px;
  padding: 0 14px;
  border-radius: 14px;
  border: 1px solid #e6ddd1;
  background: #fffdfa;
  color: #20170f;
  font-size: 14px;
  font-family: 'DM Sans', sans-serif;
}

.planning-page {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.planning-card,
.planning-state,
.planning-empty-card {
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.98), rgba(255, 251, 245, 0.98));
  border: 1px solid #ece2d6;
  border-radius: 18px;
  box-shadow: 0 10px 28px rgba(34, 26, 15, 0.05);
}

.planning-select-summary {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.planning-select-text {
  font-size: 13px;
  font-weight: 700;
  color: #7a6f62;
}

.planning-hero-card,
.planning-days-card,
.planning-detail-card {
  padding: 18px 20px;
}

.planning-hero-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.planning-hero-top {
  display: flex;
  align-items: end;
  justify-content: space-between;
  gap: 14px;
  flex-wrap: wrap;
}

.planning-group-picker--inline {
  min-width: 260px;
  max-width: 420px;
  margin-left: auto;
}

.planning-group-picker--inline label {
  font-size: 10px;
}

.planning-group-picker--inline select {
  min-height: 40px;
  padding: 0 12px;
  border-radius: 12px;
  font-size: 13px;
}

.planning-hero-kicker,
.planning-detail-kicker {
  margin: 0 0 4px;
  color: var(--gold);
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.planning-hero-title,
.planning-detail-title {
  margin: 0;
  font-family: 'Syne', sans-serif;
  color: #17120c;
}

.planning-hero-title {
  font-size: clamp(24px, 2.4vw, 31px);
  line-height: 1;
}

.planning-detail-title {
  font-size: clamp(24px, 2.5vw, 32px);
  line-height: 1;
}

.planning-hero-heading-row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 14px;
  flex-wrap: wrap;
}

.planning-hero-subtitle,
.planning-detail-subtitle {
  margin: 0;
  color: #786c5e;
  font-size: 14px;
  font-weight: 600;
}

.planning-inline-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 12px;
}

.planning-inline-meta span {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.planning-hero-actions,
.planning-detail-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.planning-action-button,
.planning-secondary-button,
.planning-primary-wide {
  min-height: 42px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 0 16px;
  border-radius: 14px;
  border: 1px solid #dfd2c2;
  background: #fffdfa;
  color: #20170f;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.16s ease, border-color 0.16s ease, background 0.16s ease;
}

.planning-action-button:hover:not(:disabled),
.planning-secondary-button:hover:not(:disabled),
.planning-primary-wide:hover:not(:disabled) {
  transform: translateY(-1px);
  border-color: #d4b574;
  background: #fff7e8;
}

.planning-action-button:disabled,
.planning-secondary-button:disabled,
.planning-primary-wide:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.planning-action-button--primary {
  background: #d8b04d;
  border-color: #d8b04d;
  color: #231907;
}

.planning-action-button--primary:hover:not(:disabled) {
  background: #dfba61;
  border-color: #dfba61;
}

.planning-section-head,
.planning-detail-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 18px;
  flex-wrap: wrap;
}

.planning-section-head {
  margin-bottom: 12px;
}

.planning-section-head h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 800;
  color: #17120c;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.planning-section-head span {
  color: #7a6f62;
  font-size: 14px;
  font-weight: 700;
}

.planning-inline-empty {
  min-height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px dashed #e5dbce;
  border-radius: 18px;
  color: #877b6c;
}

.planning-day-rail {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(136px, 156px);
  grid-template-columns: none;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.planning-day-card {
  min-height: 132px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 6px;
  text-align: left;
  border-radius: 16px;
  border: 1px solid #d8b04d;
  background: #fff8ea;
  color: #20170f;
  cursor: pointer;
  transition: border-color 0.16s ease, background 0.16s ease, transform 0.16s ease, box-shadow 0.16s ease;
}

.planning-day-card:hover {
  transform: translateY(-1px);
  border-color: #cda13b;
}

.planning-day-card.active {
  background: #fff2d3;
  border-color: #cda13b;
  box-shadow: 0 8px 20px rgba(216, 176, 77, 0.14);
}

.planning-day-card.empty {
  background: #fffaf0;
  border-color: #eadfce;
}

.planning-day-card-kicker {
  font-size: 9px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #c79e35;
}

.planning-day-card-date {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.planning-day-card-number {
  font-family: 'Syne', sans-serif;
  font-size: 24px;
  line-height: 1;
  color: #9f7017;
}

.planning-day-card-month {
  font-size: 11px;
  font-weight: 800;
  color: #84715d;
  text-transform: lowercase;
}

.planning-day-card-title {
  font-size: 13px;
  line-height: 1.2;
  color: #7b6f62;
  text-transform: lowercase;
}

.planning-day-card-subtitle,
.planning-day-card-meta {
  color: #7b6f62;
  font-size: 11px;
  font-weight: 600;
}

.planning-day-card-count {
  margin-top: auto;
  color: #c79e35;
  font-size: 11px;
  font-weight: 800;
}

.planning-detail-card {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.planning-hajj-setup {
  display: flex;
  flex-wrap: wrap;
  align-items: end;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  border-radius: 16px;
  border: 1px solid #ecddbc;
  background: #fff8ea;
}

.planning-hajj-setup-title {
  margin: 0 0 6px;
  font-size: 14px;
  font-weight: 800;
  color: #1d160e;
}

.planning-hajj-setup-text {
  margin: 0;
  color: #7a6f62;
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
  min-height: 170px;
  border: 1px dashed #e7ddd1;
  border-radius: 18px;
  background: linear-gradient(180deg, rgba(255, 248, 235, 0.72), transparent);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 22px;
}

.planning-empty-title {
  margin: 0 0 8px;
  font-size: 16px;
  font-weight: 700;
  color: #1c150e;
}

.planning-empty-copy {
  margin: 0;
  color: #7a6f62;
  font-size: 13px;
  max-width: 460px;
}

.planning-event-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.planning-event-row {
  display: grid;
  grid-template-columns: 84px minmax(0, 1fr) auto;
  gap: 0;
  align-items: stretch;
  border-radius: 14px;
  border: 1px solid #e6d8c7;
  background: #fbf6ee;
  overflow: hidden;
}

.planning-event-row.is-transport {
  box-shadow: inset 3px 0 0 #5ca5ff;
}

.planning-event-row.is-rite {
  box-shadow: inset 3px 0 0 #8d7cff;
}

.planning-event-row.is-visite {
  box-shadow: inset 3px 0 0 #44b97c;
}

.planning-event-row.is-repas {
  box-shadow: inset 3px 0 0 #f1a650;
}

.planning-event-row.is-repos {
  box-shadow: inset 3px 0 0 #9aa7bd;
}

.planning-event-row.is-priere {
  box-shadow: inset 3px 0 0 #77a8ff;
}

.planning-event-time {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 4px;
  padding: 12px 10px;
  background: rgba(255, 255, 255, 0.35);
  border-right: 1px solid #eadfce;
}

.planning-event-time-main {
  font-size: 18px;
  line-height: 1;
  font-family: 'Syne', sans-serif;
  font-weight: 800;
  color: #17120c;
}

.planning-event-time-label {
  font-size: 11px;
  font-weight: 700;
  color: #b28c63;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.planning-event-copy {
  min-width: 0;
  padding: 12px 14px;
}

.planning-event-title {
  margin: 0;
  font-size: 16px;
  font-weight: 800;
  color: #1a140c;
}

.planning-event-location-line {
  margin: 6px 0 0;
  color: #9c8164;
  font-size: 13px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.planning-event-description {
  margin: 8px 0 0;
  color: #75695b;
  font-size: 12px;
}

.planning-event-side {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: flex-end;
  padding: 12px 14px;
}

.planning-type-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 24px;
  padding: 0 10px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 800;
  border: 1px solid transparent;
}

.planning-event-badges {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.planning-type-pill.is-priere {
  background: rgba(74, 158, 255, 0.15);
  color: #2f7ad6;
}

.planning-type-pill.is-transport {
  background: #dcecff;
  color: #1764c3;
}

.planning-type-pill.is-visite {
  background: rgba(80, 205, 137, 0.18);
  color: #248a4b;
}

.planning-type-pill.is-repas {
  background: rgba(255, 174, 102, 0.2);
  color: #b86a1a;
}

.planning-type-pill.is-repos {
  background: rgba(173, 183, 201, 0.2);
  color: #667287;
}

.planning-type-pill.is-rite {
  background: #e9e1ff;
  color: #5d47d6;
}

.planning-type-pill.is-autre {
  background: rgba(125, 125, 125, 0.12);
  color: var(--text2);
}

.planning-etape-pill {
  display: inline-flex;
  align-items: center;
  min-height: 24px;
  padding: 0 10px;
  border-radius: 999px;
  background: #f5e8c8;
  color: #a76c14;
  font-size: 10px;
  font-weight: 800;
  text-transform: uppercase;
}

.planning-event-actions {
  display: flex;
  gap: 8px;
}

.planning-primary-wide {
  width: 100%;
}

.group-type-badge {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  padding: 5px 12px;
  border-radius: 999px;
}

.group-type-badge.hajj {
  background: rgba(201, 168, 76, 0.14);
  color: var(--gold);
  border: 1px solid rgba(201, 168, 76, 0.24);
}

.group-type-badge.umrah {
  background: rgba(74, 158, 255, 0.1);
  color: var(--blue);
  border: 1px solid rgba(74, 158, 255, 0.22);
}

@media (max-width: 960px) {
  .planning-hero-card,
  .planning-days-card,
  .planning-detail-card {
    padding: 18px 16px;
  }

  .planning-hero-heading-row,
  .planning-hero-top {
    align-items: flex-start;
  }

  .planning-hero-actions,
  .planning-detail-actions {
    flex-direction: column;
  }

  .planning-action-button,
  .planning-secondary-button {
    width: 100%;
  }

  .planning-event-row {
    grid-template-columns: 1fr;
    align-items: flex-start;
  }

  .planning-event-side {
    justify-content: flex-start;
  }
}
</style>

