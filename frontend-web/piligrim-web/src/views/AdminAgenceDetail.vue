<template>
  <div class="ad-modal-overlay" @click.self="$emit('close')">
    <div class="ad-modal-box ad-modal-box--wide" style="position:relative">

      <!-- Close button -->
      <button class="ad-modal-close-top" @click="$emit('close')">
        <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>
      </button>

      <!-- Loading -->
      <div v-if="loading" class="state-center" style="padding: 3rem">
        <svg class="ad-spinner" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" stroke-dasharray="40" stroke-dashoffset="10"/>
        </svg>
      </div>

      <!-- Error -->
      <div v-else-if="error" class="state-error">
        <p>{{ error }}</p>
      </div>

      <!-- Content -->
      <template v-else-if="agence">
        <!-- Header -->
        <div class="detail-header">
          <div class="detail-avatar">{{ agence.nomAgence?.[0]?.toUpperCase() }}</div>
          <div style="flex:1">
            <p class="detail-agency-name">{{ agence.nomAgence }}</p>
            <p class="detail-agency-email">{{ agence.utilisateur?.email }}</p>
          </div>
          <span class="status-badge" :class="statusClass(agence.status)">{{ statusLabel(agence.status) }}</span>
        </div>

        <!-- Stats row -->
        <div class="detail-stats-row">
          <div class="detail-stat">
            <p class="detail-stat-num">{{ agence._count?.pelerins ?? 0 }}</p>
            <p class="detail-stat-label">Pèlerins</p>
          </div>
          <div class="detail-stat">
            <p class="detail-stat-num">{{ agence._count?.guides ?? 0 }}</p>
            <p class="detail-stat-label">Guides</p>
          </div>
          <div class="detail-stat">
            <p class="detail-stat-num">{{ agence._count?.groupes ?? 0 }}</p>
            <p class="detail-stat-label">Groupes</p>
          </div>
        </div>

        <!-- Info grid -->
        <p class="detail-section-title">Informations agence</p>
        <div class="detail-grid">
          <div class="detail-field">
            <span class="detail-label">Nom de l'agence</span>
            <span class="detail-value">{{ agence.nomAgence || '—' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Adresse</span>
            <span class="detail-value">{{ agence.adresse || '—' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Téléphone</span>
            <span class="detail-value">{{ agence.telephone || agence.utilisateur?.telephone || '—' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Site web</span>
            <span class="detail-value">
              <a v-if="agence.siteWeb" :href="agence.siteWeb" target="_blank" style="color: var(--ad-accent)">{{ agence.siteWeb }}</a>
              <span v-else>—</span>
            </span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Inscrit le</span>
            <span class="detail-value">{{ formatDate(agence.createdAt) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Statut compte</span>
            <span class="detail-value">{{ agence.utilisateur?.actif ? 'Actif' : 'Inactif' }}</span>
          </div>
        </div>

        <!-- Contact info -->
        <p class="detail-section-title">Contact</p>
        <div class="detail-grid">
          <div class="detail-field">
            <span class="detail-label">Nom</span>
            <span class="detail-value">{{ agence.utilisateur?.nom || '—' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Email</span>
            <span class="detail-value">{{ agence.utilisateur?.email || '—' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Téléphone</span>
            <span class="detail-value">{{ agence.utilisateur?.telephone || '—' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Membre depuis</span>
            <span class="detail-value">{{ formatDate(agence.utilisateur?.createdAt) }}</span>
          </div>
        </div>
      </template>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAdmin } from '@/composables/useAdmin'

const props = defineProps({ agenceId: { type: String, required: true } })
defineEmits(['close'])

const { getAgenceById, statusLabel, statusClass, formatDate } = useAdmin()

const agence  = ref(null)
const loading = ref(true)
const error   = ref('')

onMounted(async () => {
  try {
    agence.value = await getAgenceById(props.agenceId)
  } catch {
    error.value = 'Impossible de charger les détails de cette agence.'
  } finally {
    loading.value = false
  }
})
</script>