<template>
  <div class="ad-modal-overlay" @click.self="$emit('close')">
    <div class="ad-modal-box ad-modal-box--wide guide-detail-modal">
      <button class="ad-modal-close-top" type="button" @click="$emit('close')">
        <AppIcon name="x" :size="14" :stroke-width="2.5" />
      </button>

      <div v-if="loading" class="state-center guide-detail-state">
        <AppIcon class="ad-spinner" name="spinner" :size="24" :stroke-width="3" spin />
      </div>

      <div v-else-if="error" class="state-error guide-detail-state">
        <p>{{ error }}</p>
      </div>

      <template v-else-if="guide">
        <div class="detail-header">
          <div class="detail-avatar guide-detail-avatar">
            {{ initials(guide.utilisateur?.prenom, guide.utilisateur?.nom) }}
          </div>
          <div style="flex: 1">
            <p class="detail-agency-name">{{ guide.utilisateur?.prenom }} {{ guide.utilisateur?.nom }}</p>
            <p class="detail-agency-email">{{ guide.utilisateur?.email || '-' }}</p>
          </div>
          <span class="status-badge" :class="statusClass">{{ statusLabel }}</span>
        </div>

        <div class="detail-stats-row">
          <div class="detail-stat">
            <p class="detail-stat-num">{{ stats?.totalGroupes ?? guide._count?.groupes ?? 0 }}</p>
            <p class="detail-stat-label">Groupes</p>
          </div>
          <div class="detail-stat">
            <p class="detail-stat-num">{{ stats?.totalPelerins ?? 0 }}</p>
            <p class="detail-stat-label">Pelerins suivis</p>
          </div>
          <div class="detail-stat">
            <p class="detail-stat-num">{{ guide.isActivated ? 'Oui' : 'Non' }}</p>
            <p class="detail-stat-label">Compte active</p>
          </div>
        </div>

        <p class="detail-section-title">Informations du guide</p>
        <div class="detail-grid">
          <div class="detail-field">
            <span class="detail-label">Prenom</span>
            <span class="detail-value">{{ guide.utilisateur?.prenom || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Nom</span>
            <span class="detail-value">{{ guide.utilisateur?.nom || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Email</span>
            <span class="detail-value">{{ guide.utilisateur?.email || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Telephone</span>
            <span class="detail-value">{{ guide.utilisateur?.telephone || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Specialite</span>
            <span class="detail-value">{{ guide.specialite || 'Aucune specialite' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Membre depuis</span>
            <span class="detail-value">{{ formatDate(guide.utilisateur?.createdAt) }}</span>
          </div>
        </div>

        <p class="detail-section-title">Repartition des groupes</p>
        <div class="detail-grid">
          <div class="detail-field">
            <span class="detail-label">Groupes Hajj</span>
            <span class="detail-value">{{ stats?.groupesParType?.HAJJ ?? 0 }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Groupes Umrah</span>
            <span class="detail-value">{{ stats?.groupesParType?.UMRAH ?? 0 }}</span>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import AppIcon from '@/components/AppIcon.vue'

const props = defineProps({
  guide: {
    type: Object,
    default: null,
  },
  stats: {
    type: Object,
    default: null,
  },
  loading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: '',
  },
})

defineEmits(['close'])

const statusLabel = computed(() => {
  if (!props.guide) return '-'
  if (!props.guide.isActivated) return 'En attente'
  return props.guide.utilisateur?.actif ? 'Actif' : 'Suspendu'
})

const statusClass = computed(() => {
  if (!props.guide) return ''
  if (!props.guide.isActivated) return 'pending'
  return props.guide.utilisateur?.actif ? 'approved' : 'suspended'
})

function initials(prenom, nom) {
  return ((prenom?.[0] ?? '') + (nom?.[0] ?? '')).toUpperCase() || '?'
}

function formatDate(value) {
  if (!value) return '-'
  return new Date(value).toLocaleDateString('fr-FR')
}
</script>

<style scoped>
.guide-detail-modal {
  position: relative;
}

.guide-detail-state {
  padding: 3rem;
}

.guide-detail-avatar {
  background: linear-gradient(135deg, #2d7a4a, #5ca678);
}
</style>
