<template>
  <div class="view-section">
    <div class="section-topbar">
      <div class="search-wrap">
        <AppIcon class="search-icon" name="search" :size="15" />
        <input v-model="search" class="search-input" placeholder="Rechercher un groupe..." />
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
          <div class="group-type-badge" :class="groupe.typeVoyage === 'HAJJ' ? 'hajj' : 'umrah'">
            {{ groupe.typeVoyage }}
          </div>

          <div class="group-actions">
            <button @click="toggleExpand(groupe.id)" class="act-btn" :title="expandedId === groupe.id ? 'Reduire' : 'Voir details'">
              <AppIcon :name="expandedId === groupe.id ? 'chevron-up' : 'chevron-down'" :size="14" />
            </button>

            <button @click="$emit('edit', groupe)" class="act-btn" title="Modifier">
              <AppIcon name="edit" :size="14" />
            </button>

            <button @click="$emit('delete', groupe)" class="act-btn act-btn-danger" title="Supprimer">
              <AppIcon name="trash" :size="14" />
            </button>
          </div>
        </div>

        <div class="group-name">{{ groupe.nom }}</div>
        <div class="group-meta">{{ groupe.annee }} · {{ groupe.description || 'Pas de description' }}</div>

        <div class="group-stats">
          <div class="group-stat">
            <span class="gs-val">{{ groupe._count?.pelerins ?? groupe.pelerins?.length ?? 0 }}</span>
            <span class="gs-lbl">Pelerins</span>
          </div>
          <div class="group-stat">
            <span class="gs-val" :style="!groupe.guide ? 'color: var(--orange)' : ''">
              {{ groupe.guide ? 'OK' : '!' }}
            </span>
            <span class="gs-lbl" :style="!groupe.guide ? 'color: var(--orange)' : ''">Guide</span>
          </div>
        </div>

        <div v-if="groupe.guide" class="group-guide">
          <AppIcon name="user" :size="13" style="flex-shrink: 0" />
          {{ groupe.guide.utilisateur?.prenom }} {{ groupe.guide.utilisateur?.nom }}
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
                Guide assigne
              </div>

              <div v-if="groupe.guide" class="guide-detail-row">
                <div class="cell-avatar green-av" style="width: 30px; height: 30px; font-size: 11px">
                  {{ initials(groupe.guide.utilisateur?.prenom, groupe.guide.utilisateur?.nom) }}
                </div>
                <div>
                  <div class="cell-name" style="font-size: 13px">
                    {{ groupe.guide.utilisateur?.prenom }} {{ groupe.guide.utilisateur?.nom }}
                  </div>
                  <div class="cell-sub">{{ groupe.guide.utilisateur?.email }}</div>
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

        <button @click="$emit('assign', groupe)" class="btn-assign">
          <AppIcon name="plus" :size="13" :stroke-width="2" style="margin-right: 5px" />
          Affecter pelerin
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import { getInitials } from '@/features/agence/utils/initials'

const props = defineProps({
  groupes: {
    type: Array,
    default: () => [],
  },
})

defineEmits(['create', 'edit', 'delete', 'assign', 'remove-pelerin'])

const search = ref('')
const activeFilter = ref('all')
const expandedId = ref(null)

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
  if (activeFilter.value === 'hajj') return 'Aucun groupe Hajj'
  if (activeFilter.value === 'umrah') return 'Aucun groupe Umrah'
  if (activeFilter.value === 'noguide') return 'Tous les groupes ont un guide !'
  if (activeFilter.value === 'nopelerin') return 'Tous les groupes ont des pelerins !'
  return 'Aucun groupe pour le moment'
})

const emptyHint = computed(() => {
  if (search.value) return 'Essayez un autre terme de recherche'
  if (activeFilter.value === 'noguide') return 'Bonne organisation !'
  if (activeFilter.value === 'nopelerin') return 'Continuez comme ca !'
  return 'Creez votre premier groupe pour organiser vos pelerins'
})

function resetFilters() {
  activeFilter.value = 'all'
  search.value = ''
}

function toggleExpand(id) {
  expandedId.value = expandedId.value === id ? null : id
}

function initials(prenom, nom) {
  return getInitials(prenom, nom)
}
</script>
