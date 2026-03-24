<template>
  <div>
    <div v-if="loading" class="state-center">
      <AppIcon class="ad-spinner" name="spinner" :size="24" :stroke-width="3" spin />
      <p>Chargement...</p>
    </div>

    <div v-else-if="fetchError" class="state-error">
      <p>{{ fetchError }}</p>
      <button @click="loadAgences" class="btn-retry">Reessayer</button>
    </div>

    <template v-else>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon stat-icon--blue">
            <AppIcon name="building" :size="20" :stroke-width="2" />
          </div>
          <p class="stat-label">Total Agences</p>
          <p class="stat-value">{{ agences.length }}</p>
          <p class="stat-sub stat-sub--green">{{ approvedCount }} approuvees</p>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon--orange">
            <AppIcon name="alert" :size="20" :stroke-width="2" />
          </div>
          <p class="stat-label">En attente</p>
          <p class="stat-value stat-value--orange">{{ pendingCount }}</p>
          <p v-if="pendingCount > 0" class="stat-sub stat-sub--orange">Action requise</p>
          <p v-else class="stat-sub">Aucune action</p>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon--purple">
            <AppIcon name="user" :size="20" :stroke-width="2" />
          </div>
          <p class="stat-label">Total Guides</p>
          <p class="stat-value">{{ totalGuides }}</p>
          <p class="stat-sub">Sur la plateforme</p>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon--green">
            <AppIcon name="users" :size="20" :stroke-width="2" />
          </div>
          <p class="stat-label">Total Pelerins</p>
          <p class="stat-value">{{ totalPelerins }}</p>
          <p class="stat-sub">Sur la plateforme</p>
        </div>
      </div>

      <div class="dash-grid">
        <div class="ad-card">
          <div class="ad-card-header">
            <h3 class="ad-card-title">Dernieres inscriptions</h3>
            <button class="ad-card-link" @click="$emit('go-agences')">Voir tout -></button>
          </div>

          <div class="recent-list">
            <div v-if="agences.length === 0" class="empty-state">Aucune agence inscrite</div>
            <div v-for="agence in agences.slice(0, 5)" :key="agence.id" class="recent-row">
              <div class="recent-avatar">{{ agence.nomAgence?.[0]?.toUpperCase() }}</div>
              <div class="recent-info">
                <p class="recent-name">{{ agence.nomAgence }}</p>
                <p class="recent-email">{{ agence.utilisateur?.email }}</p>
              </div>
              <span class="status-badge" :class="statusClass(agence.status)">{{ statusLabel(agence.status) }}</span>
            </div>
          </div>
        </div>

        <div class="ad-card">
          <div class="ad-card-header">
            <h3 class="ad-card-title">Actions rapides</h3>
          </div>
          <div class="quick-grid">
            <button class="quick-btn quick-btn--orange" @click="$emit('go-agences', 'PENDING')">
              <span class="quick-count">{{ pendingCount }}</span>
              <span class="quick-label">En attente</span>
            </button>
            <button class="quick-btn quick-btn--green" @click="$emit('go-agences', 'APPROVED')">
              <span class="quick-count">{{ approvedCount }}</span>
              <span class="quick-label">Approuvees</span>
            </button>
            <button class="quick-btn quick-btn--red" @click="$emit('go-agences', 'REJECTED')">
              <span class="quick-count">{{ rejectedCount }}</span>
              <span class="quick-label">Refusees</span>
            </button>
            <button class="quick-btn quick-btn--gray" @click="$emit('go-agences', 'SUSPENDED')">
              <span class="quick-count">{{ suspendedCount }}</span>
              <span class="quick-label">Suspendues</span>
            </button>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { useAdmin } from '@/features/admin/composables/useAdmin'
import AppIcon from '@/components/AppIcon.vue'

defineEmits(['go-agences'])

const {
  agences,
  loading,
  fetchError,
  pendingCount,
  approvedCount,
  rejectedCount,
  suspendedCount,
  totalGuides,
  totalPelerins,
  loadAgences,
  statusLabel,
  statusClass,
} = useAdmin()
</script>
