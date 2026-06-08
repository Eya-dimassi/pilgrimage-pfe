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
      <p class="planning-empty-copy">Définissez la date de départ et de retour du groupe pour activer le planning du
        voyage.</p>
    </div>

    <div v-else class="planning-page">
      <section class="planning-card planning-hero-card">
        <div class="planning-hero-layout">
          <div class="planning-hero-main">
            <p class="planning-hero-kicker">Planning du voyage</p>
            <div class="planning-select-summary">
              <span class="group-type-badge" :class="selectedGroup.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
                {{ selectedGroup.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra' }}
              </span>
              <span class="group-status-badge" :class="planningGroupStatusClass">{{ groupStatusLabel }}</span>
            </div>
            <h2 class="planning-hero-title">{{ selectedGroup.nom }}</h2>
          </div>

          <div class="planning-hero-side">
            <div class="planning-group-picker planning-group-picker--inline">
              <label for="planning-group">Groupe</label>
              <select id="planning-group" v-model="selectedGroupId">
                <option v-for="groupe in groupes" :key="groupe.id" :value="groupe.id">
                  {{ groupe.nom }} · {{ groupe.typeVoyage }} · {{ groupe.annee }}
                </option>
              </select>
            </div>
            <div class="planning-hero-subtitle planning-inline-meta">
              <span>{{ tripRangeLabel }}</span>
              <span>{{ selectedGroup.typeVoyage }}</span>
              <span>{{ totalPelerinsLabel }}</span>
            </div>
          </div>
        </div>

        <div class="planning-hero-actions">
          <button class="planning-action-button" :disabled="saving || hajjGenerationBlocked"
            :title="hajjGenerationBlocked ? 'Renseignez d’abord la date du 8 Dhul Hijja' : ''"
            @click="generateTemplate">
            <AppIcon name="sparkles" :size="16" />
            <span>Générer modèle {{ selectedGroup.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra' }}</span>
          </button>
          <button class="planning-action-button" :disabled="saving || !selectedDateKey" @click="openDayModal()">
            <AppIcon name="calendar-plus" :size="16" />
            <span>Créer une journée</span>
          </button>
          <button v-if="selectedGroup.status === 'PLANIFIE'"
            class="planning-action-button planning-action-button--danger" :disabled="saving" @click="deletePlanning">
            <AppIcon name="trash" :size="16" />
            <span>Supprimer le planning</span>
          </button>
         <!--<button class="planning-action-button planning-action-button--primary"
            :disabled="saving || !selectedDateKey || !canAddEventOnSelectedDay"
            :title="canAddEventOnSelectedDay ? '' : addEventBlockedReason"
            @click="selectedPlanning ? openEventModal() : createSelectedDayQuick()">
            <AppIcon name="plus" :size="16" />
            <span>Ajouter un événement</span>
          </button>-->
        </div>
      </section>

      <section class="planning-card planning-days-card">
        <div class="planning-section-head">
          <h3>
            <AppIcon name="calendar" :size="16" /> Jours du voyage
          </h3>
          <span>{{ tripRangeLabel }}</span>
        </div>

        <div v-if="!filteredTripDays.length" class="planning-inline-empty">
          Aucune journée disponible pour ce voyage.
        </div>

        <div v-else class="planning-day-rail">
          <button v-for="day in filteredTripDays" :key="day.dateKey" :class="[
            'planning-day-card',
            { active: selectedDateKey === day.dateKey },
            { empty: !(planningByDate[day.dateKey]?.evenements?.length) }
          ]" @click="selectedDateKey = day.dateKey">
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
              <span>
                <AppIcon name="calendar" :size="14" /> {{ selectedDayDateLabel }}
              </span>
              <span>
                <AppIcon name="map-pin" :size="14" /> {{ selectedDayPrimaryLieu }}
              </span>
              <span>
                <AppIcon name="list" :size="14" /> {{ formatEventCount(selectedPlanning?.evenements?.length || 0) }}
              </span>
            </div>
          </div>

          <div v-if="selectedPlanning" class="planning-detail-actions">
            <button class="planning-secondary-button" @click="openDayModal(selectedPlanning)">
              <AppIcon name="edit" :size="15" />
              <span>Modifier la journée</span>
            </button>
            <button class="planning-secondary-button" :disabled="saving || !canClearSelectedPlanning"
              :title="canClearSelectedPlanning ? '' : clearDayBlockedReason" @click="clearDay(selectedPlanning)">
              <AppIcon name="trash" :size="15" />
              <span>Vider la journée</span>
            </button>
          </div>
        </div>

        <div v-if="missingHajjStartDate" class="planning-hajj-setup">
          <div class="planning-hajj-setup-copy">
            <p class="planning-hajj-setup-title">Date du 8 Dhul Hijja requise</p>
            <p class="planning-hajj-setup-text">
              Pour générer le planning Hajj, indiquez ici la date grégorienne correspondant au début des jours fixes du
              Hajj.
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
            <article v-for="event in selectedPlanning.evenements" :key="event.id" class="planning-event-row"
              :class="`is-${event.type.toLowerCase()}`">
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
                  <span :class="['planning-status-pill', getEventStatusClass(event)]">
                    {{ getEventStatusLabel(event) }}
                  </span>
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
            <p class="planning-empty-copy">Ajoutez les lieux, activités et l’heure de rendez-vous prévue pour ce jour.
            </p>
          </div>

          <button class="planning-primary-wide" :disabled="saving || !canAddEventOnSelectedDay"
            :title="canAddEventOnSelectedDay ? '' : addEventBlockedReason" @click="openEventModal()">
            <AppIcon name="plus" :size="16" />
            Ajouter un événement
          </button>
        </template>

        <template v-else>
          <div class="planning-main-empty">
            <AppIcon name="calendar" :size="40" :stroke-width="1.5" style="opacity: 0.22; margin-bottom: 12px" />
            <p class="planning-empty-title">Aucun planning pour cette journée</p>
            <p class="planning-empty-copy">Ajoutez directement un événement et la journée sera créée automatiquement
              pour cette date.</p>
          </div>

          <button class="planning-primary-wide" :disabled="saving || !canAddEventOnSelectedDay"
            :title="canAddEventOnSelectedDay ? '' : addEventBlockedReason" @click="createSelectedDayQuick()">
            <AppIcon name="plus" :size="16" />
            Ajouter un événement
          </button>
        </template>
      </section>
    </div>

    <DashboardModalShell v-if="showDayModal"
      :title="editingDayId ? 'Modifier la journée' : 'Créer une journée de planning'" :error="modalError"
      @close="closeDayModal">
      <div class="form-grid">
        <div class="form-field">
          <label>Date</label>
         <input v-model="dayForm.date" type="date" :min="toDateKey(selectedGroup.dateDepart)"
            :max="toDateKey(selectedGroup.dateRetour)" />
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

    <DashboardModalShell v-if="showEventModal" :title="editingEventId ? 'Modifier l’événement' : 'Ajouter un événement'"
      :error="modalError" @close="closeEventModal">
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
          <input
            v-model="eventForm.lieu"
            list="event-location-options"
            placeholder="Choisir un lieu ou écrire un lieu personnalisé"
          />
          <datalist id="event-location-options">
            <option v-for="location in EVENT_LOCATION_OPTIONS" :key="location" :value="location" />
          </datalist>
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

    <DashboardModalShell
      v-if="confirmDialog.show"
      :title="confirmDialog.title"
      :danger="confirmDialog.danger"
      small
      @close="closeConfirmDialog"
    >
      <p class="modal-desc">{{ confirmDialog.message }}</p>
      <template #actions>
        <button class="btn-secondary" :disabled="confirmLoading || saving" @click="closeConfirmDialog">
          Annuler
        </button>
        <button
          :class="confirmDialog.danger ? 'btn-danger' : 'btn-primary'"
          :disabled="confirmLoading || saving"
          @click="runConfirmDialog"
        >
          {{ confirmLoading || saving ? confirmDialog.loadingLabel : confirmDialog.confirmLabel }}
        </button>
      </template>
    </DashboardModalShell>
  </div>
</template>

<script setup>
import { computed, nextTick, ref, watch } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import DashboardModalShell from '@/features/agence/components/dashboard/DashboardModalShell.vue'
import { useToastStore } from '@/stores/useToastStore'
import {
  createAgencePlanningDay,
  createAgencePlanningEvent,
  deleteAgencePlanningDay,
  deleteAgencePlanningEvent,
  fetchAgencePlanning,
  generateAgencePlanningTemplate,
  updateAgenceGroupe,
  updateAgencePlanningDay,
  updateAgencePlanningEvent,
  deleteAgencePlanning
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
const EVENT_STATUS_LABELS = {
  PLANIFIE: 'Planifié',
  EN_COURS: 'En cours',
  TERMINE: 'Terminé',
  ANNULE: 'Annulé',
}

const EVENT_LOCATION_OPTIONS = [
  'Makkah',
  'Mina',
  'Arafat',
  'Muzdalifah',
  'Médine',
  'Mosquée Al-Haram',
  'Masjid an-Nabawi',
  'Jamarat',
  'Hôtel',
  'Aéroport',
]

const RIYADH_TIME_ZONE = 'Asia/Riyadh'
const RIYADH_DATE_KEY_FORMATTER = new Intl.DateTimeFormat('en-US-u-nu-latn', {
  timeZone: RIYADH_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
})
const RIYADH_SHORT_DATE_FORMATTER = new Intl.DateTimeFormat('fr-FR', {
  timeZone: RIYADH_TIME_ZONE,
  day: '2-digit',
  month: 'short',
})
const RIYADH_TIME_FORMATTER = new Intl.DateTimeFormat('fr-FR', {
  timeZone: RIYADH_TIME_ZONE,
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
})
const RIYADH_WEEKDAY_FORMATTER = new Intl.DateTimeFormat('fr-FR', {
  timeZone: RIYADH_TIME_ZONE,
  weekday: 'long',
})
const RIYADH_MONTH_SHORT_FORMATTER = new Intl.DateTimeFormat('fr-FR', {
  timeZone: RIYADH_TIME_ZONE,
  month: 'short',
})

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

  const parts = RIYADH_DATE_KEY_FORMATTER.formatToParts(date)
  const year = parts.find((part) => part.type === 'year')?.value ?? ''
  const month = parts.find((part) => part.type === 'month')?.value ?? ''
  const day = parts.find((part) => part.type === 'day')?.value ?? ''
  if (!year || !month || !day) return ''

  return `${year}-${month}-${day}`
}

function parsePlanningDate(value) {
  if (value instanceof Date) return new Date(value.getTime())
  const raw = String(value ?? '').trim()
  if (!raw) return new Date('')
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
    return new Date(`${raw}T00:00:00+03:00`)
  }
  return new Date(raw)
}

function formatShortDate(value) {
  const date = parsePlanningDate(value)
  if (Number.isNaN(date.getTime())) return ''
  return RIYADH_SHORT_DATE_FORMATTER.format(date)
}

function formatEventType(value) {
  return EVENT_TYPE_LABELS[value] ?? value
}

function resolveEventStatus(event) {
  const rawStatus = String(event?.status ?? event?.statut ?? event?.validation?.status ?? '').toUpperCase()

  if (rawStatus === 'ANNULE') return rawStatus
  if (rawStatus === 'TERMINE') return rawStatus
  if (event?.estValide || event?.valideeAt || event?.valideParGuideId) return 'TERMINE'
  if (rawStatus === 'EN_COURS') return 'EN_COURS'

  const eventDateKey = toDateKey(event?.heureDebutPrevue ?? selectedPlanning.value?.date)
  if (eventDateKey && todayDateKey.value && eventDateKey === todayDateKey.value) {
    return 'EN_COURS'
  }

  return 'PLANIFIE'
}

function getEventStatusLabel(event) {
  const status = resolveEventStatus(event)
  return EVENT_STATUS_LABELS[status] ?? EVENT_STATUS_LABELS.PLANIFIE
}

function getEventStatusClass(event) {
  const status = resolveEventStatus(event)
  if (status === 'EN_COURS') return 'is-running'
  if (status === 'TERMINE') return 'is-done'
  if (status === 'ANNULE') return 'is-canceled'
  return 'is-planned'
}

function formatEventTime(value) {
  if (!value) return ''
  const date = parsePlanningDate(value)
  if (Number.isNaN(date.getTime())) return ''
  return RIYADH_TIME_FORMATTER.format(date)
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

function formatEventTimeInput(value) {
  if (!value) return ''
  const date = parsePlanningDate(value)
  if (Number.isNaN(date.getTime())) return ''
  return RIYADH_TIME_FORMATTER.format(date)
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
const toastStore = useToastStore()
const selectedGroupId = ref('')
const hajjStartDateInput = ref('')
const planningData = ref({ groupe: null, plannings: [], tripDays: [] })
const selectedDateKey = ref('')
const showDayModal = ref(false)
const showEventModal = ref(false)
const confirmLoading = ref(false)
const confirmDialog = ref({
  show: false,
  title: '',
  message: '',
  confirmLabel: 'Confirmer',
  loadingLabel: 'Traitement...',
  danger: false,
  onConfirm: null,
})
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
const todayDateKey = computed(() => toDateKey(new Date()))
const canClearSelectedPlanning = computed(() => {
  if (!selectedPlanning.value) return false
  const planningDateKey = toDateKey(selectedPlanning.value.date)
  if (!planningDateKey || !todayDateKey.value) return false
  return planningDateKey > todayDateKey.value
})
const canAddEventOnSelectedDay = computed(() => {
  if (!selectedDateKey.value || !todayDateKey.value) return false
  return selectedDateKey.value >= todayDateKey.value
})
const addEventBlockedReason = computed(() => "Impossible d'ajouter un evenement dans une journee deja passee.")
const clearDayBlockedReason = computed(() => {
  if (!selectedPlanning.value) return ''
  return "Vous ne pouvez vider qu'une journee future (date > aujourd'hui)."
})
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
const planningGroupStatusClass = computed(() => {
  switch (selectedGroup.value?.status) {
    case 'EN_COURS':
      return 'is-running'
    case 'TERMINE':
      return 'is-done'
    case 'ANNULE':
      return 'is-canceled'
    case 'PLANIFIE':
    default:
      return 'is-planned'
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
const totalPelerins = computed(() => selectedGroup.value?._count?.pelerins ?? selectedGroup.value?.pelerins?.length ?? 0)
const totalPelerinsLabel = computed(() => `${totalPelerins.value} pèlerin${totalPelerins.value > 1 ? 's' : ''}`)
const selectedDayPrimaryLieu = computed(() => {
  const firstLieu = selectedPlanning.value?.evenements?.[0]?.lieu
  return splitLieux(firstLieu)[0] || 'Lieu à préciser'
})

function showToast(message, type = 'success') {
  if (type === 'error') {
    toastStore.error(message)
    return
  }

  toastStore.success(message)
}

function getEventFallbackDescription(event) {
  const lieux = splitLieux(event?.lieu)
  return lieux.length ? lieux.join(' → ') : 'Détails à préciser'
}

function getWeekdayLabel(day) {
  const date = parsePlanningDate(day?.date)
  if (Number.isNaN(date.getTime())) return day?.label ?? ''
  return RIYADH_WEEKDAY_FORMATTER.format(date)
}

function getDayMonthShort(day) {
  const date = parsePlanningDate(day?.date)
  if (Number.isNaN(date.getTime())) return day?.monthShort ?? ''
  return RIYADH_MONTH_SHORT_FORMATTER.format(date).replace('.', '')
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
    heure: event?.heureDebutPrevue ? formatEventTimeInput(event.heureDebutPrevue) : '',
  }
  showEventModal.value = true
}

function closeEventModal() {
  showEventModal.value = false
  editingEventId.value = ''
  modalError.value = ''
}

function openConfirmDialog({
  title,
  message,
  confirmLabel = 'Confirmer',
  loadingLabel = 'Traitement...',
  danger = false,
  onConfirm,
}) {
  confirmDialog.value = {
    show: true,
    title,
    message,
    confirmLabel,
    loadingLabel,
    danger,
    onConfirm,
  }
}

function closeConfirmDialog() {
  if (confirmLoading.value || saving.value) return

  confirmDialog.value = {
    show: false,
    title: '',
    message: '',
    confirmLabel: 'Confirmer',
    loadingLabel: 'Traitement...',
    danger: false,
    onConfirm: null,
  }
}

async function runConfirmDialog() {
  if (!confirmDialog.value.onConfirm) return

  confirmLoading.value = true
  try {
    await confirmDialog.value.onConfirm()
    confirmDialog.value = {
      ...confirmDialog.value,
      show: false,
      onConfirm: null,
    }
  } finally {
    confirmLoading.value = false
  }
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
  const minDate = toDateKey(selectedGroup.value?.dateDepart)
  const maxDate = toDateKey(selectedGroup.value?.dateRetour)

  if (dayForm.value.date < minDate || dayForm.value.date > maxDate) {
    modalError.value = 'La journée doit être comprise entre la date de départ et la date de retour du groupe.'
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

  if (!canAddEventOnSelectedDay.value) {
    showToast(addEventBlockedReason.value, 'error')
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

  if (!canAddEventOnSelectedDay.value) {
    modalError.value = addEventBlockedReason.value
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

async function clearDay(planning) {
  if (!canClearSelectedPlanning.value) {
    showToast(clearDayBlockedReason.value, 'error')
    return
  }

  openConfirmDialog({
    title: 'Vider la journée',
    message: 'Tous les événements de cette journée seront supprimés. Cette action est irréversible.',
    confirmLabel: 'Vider la journée',
    loadingLabel: 'Suppression...',
    danger: true,
    onConfirm: async () => {
      try {
        await deleteAgencePlanningDay(planning.id)
        showToast('Journée vidée')
        await loadPlanning()
      } catch (err) {
        showToast(err.response?.data?.message || err.message, 'error')
      }
    },
  })
}

async function deleteEvent(event) {
  openConfirmDialog({
    title: "Supprimer l'événement",
    message: `L'événement "${event.titre}" sera supprimé du planning.`,
    confirmLabel: 'Supprimer',
    loadingLabel: 'Suppression...',
    danger: true,
    onConfirm: async () => {
      try {
        await deleteAgencePlanningEvent(event.id)
        showToast('Événement supprimé')
        await loadPlanning()
      } catch (err) {
        showToast(err.response?.data?.message || err.message, 'error')
      }
    },
  })
}

async function generateTemplate() {
  if (!selectedGroupId.value || !selectedGroup.value) return

  const typeVoyage = selectedGroup.value.typeVoyage === 'HAJJ' ? 'Hajj' : 'Omra'

  openConfirmDialog({
    title: `Générer modèle ${typeVoyage}`,
    message: 'Les journées déjà créées seront conservées. Les journées manquantes seront ajoutées automatiquement.',
    confirmLabel: 'Générer',
    loadingLabel: 'Génération...',
    onConfirm: async () => {
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
    },
  })
}
async function deletePlanning() {
  openConfirmDialog({
    title: 'Supprimer le planning',
    message: 'Tout le planning de ce groupe sera supprimé, journées et événements inclus.',
    confirmLabel: 'Supprimer',
    loadingLabel: 'Suppression...',
    danger: true,
    onConfirm: async () => {
      saving.value = true
      try {
        await deleteAgencePlanning(selectedGroupId.value)
        showToast('Planning supprimé')
        await loadPlanning()
      } catch (err) {
        showToast(err.response?.data?.message || err.message, 'error')
      } finally {
        saving.value = false
      }
    },
  })
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
  gap: 18px;
}

.planning-hero-layout {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
  flex-wrap: wrap;
}

.planning-hero-main {
  display: flex;
  flex: 1 1 420px;
  flex-direction: column;
  gap: 14px;
}

.planning-hero-side {
  display: flex;
  flex: 0 1 360px;
  flex-direction: column;
  align-items: stretch;
  gap: 34px;
  padding-top: 12px;
}

.planning-group-picker--inline {
  width: 100%;
  min-width: 280px;
  max-width: 360px;
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

.planning-hero-subtitle {
  justify-content: flex-end;
  text-align: right;
  flex-wrap: nowrap;
  gap: 14px;
  white-space: nowrap;
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

.planning-status-pill {
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

.planning-status-pill.is-planned {
  background: rgba(140, 122, 100, 0.14);
  color: #6c5d4d;
}

.planning-status-pill.is-running {
  background: rgba(54, 137, 255, 0.16);
  color: #1c63ba;
}

.planning-status-pill.is-done {
  background: rgba(57, 177, 102, 0.18);
  color: #237b43;
}

.planning-status-pill.is-canceled {
  background: rgba(220, 82, 73, 0.16);
  color: #a53730;
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

.group-status-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: var(--bg3);
  color: var(--text2);
  letter-spacing: 0.2px;
  white-space: nowrap;
}

.group-status-badge.is-planned {
  border-color: rgba(124, 195, 255, 0.25);
  color: rgba(124, 195, 255, 0.95);
  background: rgba(124, 195, 255, 0.08);
}

.group-status-badge.is-running {
  border-color: rgba(74, 222, 128, 0.22);
  color: var(--green);
  background: rgba(74, 222, 128, 0.08);
}

.group-status-badge.is-done {
  border-color: rgba(201, 168, 76, 0.35);
  color: var(--gold);
  background: rgba(201, 168, 76, 0.1);
}

.group-status-badge.is-canceled {
  border-color: rgba(255, 107, 107, 0.25);
  color: var(--red);
  background: rgba(255, 107, 107, 0.08);
}

.planning-action-button--danger {
  background: #fff0f0;
  border-color: #f5c0c0;
  color: #c0392b;
}

.planning-action-button--danger:hover:not(:disabled) {
  background: #ffe4e4;
  border-color: #e07070;
}
@media (max-width: 960px) {

  .planning-hero-card,
  .planning-days-card,
  .planning-detail-card {
    padding: 18px 16px;
  }

  .planning-hero-layout {
    gap: 18px;
  }

  .planning-hero-side {
    flex-basis: 100%;
    align-items: flex-start;
    gap: 12px;
    padding-top: 0;
  }

  .planning-group-picker--inline {
    margin-left: 0;
    max-width: none;
  }

  .planning-select-summary {
    margin-top: 18px;
  }

  .planning-hero-subtitle {
    justify-content: flex-start;
    text-align: left;
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
