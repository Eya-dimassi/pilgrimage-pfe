<template>
  <div class="view-section">
    <div class="section-topbar">
      <div class="search-wrap">
        <AppIcon class="search-icon" name="search" :size="15" />
        <input v-model="search" class="search-input" placeholder="Rechercher un guide..." />
      </div>

      <button @click="$emit('create')" class="btn-primary">
        <AppIcon name="plus" :size="15" :stroke-width="2" style="margin-right: 6px" />
        Nouveau guide
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

    <div class="card">
      <div v-if="filtered.length === 0" class="empty-state">
        <AppIcon name="user" :size="44" :stroke-width="1.5" style="opacity: 0.25; margin-bottom: 12px" />

        <p style="font-weight: 600; margin-bottom: 4px">{{ emptyMessage }}</p>
        <p style="font-size: 12.5px; opacity: 0.6; margin-bottom: 14px">{{ emptyHint }}</p>

        <button
          v-if="activeFilter === 'all' && !search"
          @click="$emit('create')"
          class="btn-primary"
          style="font-size: 13px; padding: 7px 16px"
        >
          + Ajouter le premier guide
        </button>
        <button
          v-else
          @click="resetFilters"
          class="btn-secondary"
          style="font-size: 13px; padding: 7px 16px"
        >
          Voir tous les guides
        </button>
      </div>

      <table v-else class="data-table">
        <thead>
          <tr>
            <th>Guide</th>
            <th>Contact</th>
            <th>Specialite</th>
            <th>Groupes</th>
            <th>Statut</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="guide in filtered" :key="guide.id" :class="{ 'row-loading': loadingRowId === guide.id }">
            <td>
              <div class="cell-user">
                <div class="cell-avatar green-av">
                  {{ initials(guide.utilisateur?.prenom, guide.utilisateur?.nom) }}
                </div>
                <div>
                  <div class="cell-name">
                    {{ guide.utilisateur?.prenom }} {{ guide.utilisateur?.nom }}
                  </div>
                  <div class="cell-sub">{{ guide.utilisateur?.email }}</div>
                </div>
              </div>
            </td>

            <td>
              <div class="cell-name">{{ guide.utilisateur?.telephone || '-' }}</div>
              <div class="cell-sub">{{ guide.utilisateur?.email }}</div>
            </td>

            <td>
              <span v-if="guide.specialite" class="specialite-tag">{{ guide.specialite }}</span>
              <span v-else class="cell-sub">-</span>
            </td>

            <td>
              <span v-if="guide._count?.groupes > 0" class="cell-name">{{ guide._count.groupes }} groupe(s)</span>
              <span v-else class="cell-sub">Non assigne</span>
            </td>

            <td>
              <StatusPill :tone="guideStatusClass(guide)">{{ guideStatusLabel(guide) }}</StatusPill>
            </td>

            <td>
              <div class="action-btns">
                <button
                  @click="$emit('detail', guide)"
                  class="act-btn"
                  title="Voir details"
                  :disabled="loadingRowId === guide.id"
                >
                  <AppIcon name="eye" :size="14" />
                </button>

                <button
                  v-if="!guide.isActivated"
                  @click="$emit('resend', guide)"
                  :disabled="resendingId === guide.id || loadingRowId === guide.id"
                  class="resend-btn"
                  title="Renvoyer l'email d'activation"
                >
                  <AppIcon v-if="resendingId !== guide.id" name="mail" :size="14" />
                  <span v-else style="font-size: 10px; font-weight: 700">...</span>
                </button>

                <button
                  @click="$emit('edit', guide)"
                  class="act-btn"
                  title="Modifier"
                  :disabled="loadingRowId === guide.id"
                >
                  <AppIcon name="edit" :size="14" />
                </button>

                <button
                  @click="$emit('delete', guide)"
                  class="act-btn act-btn-danger"
                  :disabled="guide._count?.groupes > 0 || loadingRowId === guide.id"
                  :title="guide._count?.groupes > 0 ? 'Guide assigne a un groupe - retirez-le d abord' : 'Supprimer'"
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
import { computed } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import StatusPill from '@/features/agence/components/dashboard/StatusPill.vue'
import { useGuideStatus } from '@/features/agence/composables/useGuideStatus'
import { useSearchFilter } from '@/features/agence/composables/useSearchFilter'
import { getInitials } from '@/features/agence/utils/initials'

const props = defineProps({
  guides: {
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
})

defineEmits(['create', 'detail', 'edit', 'delete', 'resend'])

const { guideStatusClass, guideStatusLabel } = useGuideStatus()

const filterConfigs = computed(() => [
  { key: 'all', label: 'Tous', predicate: () => true },
  { key: 'actif', label: 'Actifs', predicate: (guide) => guide.isActivated && guide.utilisateur?.actif },
  { key: 'pending', label: 'En attente', predicate: (guide) => !guide.isActivated },
  { key: 'suspended', label: 'Suspendus', predicate: (guide) => guide.isActivated && !guide.utilisateur?.actif },
  { key: 'assigned', label: 'Assignes', predicate: (guide) => guide._count?.groupes > 0 },
])

const { search, activeFilter, filters, filtered, resetFilters } = useSearchFilter({
  items: computed(() => props.guides),
  filterConfigs,
  searchableText: (guide) =>
    `${guide.utilisateur?.prenom ?? ''} ${guide.utilisateur?.nom ?? ''} ${guide.utilisateur?.email ?? ''} ${guide.specialite ?? ''}`,
})

const emptyMessage = computed(() => {
  if (search.value) return `Aucun resultat pour "${search.value}"`
  if (activeFilter.value === 'actif') return 'Aucun guide actif pour le moment'
  if (activeFilter.value === 'pending') return "Aucun guide en attente d'activation"
  if (activeFilter.value === 'suspended') return 'Aucun guide suspendu'
  if (activeFilter.value === 'assigned') return 'Aucun guide assigne a un groupe'
  return 'Aucun guide pour le moment'
})

const emptyHint = computed(() => {
  if (search.value) return 'Essayez un autre terme de recherche'
  if (activeFilter.value === 'pending') return "Renvoyez l'email d'activation si necessaire"
  if (activeFilter.value === 'actif') return 'Les guides actifs ont defini leur mot de passe'
  return 'Ajoutez votre premier guide pour commencer'
})

function initials(prenom, nom) {
  return getInitials(prenom, nom)
}
</script>
