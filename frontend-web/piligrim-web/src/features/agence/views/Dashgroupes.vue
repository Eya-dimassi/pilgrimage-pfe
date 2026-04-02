<template>
  <div class="view-section">
    <div class="section-topbar section-topbar--groups">
      <div class="search-wrap">
        <AppIcon class="search-icon" name="search" :size="15" />
        <input v-model="search" class="search-input" placeholder="Rechercher un groupe..." />
      </div>

      <div ref="filterWrap" class="filter-dropdown-wrap">
        <button type="button" @click="showFilters = !showFilters" class="btn-filter">
          <span class="btn-filter-icon" aria-hidden="true">
            <AppIcon name="filter-sort" :size="14" />
          </span>
          Filtrer
          <span v-if="activeFilterCount > 0" class="filter-pill">{{ activeFilterCount }}</span>
        </button>

        <div v-if="showFilters" class="filter-dropdown">
          <div class="filter-group">
            <label>Statut</label>
            <select v-model="selectedStatus">
              <option value="">Tous</option>
              <option value="PLANIFIE">Planifie</option>
              <option value="EN_COURS">En cours</option>
              <option value="TERMINE">Termine</option>
              <option value="ANNULE">Annule</option>
            </select>
          </div>

          <div class="filter-group">
            <label>Annee</label>
            <select v-model="selectedYear">
              <option value="">Toutes</option>
              <option v-for="year in availableYears" :key="year" :value="String(year)">
                {{ year }}
              </option>
            </select>
          </div>

          <button type="button" @click="handleResetFilters" class="btn-reset">Reinitialiser</button>
        </div>
      </div>

      <button @click="$emit('create')" class="btn-primary">
        <AppIcon name="plus" :size="15" :stroke-width="2" style="margin-right: 6px" />
        Nouveau groupe
      </button>
    </div>

    <div class="filter-tabs">
      <button
        v-for="filter in filters"
        :key="filter.key"
        :class="['filter-tab', { active: activeFilter === filter.key }]"
        @click="activeFilter = filter.key"
      >
        {{ filter.label }}
        <span class="filter-count">{{ filter.count }}</span>
      </button>
    </div>

    <div
      v-if="filtered.length === 0"
      class="empty-state"
      style="background: var(--bg2); border: 1px solid var(--border); border-radius: 16px"
    >
      <AppIcon name="building" :size="44" :stroke-width="1.5" style="opacity: 0.25; margin-bottom: 12px" />

      <p style="font-weight: 600; margin-bottom: 4px">{{ emptyMessage }}</p>
      <p style="font-size: 12.5px; opacity: 0.6; margin-bottom: 14px">{{ emptyHint }}</p>

      <button
        v-if="activeFilter === 'all' && !search"
        @click="$emit('create')"
        class="btn-primary"
        style="font-size: 13px; padding: 7px 16px"
      >
        + Creer le premier groupe
      </button>
      <button
        v-else
        @click="resetFilters"
        class="btn-secondary"
        style="font-size: 13px; padding: 7px 16px"
      >
        Voir tous les groupes
      </button>
    </div>

    <div v-else class="groups-grid">
      <div v-for="groupe in filtered" :key="groupe.id" :class="['group-card', { 'group-card--expanded': expandedId === groupe.id }]">
        <div class="group-card-header">
          <div style="display: flex; align-items: center; gap: 8px">
            <div class="group-type-badge" :class="groupe.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
              {{ groupe.typeVoyage }}
            </div>
            <div class="group-status-badge" :class="statusClass(groupe.status)">
              {{ statusLabel(groupe.status) }}
            </div>
          </div>

          <div class="group-actions">
            <button @click="toggleExpand(groupe.id)" class="act-btn" :title="expandedId === groupe.id ? 'Reduire' : 'Voir details'">
              <AppIcon :name="expandedId === groupe.id ? 'chevron-up' : 'chevron-down'" :size="14" />
            </button>

            <button @click="exportGroupePdf(groupe)" class="act-btn" title="Exporter en PDF">
              <AppIcon name="download" :size="14" />
            </button>

            <button @click="$emit('edit', groupe)" class="act-btn" title="Modifier">
              <AppIcon name="edit" :size="14" />
            </button>

            <button
              @click="$emit('delete', groupe)"
              class="act-btn act-btn-danger"
              :title="(groupe._count?.pelerins ?? groupe.pelerins?.length ?? 0) > 0 ? 'Annuler le groupe' : 'Supprimer'"
            >
              <AppIcon :name="(groupe._count?.pelerins ?? groupe.pelerins?.length ?? 0) > 0 ? 'x' : 'trash'" :size="14" />
            </button>
          </div>
        </div>

        <div class="group-name">{{ groupe.nom }}</div>
        <div class="group-meta">
          {{ groupe.annee }} ·
          <template v-if="dateRangeText(groupe)">
            {{ dateRangeText(groupe) }} ·
          </template>
          {{ groupe.description || 'Pas de description' }}
        </div>

        <div class="group-stats">
          <div class="group-stat">
            <span class="gs-val">{{ groupe._count?.pelerins ?? groupe.pelerins?.length ?? 0 }}</span>
            <span class="gs-lbl">Pelerins</span>
          </div>
          <div class="group-stat">
            <span class="gs-val" :style="(groupe.guides?.length ?? 0) === 0 ? 'color: var(--orange)' : ''">
              {{ (groupe.guides?.length ?? 0) > 0 ? groupe.guides.length : '!' }}
            </span>
            <span class="gs-lbl" :style="(groupe.guides?.length ?? 0) === 0 ? 'color: var(--orange)' : ''">Guides</span>
          </div>
        </div>

        <div v-if="(groupe.guides?.length ?? 0) > 0" class="group-guide">
          <AppIcon name="user" :size="13" style="flex-shrink: 0" />
          {{ groupe.guides.map((g) => `${g.utilisateur?.prenom ?? ''} ${g.utilisateur?.nom ?? ''}`.trim()).join(', ') }}
        </div>

        <div v-else class="group-guide" style="color: var(--orange)">
          <AppIcon name="alert" :size="13" style="flex-shrink: 0" />
          Aucun guide assigne
        </div>

        <transition name="expand">
          <div v-if="expandedId === groupe.id" class="group-details">
            <div class="group-details-section">
              <div class="group-details-label">
                <AppIcon name="user" :size="13" />
                Guides assignes
              </div>

              <div v-if="(groupe.guides?.length ?? 0) > 0">
                <div v-for="guide in groupe.guides" :key="guide.id" class="guide-detail-row">
                  <div class="cell-avatar green-av" style="width: 30px; height: 30px; font-size: 11px">
                    {{ initials(guide.utilisateur?.prenom, guide.utilisateur?.nom) }}
                  </div>
                  <div>
                    <div class="cell-name" style="font-size: 13px">
                      {{ guide.utilisateur?.prenom }} {{ guide.utilisateur?.nom }}
                    </div>
                    <div class="cell-sub">{{ guide.utilisateur?.email }}</div>
                  </div>

                  <button
                    @click="$emit('remove-guide', { groupeId: groupe.id, guideId: guide.id })"
                    class="act-btn act-btn-danger"
                    title="Retirer du groupe"
                    style="width: 26px; height: 26px; flex-shrink: 0"
                  >
                    <AppIcon name="x" :size="12" />
                  </button>
                </div>
              </div>

              <div v-else class="group-details-empty" style="color: var(--orange)">
                Aucun guide - modifiez le groupe pour en assigner un
              </div>
            </div>

            <div class="group-details-section">
              <div class="group-details-label">
                <AppIcon name="users" :size="13" />
                Pelerins ({{ groupe.pelerins?.length ?? 0 }})
              </div>

              <div v-if="!groupe.pelerins || groupe.pelerins.length === 0" class="group-details-empty">
                Aucun pelerin - utilisez "Affecter pelerin" depuis la vue Pelerins
              </div>

              <div v-for="pelerin in groupe.pelerins" :key="pelerin.id" class="pelerin-detail-row">
                <div class="cell-avatar" style="width: 30px; height: 30px; font-size: 11px">
                  {{ initials(pelerin.utilisateur?.prenom, pelerin.utilisateur?.nom) }}
                </div>

                <div class="pelerin-detail-info">
                  <div class="cell-name" style="font-size: 13px">
                    {{ pelerin.utilisateur?.prenom }} {{ pelerin.utilisateur?.nom }}
                  </div>
                  <div class="cell-sub">{{ pelerin.utilisateur?.email }}</div>
                </div>

                <button
                  @click="$emit('remove-pelerin', { groupeId: groupe.id, pelerinId: pelerin.id })"
                  class="act-btn act-btn-danger"
                  title="Retirer du groupe"
                  style="width: 26px; height: 26px; flex-shrink: 0"
                >
                  <AppIcon name="x" :size="12" />
                </button>
              </div>
            </div>
          </div>
        </transition>

        <button
          @click="$emit('assign', groupe)"
          class="btn-assign"
          :disabled="isLockedStatus(groupe.status)"
          :title="isLockedStatus(groupe.status) ? 'Affectation indisponible' : 'Affecter pelerins'"
        >
          <AppIcon name="plus" :size="13" :stroke-width="2" style="margin-right: 5px" />
          Affecter pelerins
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import { getInitials } from '@/features/agence/utils/initials'
import { exportGroupePdf as doExportGroupePdf } from '@/features/agence/utils/exportGroupePdf'

