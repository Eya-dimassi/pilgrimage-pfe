<template>
  <div class="view-section">
    <div class="section-topbar">
      <div class="search-wrap">
        <AppIcon class="search-icon" name="search" :size="15" />
        <input v-model="search" class="search-input" placeholder="Rechercher un pelerin..." />
      </div>

      <div class="topbar-actions">
        <div v-if="selectedCount > 0" class="bulk-assign-bar">
          <span class="bulk-assign-label">{{ selectedCount }} selectionne{{ selectedCount > 1 ? 's' : '' }}</span>
          <select v-model="bulkGroupeId" class="bulk-assign-select" :disabled="bulkAssignLoading">
            <option value="">Choisir un groupe</option>
            <option v-for="groupe in assignableGroupes" :key="groupe.id" :value="groupe.id">
              {{ groupe.nom }}
            </option>
          </select>
          <button
            class="btn-secondary bulk-assign-button"
            :disabled="!bulkGroupeId || bulkAssignLoading"
            @click="handleBulkAssign"
          >
            {{ bulkAssignLoading ? 'Affectation...' : 'Affecter au groupe' }}
          </button>
          <button class="bulk-clear-btn" type="button" @click="clearSelection">
            <AppIcon name="x" :size="12" :stroke-width="2" />
          </button>
        </div>

        <button @click="$emit('create')" class="btn-primary">
          <AppIcon name="plus" :size="15" :stroke-width="2" style="margin-right: 6px" />
          Nouveau pelerin
        </button>
      </div>
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

    <div class="card">
      <div v-if="filtered.length === 0" class="empty-state">
        <AppIcon name="users" :size="44" :stroke-width="1.5" style="opacity: 0.25; margin-bottom: 12px" />

        <p style="font-weight: 600; margin-bottom: 4px">
          {{ emptyMessage }}
        </p>
        <p style="font-size: 12.5px; opacity: 0.6; margin-bottom: 14px">{{ emptyHint }}</p>

        <button
          v-if="activeFilter === 'all' && !search"
          @click="$emit('create')"
          class="btn-primary"
          style="font-size: 13px; padding: 7px 16px"
        >
          + Ajouter le premier pelerin
        </button>
        <button
          v-else
          @click="resetFilters"
          class="btn-secondary"
          style="font-size: 13px; padding: 7px 16px"
        >
          Voir tous les pelerins
        </button>
      </div>

      <table v-else class="data-table">
        <thead>
          <tr>
            <th class="checkbox-col">
              <input
                type="checkbox"
                :checked="allVisibleSelected"
                :indeterminate.prop="someVisibleSelected && !allVisibleSelected"
                @change="toggleSelectAll($event.target.checked)"
              />
            </th>
            <th>Pelerin</th>
            <th>Contact</th>
            <th>Passeport</th>
            <th>Groupe</th>
            <th>Statut</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="pelerin in filtered" :key="pelerin.id" :class="{ 'row-loading': loadingRowId === pelerin.id }">
            <td class="checkbox-col">
              <input
                type="checkbox"
                :checked="isSelected(pelerin.id)"
                @change="toggleSelection(pelerin.id, $event.target.checked)"
              />
            </td>
            <td>
              <div class="cell-user">
                <div class="cell-avatar">
                  {{ initials(pelerin.utilisateur?.prenom, pelerin.utilisateur?.nom) }}
                </div>
                <div>
                  <div class="cell-name">
                    {{ pelerin.utilisateur?.prenom }} {{ pelerin.utilisateur?.nom }}
                  </div>
                  <div class="cell-sub">{{ pelerin.nationalite || '-' }}</div>
                </div>
              </div>
            </td>

            <td>
              <div class="cell-name">{{ pelerin.utilisateur?.email }}</div>
              <div class="cell-sub">{{ pelerin.utilisateur?.telephone || '-' }}</div>
            </td>

            <td class="cell-sub">{{ pelerin.numeroPasseport || '-' }}</td>

            <td>
              <div v-if="assigningId === pelerin.id" class="inline-assign">
                <select
                  :value="pelerin.groupeId || ''"
                  @change="handleAssign(pelerin, $event.target.value)"
                  class="inline-select"
                  :disabled="assignLoadingId === pelerin.id"
                  autofocus
                >
                  <option value="">- Sans groupe -</option>
                  <option
                    v-if="lockedGroupeForPelerin(pelerin)"
                    :value="pelerin.groupeId"
                    disabled
                  >
                    {{ lockedGroupeForPelerin(pelerin).nom }} ({{ lockedGroupeForPelerin(pelerin).status === 'TERMINE' ? 'Termine' : 'Annule' }})
                  </option>
                  <option v-for="groupe in assignableGroupes" :key="groupe.id" :value="groupe.id">
                    {{ groupe.nom }}
                  </option>
                </select>

                <button @click="assigningId = null" class="inline-cancel" title="Annuler">
                  <AppIcon name="x" :size="12" :stroke-width="2" />
                </button>
              </div>

              <button
                v-else
                @click="assigningId = pelerin.id"
                class="group-assign-btn"
                :title="pelerin.groupe ? 'Changer de groupe' : 'Affecter a un groupe'"
              >
                <span v-if="assignLoadingId === pelerin.id" class="cell-sub">...</span>
                <template v-else>
                  <span v-if="pelerin.groupe" class="group-tag">{{ pelerin.groupe.nom }}</span>
                  <span v-else class="group-assign-empty">
                    <AppIcon name="plus" :size="11" :stroke-width="2" />
                    Affecter
                  </span>
                </template>
              </button>
            </td>

            <td>
                  <StatusPill :tone="pelerin.utilisateur?.actif ? 'active' : 'pending'">
                    {{ pelerin.utilisateur?.actif ? 'Actif' : 'En attente' }}
                  </StatusPill>
            </td>

            <td>
              <div class="action-btns">
                <button
                  @click="$emit('detail', pelerin)"
                  class="act-btn"
                  title="Voir details"
                  :disabled="loadingRowId === pelerin.id"
                >
                  <AppIcon name="eye" :size="14" />
                </button>

                <button
                  v-if="!pelerin.utilisateur?.actif"
                  @click="$emit('resend', pelerin)"
                  :disabled="resendingId === pelerin.id || loadingRowId === pelerin.id"
                  class="resend-btn"
                  title="Renvoyer l'email d'activation"
                >
                  <AppIcon v-if="resendingId !== pelerin.id" name="mail" :size="14" />
                  <span v-else style="font-size: 10px; font-weight: 700">...</span>
                </button>

                <button
                  @click="$emit('edit', pelerin)"
                  class="act-btn"
                  title="Modifier"
                  :disabled="loadingRowId === pelerin.id"
                >
                  <AppIcon name="edit" :size="14" />
                </button>

                <button
                  @click="$emit('delete', pelerin)"
                  class="act-btn act-btn-danger"
                  title="Supprimer"
                  :disabled="loadingRowId === pelerin.id"
                >
                  <AppIcon name="trash" :size="14" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import StatusPill from '@/features/agence/components/dashboard/StatusPill.vue'
