<template>
  <div class="view-section">

    <!-- ── Topbar ── -->
    <div class="section-topbar">
      <div class="search-wrap">
        <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="15" height="15">
          <circle cx="11" cy="11" r="8"/>
          <line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input v-model="search" class="search-input" placeholder="Rechercher un guide..." />
      </div>
      <button @click="$emit('create')" class="btn-primary">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="15" height="15" style="margin-right:6px">
          <line x1="12" y1="5" x2="12" y2="19"/>
          <line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
        Nouveau guide
      </button>
    </div>

    <!-- ── Filter tabs ── -->
    <div class="filter-tabs">
      <button v-for="f in filters" :key="f.key"
        :class="['filter-tab', { active: activeFilter === f.key }]"
        @click="activeFilter = f.key">
        {{ f.label }}
        <span class="filter-count">{{ f.count }}</span>
      </button>
    </div>

    <!-- ── Table ── -->
    <div class="card">
      <div v-if="filtered.length === 0" class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" width="44" height="44" style="opacity:0.25;margin-bottom:12px">
          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
          <circle cx="12" cy="7" r="4"/>
        </svg>
        <p style="font-weight:600;margin-bottom:4px">{{ emptyMessage }}</p>
        <p style="font-size:12.5px;opacity:0.6;margin-bottom:14px">{{ emptyHint }}</p>
        <button v-if="activeFilter === 'all' && !search" @click="$emit('create')" class="btn-primary" style="font-size:13px;padding:7px 16px">
          + Ajouter le premier guide
        </button>
        <button v-else @click="activeFilter = 'all'; search = ''" class="btn-secondary" style="font-size:13px;padding:7px 16px">
          Voir tous les guides
        </button>
      </div>

      <table v-else class="data-table">
        <thead>
          <tr>
            <th>Guide</th>
            <th>Contact</th>
            <th>Spécialité</th>
            <th>Groupes</th>
            <th>Statut</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="g in filtered" :key="g.id"
            :class="{ 'row-loading': loadingRowId === g.id }">
            <td>
              <div class="cell-user">
                <div class="cell-avatar green-av">{{ initials(g.utilisateur?.prenom, g.utilisateur?.nom) }}</div>
                <div>
                  <div class="cell-name">{{ g.utilisateur?.prenom }} {{ g.utilisateur?.nom }}</div>
                  <div class="cell-sub">{{ g.utilisateur?.email }}</div>
                </div>
              </div>
            </td>
            <td>
              <div class="cell-name">{{ g.utilisateur?.telephone || '—' }}</div>
              <div class="cell-sub">{{ g.utilisateur?.email }}</div>
            </td>
            <td>
              <span v-if="g.specialite" class="specialite-tag">{{ g.specialite }}</span>
              <span v-else class="cell-sub">—</span>
            </td>
            <td>
              <span v-if="g._count?.groupes > 0" class="cell-name">{{ g._count.groupes }} groupe(s)</span>
              <span v-else class="cell-sub">Non assigné</span>
            </td>
            <td>
              <span :class="['status-pill', statusClass(g)]">{{ statusLabel(g) }}</span>
            </td>
            <td>
              <div class="action-btns">
                <!-- Resend activation -->
                <button v-if="!g.isActivated"
                  @click="$emit('resend', g)"
                  :disabled="resendingId === g.id || loadingRowId === g.id"
                  class="resend-btn" title="Renvoyer l'email d'activation">
                  <svg v-if="resendingId !== g.id" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="14" height="14">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                    <polyline points="22,6 12,13 2,6"/>
                  </svg>
                  <span v-else style="font-size:10px;font-weight:700">...</span>
                </button>
                <!-- Edit -->
                <button @click="$emit('edit', g)" class="act-btn" title="Modifier"
                  :disabled="loadingRowId === g.id">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="14" height="14">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
                <!-- Delete -->
                <button @click="$emit('delete', g)" class="act-btn act-btn-danger"
                  :disabled="g._count?.groupes > 0 || loadingRowId === g.id"
                  :title="g._count?.groupes > 0 ? 'Guide assigné à un groupe — retirez-le d\'abord' : 'Supprimer'">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="14" height="14">
                    <polyline points="3 6 5 6 21 6"/>
                    <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                    <path d="M10 11v6"/><path d="M14 11v6"/>
                    <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
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
  guides: Array,
  resendingId: { type: String, default: null },
  loadingRowId: { type: String, default: null },
})

defineEmits(['create', 'edit', 'delete', 'resend'])

const search = ref('')
const activeFilter = ref('all')

const filters = computed(() => [
  { key: 'all',       label: 'Tous',        count: props.guides.length },
  { key: 'actif',     label: 'Actifs',      count: props.guides.filter(g => g.isActivated && g.utilisateur?.actif).length },
  { key: 'pending',   label: 'En attente',  count: props.guides.filter(g => !g.isActivated).length },
  { key: 'suspended', label: 'Suspendus',   count: props.guides.filter(g => g.isActivated && !g.utilisateur?.actif).length },
  { key: 'assigned',  label: 'Assignés',    count: props.guides.filter(g => g._count?.groupes > 0).length },
])

const filtered = computed(() => {
  let list = props.guides
  if (activeFilter.value === 'actif')     list = list.filter(g => g.isActivated && g.utilisateur?.actif)
  if (activeFilter.value === 'pending')   list = list.filter(g => !g.isActivated)
  if (activeFilter.value === 'suspended') list = list.filter(g => g.isActivated && !g.utilisateur?.actif)
  if (activeFilter.value === 'assigned')  list = list.filter(g => g._count?.groupes > 0)
  const q = search.value.toLowerCase()
  if (q) list = list.filter(g =>
    `${g.utilisateur?.prenom} ${g.utilisateur?.nom} ${g.utilisateur?.email} ${g.specialite ?? ''}`.toLowerCase().includes(q)
  )
  return list
})

const emptyMessage = computed(() => {
  if (search.value) return `Aucun résultat pour "${search.value}"`
  if (activeFilter.value === 'actif')     return 'Aucun guide actif pour le moment'
  if (activeFilter.value === 'pending')   return 'Aucun guide en attente d\'activation'
  if (activeFilter.value === 'suspended') return 'Aucun guide suspendu'
  if (activeFilter.value === 'assigned')  return 'Aucun guide assigné à un groupe'
  return 'Aucun guide pour le moment'
})

const emptyHint = computed(() => {
  if (search.value) return 'Essayez un autre terme de recherche'
  if (activeFilter.value === 'pending') return 'Renvoyez l\'email d\'activation si nécessaire'
  if (activeFilter.value === 'actif')   return 'Les guides actifs ont défini leur mot de passe'
  return 'Ajoutez votre premier guide pour commencer'
})

function initials(prenom, nom) {
  return ((prenom?.[0] ?? '') + (nom?.[0] ?? '')).toUpperCase() || '?'
}

function statusClass(g) {
  if (!g.isActivated) return 'pending'
  if (!g.utilisateur?.actif) return 'suspended'
  return 'active'
}

function statusLabel(g) {
  if (!g.isActivated) return 'En attente'
  if (!g.utilisateur?.actif) return 'Suspendu'
  return 'Actif'
}
</script>