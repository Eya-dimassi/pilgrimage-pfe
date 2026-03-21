<template>
  <div class="view-section">

    <!-- ── Topbar ── -->
    <div class="section-topbar">
      <div class="search-wrap">
        <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="15" height="15">
          <circle cx="11" cy="11" r="8"/>
          <line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input v-model="search" class="search-input" placeholder="Rechercher un groupe..." />
      </div>
      <button @click="$emit('create')" class="btn-primary">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="15" height="15" style="margin-right:6px">
          <line x1="12" y1="5" x2="12" y2="19"/>
          <line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
        Nouveau groupe
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

    <!-- ── Grid ── -->
    <div v-if="filtered.length === 0" class="empty-state" style="background:var(--bg2);border:1px solid var(--border);border-radius:16px;">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" width="44" height="44" style="opacity:0.25;margin-bottom:12px">
        <path d="M2 20h20"/><path d="M5 20V8l7-5 7 5v12"/><path d="M9 20v-6h6v6"/>
      </svg>
      <p style="font-weight:600;margin-bottom:4px">{{ emptyMessage }}</p>
      <p style="font-size:12.5px;opacity:0.6;margin-bottom:14px">{{ emptyHint }}</p>
      <button v-if="activeFilter === 'all' && !search" @click="$emit('create')" class="btn-primary" style="font-size:13px;padding:7px 16px">
        + Créer le premier groupe
      </button>
      <button v-else @click="activeFilter = 'all'; search = ''" class="btn-secondary" style="font-size:13px;padding:7px 16px">
        Voir tous les groupes
      </button>
    </div>

    <div v-else class="groups-grid">
      <div v-for="gr in filtered" :key="gr.id"
        :class="['group-card', { 'group-card--expanded': expandedId === gr.id }]">

        <!-- ── Header ── -->
        <div class="group-card-header">
          <div class="group-type-badge" :class="gr.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
            {{ gr.typeVoyage }}
          </div>
          <div class="group-actions">
            <button @click="toggleExpand(gr.id)" class="act-btn"
              :title="expandedId === gr.id ? 'Réduire' : 'Voir détails'">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="14" height="14">
                <polyline v-if="expandedId === gr.id" points="18 15 12 9 6 15"/>
                <polyline v-else points="6 9 12 15 18 9"/>
              </svg>
            </button>
            <button @click="$emit('edit', gr)" class="act-btn" title="Modifier">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="14" height="14">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
              </svg>
            </button>
            <button @click="$emit('delete', gr)" class="act-btn act-btn-danger" title="Supprimer">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="14" height="14">
                <polyline points="3 6 5 6 21 6"/>
                <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                <path d="M10 11v6"/><path d="M14 11v6"/>
                <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- ── Summary ── -->
        <div class="group-name">{{ gr.nom }}</div>
        <div class="group-meta">{{ gr.annee }} · {{ gr.description || 'Pas de description' }}</div>

        <div class="group-stats">
          <div class="group-stat">
            <span class="gs-val">{{ gr._count?.pelerins ?? gr.pelerins?.length ?? 0 }}</span>
            <span class="gs-lbl">Pèlerins</span>
          </div>
          <div class="group-stat">
            <span class="gs-val" :style="!gr.guide ? 'color:var(--orange)' : ''">
              {{ gr.guide ? '✓' : '!' }}
            </span>
            <span class="gs-lbl" :style="!gr.guide ? 'color:var(--orange)' : ''">Guide</span>
          </div>
        </div>

        <div v-if="gr.guide" class="group-guide">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="13" height="13" style="flex-shrink:0">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
            <circle cx="12" cy="7" r="4"/>
          </svg>
          {{ gr.guide.utilisateur?.prenom }} {{ gr.guide.utilisateur?.nom }}
        </div>
        <div v-else class="group-guide" style="color:var(--orange)">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="13" height="13" style="flex-shrink:0">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          Aucun guide assigné
        </div>

        <!-- ── Expanded details ── -->
        <transition name="expand">
          <div v-if="expandedId === gr.id" class="group-details">

            <!-- Guide section -->
            <div class="group-details-section">
              <div class="group-details-label">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="13" height="13">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                  <circle cx="12" cy="7" r="4"/>
                </svg>
                Guide assigné
              </div>
              <div v-if="gr.guide" class="guide-detail-row">
                <div class="cell-avatar green-av" style="width:30px;height:30px;font-size:11px">
                  {{ initials(gr.guide.utilisateur?.prenom, gr.guide.utilisateur?.nom) }}
                </div>
                <div>
                  <div class="cell-name" style="font-size:13px">
                    {{ gr.guide.utilisateur?.prenom }} {{ gr.guide.utilisateur?.nom }}
                  </div>
                  <div class="cell-sub">{{ gr.guide.utilisateur?.email }}</div>
                </div>
              </div>
              <div v-else class="group-details-empty" style="color:var(--orange)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="13" height="13" style="display:inline;margin-right:4px">
                  <circle cx="12" cy="12" r="10"/>
                  <line x1="12" y1="8" x2="12" y2="12"/>
                  <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                Aucun guide — modifiez le groupe pour en assigner un
              </div>
            </div>

            <!-- Pelerins section -->
            <div class="group-details-section">
              <div class="group-details-label">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="13" height="13">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                  <circle cx="9" cy="7" r="4"/>
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                  <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
                Pèlerins ({{ gr.pelerins?.length ?? 0 }})
              </div>
              <div v-if="!gr.pelerins || gr.pelerins.length === 0" class="group-details-empty">
                Aucun pèlerin — utilisez "Affecter pèlerin" depuis la vue Pèlerins
              </div>
              <div v-for="p in gr.pelerins" :key="p.id" class="pelerin-detail-row">
                <div class="cell-avatar" style="width:30px;height:30px;font-size:11px">
                  {{ initials(p.utilisateur?.prenom, p.utilisateur?.nom) }}
                </div>
                <div class="pelerin-detail-info">
                  <div class="cell-name" style="font-size:13px">
                    {{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}
                  </div>
                  <div class="cell-sub">{{ p.utilisateur?.email }}</div>
                </div>
                <button @click="$emit('remove-pelerin', { groupeId: gr.id, pelerinId: p.id })"
                  class="act-btn act-btn-danger" title="Retirer du groupe"
                  style="width:26px;height:26px;flex-shrink:0">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" width="12" height="12">
                    <line x1="18" y1="6" x2="6" y2="18"/>
                    <line x1="6" y1="6" x2="18" y2="18"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </transition>

        <button @click="$emit('assign', gr)" class="btn-assign">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="13" height="13" style="margin-right:5px">
            <line x1="12" y1="5" x2="12" y2="19"/>
            <line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Affecter pèlerin
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({ groupes: Array })
defineEmits(['create', 'edit', 'delete', 'assign', 'remove-pelerin'])

const search = ref('')
const activeFilter = ref('all')
const expandedId = ref(null)

const filters = computed(() => [
  { key: 'all',      label: 'Tous',        count: props.groupes.length },
  { key: 'hajj',     label: 'Hajj',        count: props.groupes.filter(g => g.typeVoyage === 'HAJJ').length },
  { key: 'umrah',    label: 'Umrah',       count: props.groupes.filter(g => g.typeVoyage === 'UMRAH').length },
  { key: 'noguide',  label: 'Sans guide',  count: props.groupes.filter(g => !g.guide).length },
  { key: 'nopelerin',label: 'Vides',       count: props.groupes.filter(g => (g._count?.pelerins ?? 0) === 0).length },
])

const filtered = computed(() => {
  let list = props.groupes
  if (activeFilter.value === 'hajj')      list = list.filter(g => g.typeVoyage === 'HAJJ')
  if (activeFilter.value === 'umrah')     list = list.filter(g => g.typeVoyage === 'UMRAH')
  if (activeFilter.value === 'noguide')   list = list.filter(g => !g.guide)
  if (activeFilter.value === 'nopelerin') list = list.filter(g => (g._count?.pelerins ?? 0) === 0)
  const q = search.value.toLowerCase()
  if (q) list = list.filter(g => g.nom.toLowerCase().includes(q))
  return list
})

const emptyMessage = computed(() => {
  if (search.value) return `Aucun résultat pour "${search.value}"`
  if (activeFilter.value === 'hajj')      return 'Aucun groupe Hajj'
  if (activeFilter.value === 'umrah')     return 'Aucun groupe Umrah'
  if (activeFilter.value === 'noguide')   return 'Tous les groupes ont un guide !'
  if (activeFilter.value === 'nopelerin') return 'Tous les groupes ont des pèlerins !'
  return 'Aucun groupe pour le moment'
})

const emptyHint = computed(() => {
  if (search.value) return 'Essayez un autre terme de recherche'
  if (activeFilter.value === 'noguide')   return 'Bonne organisation !'
  if (activeFilter.value === 'nopelerin') return 'Continuez comme ça !'
  return 'Créez votre premier groupe pour organiser vos pèlerins'
})

function toggleExpand(id) {
  expandedId.value = expandedId.value === id ? null : id
}

function initials(prenom, nom) {
  return ((prenom?.[0] ?? '') + (nom?.[0] ?? '')).toUpperCase() || '?'
}
</script>