import { useSearchFilter } from '@/features/agence/composables/useSearchFilter'
import { getInitials } from '@/features/agence/utils/initials'

const props = defineProps({
  pelerins: {
    type: Array,
    default: () => [],
  },
  groupes: {
    type: Array,
    default: () => [],
  },
  resendingId: {
    type: String,
    default: null,
  },
  loadingRowId: {
    type: String,
    default: null,
  },
  bulkAssignLoading: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['create', 'detail', 'edit', 'delete', 'resend', 'assign', 'bulk-assign', 'unassign'])

const assigningId = ref(null)
const assignLoadingId = ref(null)
const selectedPelerinIds = ref([])
const bulkGroupeId = ref('')

const filterConfigs = computed(() => [
  { key: 'all', label: 'Tous', predicate: () => true },
  { key: 'actif', label: 'Actifs', predicate: (pelerin) => pelerin.utilisateur?.actif },
  { key: 'pending', label: 'En attente', predicate: (pelerin) => !pelerin.utilisateur?.actif },
  { key: 'nogroupe', label: 'Sans groupe', predicate: (pelerin) => !pelerin.groupeId },
])

const assignableGroupes = computed(() =>
  (props.groupes ?? []).filter((g) => !['TERMINE', 'ANNULE'].includes(g?.status))
)

const { search, activeFilter, filters, filtered, resetFilters } = useSearchFilter({
  items: computed(() => props.pelerins),
  filterConfigs,
  searchableText: (pelerin) =>
    `${pelerin.utilisateur?.prenom ?? ''} ${pelerin.utilisateur?.nom ?? ''} ${pelerin.utilisateur?.email ?? ''}`,
})

const emptyMessage = computed(() => {
  if (search.value) return `Aucun resultat pour "${search.value}"`
  if (activeFilter.value === 'actif') return 'Aucun pelerin actif'
  if (activeFilter.value === 'pending') return 'Aucun pelerin en attente'
  if (activeFilter.value === 'nogroupe') return 'Tous les pelerins sont affectes a un groupe'
  return 'Aucun pelerin pour le moment'
})

const emptyHint = computed(() => {
  if (search.value) return 'Essayez un autre terme de recherche'
  if (activeFilter.value === 'actif') return 'Les pelerins actifs ont defini leur mot de passe'
  if (activeFilter.value === 'pending') return 'Ces pelerins attendent de recevoir et valider leur email'
  if (activeFilter.value === 'nogroupe') return 'Bonne organisation !'
  return 'Ajoutez votre premier pelerin pour commencer'
})

const visiblePelerinIds = computed(() => filtered.value.map((pelerin) => pelerin.id))
const selectedCount = computed(() => selectedPelerinIds.value.length)
const allVisibleSelected = computed(() =>
  visiblePelerinIds.value.length > 0 &&
  visiblePelerinIds.value.every((id) => selectedPelerinIds.value.includes(id))
)
const someVisibleSelected = computed(() =>
  visiblePelerinIds.value.some((id) => selectedPelerinIds.value.includes(id))
)

function initials(prenom, nom) {
  return getInitials(prenom, nom)
}

function isSelected(pelerinId) {
  return selectedPelerinIds.value.includes(pelerinId)
}

function toggleSelection(pelerinId, checked) {
  if (checked) {
    selectedPelerinIds.value = [...new Set([...selectedPelerinIds.value, pelerinId])]
    return
  }

  selectedPelerinIds.value = selectedPelerinIds.value.filter((id) => id !== pelerinId)
}

function toggleSelectAll(checked) {
  if (!checked) {
    selectedPelerinIds.value = selectedPelerinIds.value.filter((id) => !visiblePelerinIds.value.includes(id))
    return
  }

  selectedPelerinIds.value = [...new Set([...selectedPelerinIds.value, ...visiblePelerinIds.value])]
}

function clearSelection() {
  selectedPelerinIds.value = []
  bulkGroupeId.value = ''
}

async function handleAssign(pelerin, newGroupeId) {
  if (newGroupeId === (pelerin.groupeId || '')) {
    assigningId.value = null
    return
  }

  assigningId.value = null
  assignLoadingId.value = pelerin.id

  try {
    if (newGroupeId === '') {
      emit('unassign', { groupeId: pelerin.groupeId, pelerinId: pelerin.id })
    } else {
      emit('assign', { groupeId: newGroupeId, pelerinId: pelerin.id })
    }
  } finally {
    assignLoadingId.value = null
  }
}

function handleBulkAssign() {
  if (!bulkGroupeId.value || selectedPelerinIds.value.length === 0) {
    return
  }

  emit('bulk-assign', {
    groupeId: bulkGroupeId.value,
    pelerinIds: selectedPelerinIds.value,
  })

  clearSelection()
}

function lockedGroupeForPelerin(pelerin) {
  if (!pelerin?.groupeId) return null
  const groupe = (props.groupes ?? []).find((g) => g.id === pelerin.groupeId)
  if (!groupe) return null
  if (groupe.status === 'TERMINE' || groupe.status === 'ANNULE') return groupe
  return null
}
</script>

<style scoped>
.topbar-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.bulk-assign-bar {
  display: flex;
  align-items: center;
  gap: 0.55rem;
  flex-wrap: wrap;
  padding: 0.55rem 0.7rem;
  border: 1px solid rgba(201, 168, 76, 0.22);
  border-radius: 14px;
  background: rgba(201, 168, 76, 0.08);
}

.bulk-assign-label {
  font-size: 0.82rem;
  font-weight: 600;
  color: rgba(246, 238, 223, 0.9);
}

.bulk-assign-select {
  min-width: 180px;
}

.bulk-assign-button {
  white-space: nowrap;
}

.bulk-clear-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.08);
  color: inherit;
  cursor: pointer;
}

.checkbox-col {
  width: 42px;
  text-align: center;
}

.checkbox-col input {
  width: 15px;
  height: 15px;
  accent-color: #c9a84c;
  cursor: pointer;
}

@media (max-width: 980px) {
  .topbar-actions {
    justify-content: stretch;
  }

  .bulk-assign-bar {
    width: 100%;
  }

  .bulk-assign-select {
    flex: 1;
    min-width: 160px;
  }
}
</style>
