<template>
  <div class="ad-modal-overlay" @click.self="$emit('close')">
    <div class="ad-modal-box ad-modal-box--wide pelerin-detail-modal">
      <button class="ad-modal-close-top" type="button" @click="$emit('close')">
        <AppIcon name="x" :size="14" :stroke-width="2.5" />
      </button>

      <div v-if="loading" class="state-center pelerin-detail-state">
        <AppIcon class="ad-spinner" name="spinner" :size="24" :stroke-width="3" spin />
      </div>

      <div v-else-if="error" class="state-error pelerin-detail-state">
        <p>{{ error }}</p>
      </div>

      <template v-else-if="pelerin">
        <div class="detail-header">
          <div class="detail-avatar pelerin-detail-avatar">
            {{ initials(pelerin.utilisateur?.prenom, pelerin.utilisateur?.nom) }}
          </div>
          <div style="flex: 1">
            <p class="detail-agency-name">{{ pelerin.utilisateur?.prenom }} {{ pelerin.utilisateur?.nom }}</p>
            <p class="detail-agency-email">{{ pelerin.utilisateur?.email || '-' }}</p>
          </div>
          <span class="status-badge" :class="statusBadgeClass">{{ statusLabel }}</span>
        </div>

        <div class="detail-stats-row">
          <div class="detail-stat">
            <p class="detail-stat-num">{{ pelerin.groupe ? 'Oui' : 'Non' }}</p>
            <p class="detail-stat-label">Dans un groupe</p>
          </div>
          <div class="detail-stat">
            <p class="detail-stat-num">{{ pelerin.nationalite || '-' }}</p>
            <p class="detail-stat-label">Nationalite</p>
          </div>
          <div class="detail-stat">
            <p class="detail-stat-num">{{ pelerin.utilisateur?.actif ? 'Oui' : 'Non' }}</p>
            <p class="detail-stat-label">Compte active</p>
          </div>
        </div>

        <p class="detail-section-title">Informations du pelerin</p>
        <div class="detail-grid">
          <div class="detail-field">
            <span class="detail-label">Prenom</span>
            <span class="detail-value">{{ pelerin.utilisateur?.prenom || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Nom</span>
            <span class="detail-value">{{ pelerin.utilisateur?.nom || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Email</span>
            <span class="detail-value">{{ pelerin.utilisateur?.email || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Telephone</span>
            <span class="detail-value">{{ pelerin.utilisateur?.telephone || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Numero passeport</span>
            <span class="detail-value">{{ pelerin.numeroPasseport || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Date naissance</span>
            <span class="detail-value">{{ formatDate(pelerin.dateNaissance) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Code unique</span>
            <span class="detail-value">{{ pelerin.codeUnique || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Membre depuis</span>
            <span class="detail-value">{{ formatDate(pelerin.utilisateur?.createdAt) }}</span>
          </div>
        </div>

        <p class="detail-section-title">Groupe</p>
        <div class="detail-grid">
          <div class="detail-field">
            <span class="detail-label">Nom du groupe</span>
            <span class="detail-value">{{ pelerin.groupe?.nom || '-' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Type voyage</span>
            <span class="detail-value">{{ pelerin.groupe?.typeVoyage || '-' }}</span>
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
  pelerin: {
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

const statusLabel = computed(() => (props.pelerin?.utilisateur?.actif ? 'Actif' : 'En attente'))
const statusBadgeClass = computed(() => (props.pelerin?.utilisateur?.actif ? 'badge--green' : 'badge--orange'))

function initials(prenom, nom) {
  return ((prenom?.[0] ?? '') + (nom?.[0] ?? '')).toUpperCase() || '?'
}

function formatDate(value) {
  if (!value) return '-'
  return new Date(value).toLocaleDateString('fr-FR')
}
</script>

<style scoped>
.pelerin-detail-modal {
  position: relative;
}

.pelerin-detail-state {
  padding: 3rem;
}

.pelerin-detail-avatar {
  background: linear-gradient(135deg, #7a3b0a, #c9894c);
  color: #fff;
  border-color: rgba(201, 168, 76, 0.55);
}
</style>

