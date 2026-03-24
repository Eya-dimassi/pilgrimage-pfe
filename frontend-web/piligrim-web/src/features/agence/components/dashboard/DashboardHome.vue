<template>
  <div class="view-dashboard">
    <div class="stats-grid">
      <DashboardStatCard
        tone="gold"
        icon-name="home"
        :value="groupes.length"
        label="Groupes"
        clickable
        @select="$emit('navigate', 'groupes')"
      >
        {{ groupes.filter((g) => g.typeVoyage === 'HAJJ').length }} Hajj ·
        {{ groupes.filter((g) => g.typeVoyage === 'UMRAH').length }} Umrah
      </DashboardStatCard>

      <DashboardStatCard
        tone="blue"
        icon-name="users"
        :value="pelerins.length"
        label="Pelerins"
        clickable
        @select="$emit('navigate', 'pelerins')"
      >
        {{ pelerins.filter((p) => p.utilisateur?.actif).length }} actifs ·
        <span :class="pelerinsWithoutGroupCount > 0 ? 'stat-sub-warn' : ''">
          {{ pelerinsWithoutGroupCount }} sans groupe
        </span>
      </DashboardStatCard>

      <DashboardStatCard
        tone="green"
        icon-name="user"
        :value="guides.length"
        label="Guides"
        clickable
        @select="$emit('navigate', 'guides')"
      >
        {{ activatedGuidesCount }} actives ·
        <span :class="pendingGuidesCount > 0 ? 'stat-sub-warn' : ''">
          {{ pendingGuidesCount }} en attente
        </span>
      </DashboardStatCard>

      <DashboardStatCard
        tone="orange"
        icon-name="alert"
        :value="pendingActivationsCount"
        label="En attente"
      >
        Activation email
      </DashboardStatCard>
    </div>

    <div v-if="actionsNeeded.length > 0" class="actions-banner">
      <div class="actions-banner-icon">
        <AppIcon name="alert" :size="16" />
      </div>
      <div class="actions-banner-items">
        <span
          v-for="action in actionsNeeded"
          :key="action.key"
          class="action-chip"
          style="cursor: pointer"
          @click="$emit('navigate', action.view)"
        >
          {{ action.label }}
        </span>
      </div>
    </div>

    <div class="recent-grid">
      <DashboardMiniListCard
        title="Derniers pelerins"
        :is-empty="pelerins.length === 0"
        empty-icon-name="users"
        empty-text="Aucun pelerin"
        empty-action-text="+ Ajouter le premier"
        view-all-text="Voir tout ->"
        @view-all="$emit('navigate', 'pelerins')"
        @empty-action="$emit('open-modal', 'createPelerin')"
      >
        <div v-for="p in pelerins.slice(0, 5)" :key="p.id" class="mini-row">
          <div class="mini-avatar">{{ initials(p.utilisateur?.prenom, p.utilisateur?.nom) }}</div>
          <div class="mini-info">
            <div class="mini-name">{{ p.utilisateur?.prenom }} {{ p.utilisateur?.nom }}</div>
            <div class="mini-sub">{{ p.groupe?.nom || 'Sans groupe' }}</div>
          </div>
          <StatusPill :tone="p.utilisateur?.actif ? 'active' : 'pending'">
            {{ p.utilisateur?.actif ? 'Actif' : 'En attente' }}
          </StatusPill>
        </div>
      </DashboardMiniListCard>

      <DashboardMiniListCard
        title="Derniers guides"
        :is-empty="guides.length === 0"
        empty-icon-name="user"
        empty-text="Aucun guide"
        empty-action-text="+ Ajouter le premier"
        view-all-text="Voir tout ->"
        @view-all="$emit('navigate', 'guides')"
        @empty-action="$emit('open-modal', 'createGuide')"
      >
        <div v-for="g in guides.slice(0, 5)" :key="g.id" class="mini-row">
          <div class="mini-avatar green-av">{{ initials(g.utilisateur?.prenom, g.utilisateur?.nom) }}</div>
          <div class="mini-info">
            <div class="mini-name">{{ g.utilisateur?.prenom }} {{ g.utilisateur?.nom }}</div>
            <div class="mini-sub">{{ g.specialite || 'Pas de specialite' }}</div>
          </div>
          <StatusPill :tone="guideStatusClass(g)">{{ guideStatusLabel(g) }}</StatusPill>
        </div>
      </DashboardMiniListCard>

      <DashboardMiniListCard
        title="Groupes"
        :is-empty="groupes.length === 0"
        empty-icon-name="home"
        empty-text="Aucun groupe"
        empty-action-text="+ Creer le premier"
        view-all-text="Voir tout ->"
        @view-all="$emit('navigate', 'groupes')"
        @empty-action="$emit('open-modal', 'createGroupe')"
      >
        <div v-for="g in groupes.slice(0, 5)" :key="g.id" class="mini-row">
          <div class="mini-avatar gold-av">{{ getGroupSymbol(g.typeVoyage) }}</div>
          <div class="mini-info">
            <div class="mini-name">{{ g.nom }}</div>
            <div class="mini-sub">
              {{ g.annee }} · {{ g._count?.pelerins ?? 0 }} pelerins
              <span v-if="!g.guide" class="mini-warn">· sans guide</span>
            </div>
          </div>
          <span class="type-pill">{{ g.typeVoyage }}</span>
        </div>
      </DashboardMiniListCard>
    </div>
  </div>
</template>

<script setup>
import AppIcon from '@/components/AppIcon.vue'
import DashboardMiniListCard from '@/features/agence/components/dashboard/DashboardMiniListCard.vue'
import DashboardStatCard from '@/features/agence/components/dashboard/DashboardStatCard.vue'
import StatusPill from '@/features/agence/components/dashboard/StatusPill.vue'

defineProps({
  pelerins: {
    type: Array,
    required: true,
  },
  guides: {
    type: Array,
    required: true,
  },
  groupes: {
    type: Array,
    required: true,
  },
  pelerinsWithoutGroupCount: {
    type: Number,
    required: true,
  },
  activatedGuidesCount: {
    type: Number,
    required: true,
  },
  pendingGuidesCount: {
    type: Number,
    required: true,
  },
  pendingActivationsCount: {
    type: Number,
    required: true,
  },
  actionsNeeded: {
    type: Array,
    required: true,
  },
  initials: {
    type: Function,
    required: true,
  },
  guideStatusClass: {
    type: Function,
    required: true,
  },
  guideStatusLabel: {
    type: Function,
    required: true,
  },
  getGroupSymbol: {
    type: Function,
    required: true,
  },
})

defineEmits(['navigate', 'open-modal'])
</script>
