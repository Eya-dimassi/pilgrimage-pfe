<template>
  <div>
    <!-- Loading / Error -->
    <div v-if="loading" class="state-center">
      <svg class="ad-spinner" viewBox="0 0 24 24" fill="none">
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" stroke-dasharray="40" stroke-dashoffset="10"/>
      </svg>
      <p>Chargement...</p>
    </div>

    <div v-else-if="fetchError" class="state-error">
      <p>{{ fetchError }}</p>
      <button @click="loadAgences" class="btn-retry">Réessayer</button>
    </div>

    <template v-else>
      <!-- Stats -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon stat-icon--blue">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
            </svg>
          </div>
          <p class="stat-label">Total Agences</p>
          <p class="stat-value">{{ agences.length }}</p>
          <p class="stat-sub stat-sub--green">{{ approvedCount }} approuvées</p>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon--orange">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
          </div>
          <p class="stat-label">En Attente</p>
          <p class="stat-value stat-value--orange">{{ pendingCount }}</p>
          <p class="stat-sub stat-sub--orange" v-if="pendingCount > 0">Action requise</p>
          <p class="stat-sub" v-else>Aucune action</p>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon--purple">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
            </svg>
          </div>
          <p class="stat-label">Total Guides</p>
          <p class="stat-value">{{ totalGuides }}</p>
          <p class="stat-sub">Sur la plateforme</p>
        </div>

        <div class="stat-card">
          <div class="stat-icon stat-icon--green">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
          </div>
          <p class="stat-label">Total Pèlerins</p>
          <p class="stat-value">{{ totalPelerins }}</p>
          <p class="stat-sub">Sur la plateforme</p>
        </div>
      </div>

      <!-- Bottom grid -->
      <div class="dash-grid">
        <!-- Recent registrations -->
        <div class="ad-card">
          <div class="ad-card-header">
            <h3 class="ad-card-title">Dernières Inscriptions</h3>
            <button class="ad-card-link" @click="$emit('go-agences')">Voir tout →</button>
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

        <!-- Quick actions -->
        <div class="ad-card">
          <div class="ad-card-header">
            <h3 class="ad-card-title">Actions Rapides</h3>
          </div>
          <div class="quick-grid">
            <button class="quick-btn quick-btn--orange" @click="$emit('go-agences', 'PENDING')">
              <span class="quick-count">{{ pendingCount }}</span>
              <span class="quick-label">En attente</span>
            </button>
            <button class="quick-btn quick-btn--green" @click="$emit('go-agences', 'APPROVED')">
              <span class="quick-count">{{ approvedCount }}</span>
              <span class="quick-label">Approuvées</span>
            </button>
            <button class="quick-btn quick-btn--red" @click="$emit('go-agences', 'REJECTED')">
              <span class="quick-count">{{ rejectedCount }}</span>
              <span class="quick-label">Refusées</span>
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
import { useAdmin } from '@/composables/useAdmin'

defineEmits(['go-agences'])

const {
  agences, loading, fetchError,
  pendingCount, approvedCount, rejectedCount, suspendedCount, totalGuides, totalPelerins,
  loadAgences, statusLabel, statusClass,
} = useAdmin()
</script>