const props = defineProps({
  groupes: {
    type: Array,
    default: () => [],
  },
})

defineEmits(['create', 'edit', 'delete', 'assign', 'remove-pelerin', 'remove-guide'])

const search = ref('')
const activeFilter = ref('all')
const expandedId = ref(null)
const selectedStatus = ref('')
const selectedYear = ref('')
const showFilters = ref(false)
const filterWrap = ref(null)

const activeFilterCount = computed(() => (selectedStatus.value ? 1 : 0) + (selectedYear.value ? 1 : 0))

const availableYears = computed(() => {
  const years = new Set(
    (props.groupes ?? [])
      .map((g) => g?.annee)
      .filter((y) => y != null && String(y).trim() !== '')
      .map((y) => Number(y))
      .filter((y) => !Number.isNaN(y))
  )

  return Array.from(years).sort((a, b) => b - a)
})

const filters = computed(() => [
  { key: 'all', label: 'Tous', count: props.groupes.length },
  { key: 'hajj', label: 'Hajj', count: props.groupes.filter((g) => g.typeVoyage === 'HAJJ').length },
  { key: 'umrah', label: 'Umrah', count: props.groupes.filter((g) => g.typeVoyage === 'UMRAH').length },
  { key: 'noguide', label: 'Sans guide', count: props.groupes.filter((g) => !g.guide).length },
  {
    key: 'nopelerin',
    label: 'Vides',
    count: props.groupes.filter((g) => (g._count?.pelerins ?? 0) === 0).length,
  },
])

