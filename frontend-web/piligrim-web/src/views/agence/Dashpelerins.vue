<template>
  <div class="view-section">

    <!-- ── Topbar ── -->
    <div class="section-topbar">
      <div class="search-wrap">
        <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75"
          stroke-linecap="round" stroke-linejoin="round" width="15" height="15">
          <circle cx="11" cy="11" r="8" />
          <line x1="21" y1="21" x2="16.65" y2="16.65" />
        </svg>
        <input v-model="search" class="search-input" placeholder="Rechercher un pèlerin..." />
      </div>
      <button @click="$emit('create')" class="btn-primary">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
          stroke-linejoin="round" width="15" height="15" style="margin-right:6px">
          <line x1="12" y1="5" x2="12" y2="19" />
          <line x1="5" y1="12" x2="19" y2="12" />
        </svg>
        Nouveau pèlerin
      </button>
    </div>

    <!-- ── Filter tabs ── -->
    <div class="filter-tabs">
      <button v-for="f in filters" :key="f.key" :class="['filter-tab', { active: activeFilter === f.key }]"
        @click="activeFilter = f.key">
        {{ f.label }}
        <span class="filter-count">{{ f.count }}</span>
      </button>
    </div>

    <!-- ── Table ── -->
    <div class="card">

      <!-- Empty state -->
      <div v-if="filtered.length === 0" class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"
          stroke-linejoin="round" width="44" height="44" style="opacity:0.25;margin-bottom:12px">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
          <circle cx="9" cy="7" r="4" />
          <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
          <path d="M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
        <p style="font-weight:600;margin-bottom:4px">
          {{ emptyMessage }}
        </p>
        <p style="font-size:12.5px;opacity:0.6;margin-bottom:14px">{{ emptyHint }}</p>
        <button v-if="activeFilter === 'all' && !search" @click="$emit('create')" class="btn-primary"
          style="font-size:13px;padding:7px 16px">
          + Ajouter le premier pèlerin
        </button>
        <button v-else @click="activeFilter = 'all'; search = ''" class="btn-secondary"
          style="font-size:13px;padding:7px 16px">
          Voir tous les pèlerins
        </button>
      </div>

      <table v-else class="data-table">
        <thead>
          <tr>
            <th>Pèlerin</th>
            <th>Contact</th>
            <th>Passeport</th>
            <th>Groupe</th>
            <th>Statut</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in filtered" :key="p.id" :class="{ 'row-loading': loadingRowId === p.id }">
            <td>
              <div class="cell-user">
                <div class="cell-avatar">{{ initials(p.utilisateur?.prenom, p.utilisateur?.nom) }}</div>
                <div>
                  <div class="cell-name">{{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}</div>
                  <div class="cell-sub">{{ p.nationalite || '—' }}</div>
                </div>
              </div>
            </td>
            <td>
              <div class="cell-name">{{ p.utilisateur?.email }}</div>
              <div class="cell-sub">{{ p.utilisateur?.telephone || '—' }}</div>
            </td>
            <td class="cell-sub">{{ p.numeroPasseport || '—' }}</td>

            <!-- ── Groupe cell — inline assign ── -->
            <td>
              <div v-if="assigningId === p.id" class="inline-assign">
                <select :value="p.groupeId || ''" @change="handleAssign(p, $event.target.value)" class="inline-select"
                  :disabled="assignLoadingId === p.id" autofocus>
                  <option value="">— Sans groupe —</option>
                  <option v-for="g in groupes" :key="g.id" :value="g.id">{{ g.nom }}</option>
                </select>
                <button @click="assigningId = null" class="inline-cancel" title="Annuler">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                    stroke-linejoin="round" width="12" height="12">
                    <line x1="18" y1="6" x2="6" y2="18" />
                    <line x1="6" y1="6" x2="18" y2="18" />
                  </svg>
                </button>
              </div>
              <button v-else @click="assigningId = p.id" class="group-assign-btn"
                :title="p.groupe ? 'Changer de groupe' : 'Affecter à un groupe'">
                <span v-if="assignLoadingId === p.id" class="cell-sub">...</span>
                <template v-else>
                  <span v-if="p.groupe" class="group-tag">{{ p.groupe.nom }}</span>
                  <span v-else class="group-assign-empty">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                      stroke-linejoin="round" width="11" height="11">
                      <line x1="12" y1="5" x2="12" y2="19" />
                      <line x1="5" y1="12" x2="19" y2="12" />
                    </svg>
                    Affecter
                  </span>
                </template>
              </button>
            </td>

            <td>
              <span :class="['status-pill', p.utilisateur?.actif ? 'active' : 'pending']">
                {{ p.utilisateur?.actif ? 'Actif' : 'En attente' }}
              </span>
            </td>

            <td>
              <div class="action-btns">
                <button @click="$emit('edit', p)" class="act-btn" title="Modifier" :disabled="loadingRowId === p.id">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"
                    stroke-linejoin="round" width="14" height="14">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                  </svg>
                </button>
                <button @click="$emit('delete', p)" class="act-btn act-btn-danger" title="Supprimer"
                  :disabled="loadingRowId === p.id">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"
                    stroke-linejoin="round" width="14" height="14">
                    <polyline points="3 6 5 6 21 6" />
                    <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                    <path d="M10 11v6" />
                    <path d="M14 11v6" />
                    <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
                  </svg>
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
import { ref, computed } from 'vue'

const props = defineProps({
  pelerins: Array,
  groupes: Array,
  loadingRowId: { type: String, default: null },
})

const emit = defineEmits(['create', 'edit', 'delete', 'assign', 'unassign'])

const search = ref('')
const activeFilter = ref('all')
const assigningId = ref(null)
const assignLoadingId = ref(null)

// ── Filters ───────────────────────────────────────────────
const filters = computed(() => [
  { key: 'all', label: 'Tous', count: props.pelerins.length },
  { key: 'actif', label: 'Actifs', count: props.pelerins.filter(p => p.utilisateur?.actif).length },
  { key: 'pending', label: 'En attente', count: props.pelerins.filter(p => !p.utilisateur?.actif).length },
  { key: 'nogroupe', label: 'Sans groupe', count: props.pelerins.filter(p => !p.groupeId).length },
])

const filtered = computed(() => {
  let list = props.pelerins
  // apply filter tab
  if (activeFilter.value === 'actif') list = list.filter(p => p.utilisateur?.actif)
  if (activeFilter.value === 'pending') list = list.filter(p => !p.utilisateur?.actif)
  if (activeFilter.value === 'nogroupe') list = list.filter(p => !p.groupeId)
  // apply search
  const q = search.value.toLowerCase()
  if (q) list = list.filter(p =>
    `${p.utilisateur?.prenom} ${p.utilisateur?.nom} ${p.utilisateur?.email}`.toLowerCase().includes(q)
  )
  return list
})

const emptyMessage = computed(() => {
  if (search.value) return `Aucun résultat pour "${search.value}"`
  if (activeFilter.value === 'actif') return 'Aucun pèlerin actif'
  if (activeFilter.value === 'pending') return 'Aucun pèlerin en attente'
  if (activeFilter.value === 'nogroupe') return 'Tous les pèlerins sont affectés à un groupe'
  return 'Aucun pèlerin pour le moment'
})

const emptyHint = computed(() => {
  if (search.value) return 'Essayez un autre terme de recherche'
  if (activeFilter.value === 'actif') return 'Les pèlerins actifs ont défini leur mot de passe'
  if (activeFilter.value === 'pending') return 'Ces pèlerins attendent de recevoir et valider leur email'
  if (activeFilter.value === 'nogroupe') return 'Bonne organisation !'
  return 'Ajoutez votre premier pèlerin pour commencer'
})

function initials(prenom, nom) {
  return ((prenom?.[0] ?? '') + (nom?.[0] ?? '')).toUpperCase() || '?'
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
</script>