const filtered = computed(() => {
  let list = props.groupes

  if (selectedStatus.value) {
    list = list.filter((g) => String(g?.status ?? '') === selectedStatus.value)
  }

  if (selectedYear.value) {
    list = list.filter((g) => String(g?.annee ?? '') === selectedYear.value)
  }

  if (activeFilter.value === 'hajj') list = list.filter((g) => g.typeVoyage === 'HAJJ')
  if (activeFilter.value === 'umrah') list = list.filter((g) => g.typeVoyage === 'UMRAH')
  if (activeFilter.value === 'noguide') list = list.filter((g) => !g.guide)
  if (activeFilter.value === 'nopelerin') list = list.filter((g) => (g._count?.pelerins ?? 0) === 0)

  const query = search.value.toLowerCase()
  if (query) {
    list = list.filter((g) => g.nom.toLowerCase().includes(query))
  }

  return list
})

const emptyMessage = computed(() => {
  if (search.value) return `Aucun resultat pour "${search.value}"`
  if (selectedStatus.value) return `Aucun groupe pour le statut "${statusLabel(selectedStatus.value)}"`
  if (selectedYear.value) return `Aucun groupe pour l'annee ${selectedYear.value}`
  if (activeFilter.value === 'hajj') return 'Aucun groupe Hajj'
  if (activeFilter.value === 'umrah') return 'Aucun groupe Umrah'
  if (activeFilter.value === 'noguide') return 'Tous les groupes ont un guide !'
  if (activeFilter.value === 'nopelerin') return 'Tous les groupes ont des pelerins !'
  return 'Aucun groupe pour le moment'
})

const emptyHint = computed(() => {
  if (search.value) return 'Essayez un autre terme de recherche'
  if (selectedStatus.value) return 'Essayez un autre statut ou reinitialisez les filtres'
  if (selectedYear.value) return 'Essayez une autre annee ou reinitialisez les filtres'
  if (activeFilter.value === 'noguide') return 'Bonne organisation !'
  if (activeFilter.value === 'nopelerin') return 'Continuez comme ca !'
  return 'Creez votre premier groupe pour organiser vos pelerins'
})

function resetFilters() {
  activeFilter.value = 'all'
  search.value = ''
  selectedStatus.value = ''
  selectedYear.value = ''
}

function handleResetFilters() {
  resetFilters()
  showFilters.value = false
}

function handleDocumentClick(event) {
  if (!showFilters.value) return
  if (!filterWrap.value) return
  if (filterWrap.value.contains(event.target)) return
  showFilters.value = false
}

function handleKeydown(event) {
  if (event.key === 'Escape') showFilters.value = false
}

onMounted(() => {
  document.addEventListener('click', handleDocumentClick)
  document.addEventListener('keydown', handleKeydown)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleDocumentClick)
  document.removeEventListener('keydown', handleKeydown)
})

function toggleExpand(id) {
  expandedId.value = expandedId.value === id ? null : id
}

function initials(prenom, nom) {
  return getInitials(prenom, nom)
}

function formatDate(value) {
  if (!value) return ''
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short', day: '2-digit' })
}

function dateRangeText(groupe) {
  const depart = formatDate(groupe.dateDepart)
  const retour = formatDate(groupe.dateRetour)

  if (depart && retour) return `${depart} \u2192 ${retour}`
  if (depart) return `Depart: ${depart}`
  if (retour) return `Retour: ${retour}`
  return ''
}

function statusLabel(status) {
  if (status === 'EN_COURS') return 'En cours'
  if (status === 'TERMINE') return 'Termine'
  if (status === 'ANNULE') return 'Annule'
  return 'Planifie'
}

function statusClass(status) {
  if (status === 'EN_COURS') return 'is-running'
  if (status === 'TERMINE') return 'is-done'
  if (status === 'ANNULE') return 'is-canceled'
  return 'is-planned'
}

function isLockedStatus(status) {
  return status === 'TERMINE' || status === 'ANNULE'
}

function exportGroupePdf(groupe) {
  try {
    doExportGroupePdf(groupe)
  } catch (error) {
    alert(error?.message || "Impossible d'exporter en PDF. Autorisez les popups puis reessayez.")
  }
}
</script>

<style scoped>
.section-topbar--groups {
  flex-wrap: wrap;
}

.section-topbar--groups .search-wrap {
  flex: 1 1 260px;
  max-width: 420px;
}

.filter-dropdown-wrap {
  position: relative;
  flex: 0 0 auto;
}

.btn-filter {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 7px 12px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--bg2);
  color: var(--text2);
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  transition: border-color 0.15s, color 0.15s, background 0.15s;
  white-space: nowrap;
}

.btn-filter-icon {
  width: 22px;
  height: 22px;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--bg3);
  border: 1px solid var(--border);
  color: var(--text2);
  box-shadow: 0 8px 18px rgba(0, 0, 0, 0.18);
  flex: 0 0 auto;
}

.btn-filter:hover {
  border-color: rgba(201, 168, 76, 0.45);
  color: var(--gold);
  background: rgba(201, 168, 76, 0.06);
}

.btn-filter:hover .btn-filter-icon {
  border-color: rgba(201, 168, 76, 0.45);
  color: var(--gold);
  background: rgba(201, 168, 76, 0.08);
}

.filter-pill {
  min-width: 18px;
  height: 18px;
  padding: 0 6px;
  border-radius: 999px;
  background: rgba(201, 168, 76, 0.16);
  border: 1px solid rgba(201, 168, 76, 0.35);
  color: var(--gold);
  font-size: 11px;
  font-weight: 800;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-left: 2px;
}

.filter-dropdown {
  position: absolute;
  top: calc(100% + 10px);
  right: 0;
  width: 260px;
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 12px;
  box-shadow: var(--shadow);
  z-index: 50;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 10px;
}

.filter-group label {
  font-size: 11px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.7px;
  color: var(--text2);
}

.filter-group select {
  width: 100%;
  padding: 9px 10px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--bg3);
  color: var(--text);
  font-size: 13px;
  outline: none;
  font-family: 'DM Sans', sans-serif;
}

.filter-group select:focus {
  border-color: var(--gold);
}

.btn-reset {
  width: 100%;
  padding: 9px 10px;
  border-radius: 10px;
  border: 1px solid rgba(201, 168, 76, 0.35);
  background: rgba(201, 168, 76, 0.08);
  color: var(--gold);
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s, border-color 0.15s;
}

.btn-reset:hover {
  background: rgba(201, 168, 76, 0.12);
  border-color: rgba(201, 168, 76, 0.5);
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
  border-color: rgba(255, 255, 255, 0.14);
  color: rgba(255, 255, 255, 0.75);
  background: rgba(255, 255, 255, 0.06);
}

.group-status-badge.is-canceled {
  border-color: rgba(255, 107, 107, 0.25);
  color: var(--red);
  background: rgba(255, 107, 107, 0.08);
}
</style>
