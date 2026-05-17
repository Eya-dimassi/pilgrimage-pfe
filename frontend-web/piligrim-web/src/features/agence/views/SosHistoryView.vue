<template>
  <div class="view-section">
    <div class="dashboard-hero">
      <span class="dashboard-hero-kicker">Log</span>
      <h1 class="dashboard-hero-title">Historique SOS</h1>
    </div>

    <div v-if="loading" class="state-center">
      <div class="spinner"></div>
      <p>Chargement de l'historique SOS...</p>
    </div>

    <div v-else-if="error" class="state-center">
      <p class="error-text">{{ error }}</p>
      <button class="btn-primary" @click="loadHistory">Reessayer</button>
    </div>

    <template v-else>
      <div class="stats-grid">
        <article class="stat-card gold">
          <div class="stat-icon-wrap gold-icon">
            <AppIcon name="alert" :size="20" />
          </div>
          <div class="stat-body">
            <span class="stat-value">{{ stats.total }}</span>
          </div>
          <p class="stat-label">Total alertes</p>
        </article>

        <article class="stat-card green">
          <div class="stat-icon-wrap green-icon">
            <AppIcon name="check" :size="20" />
          </div>
          <div class="stat-body">
            <span class="stat-value">{{ stats.resolues }}</span>
          </div>
          <p class="stat-label">Resolues</p>
        </article>

        <article class="stat-card orange">
          <div class="stat-icon-wrap orange-icon">
            <AppIcon name="spinner" :size="20" />
          </div>
          <div class="stat-body">
            <span class="stat-value">{{ stats.enCours }}</span>
          </div>
          <p class="stat-label">En cours</p>
        </article>

        <article class="stat-card blue">
          <div class="stat-icon-wrap blue-icon">
            <AppIcon name="refresh" :size="20" />
          </div>
          <div class="stat-body">
            <span class="stat-value">{{ stats.avgMin !== null ? `${stats.avgMin} min` : '—' }}</span>
          </div>
          <p class="stat-label">Temps moyen de resolution</p>
        </article>
      </div>

      <section class="card sos-toolbar-card">
        <div class="section-topbar sos-toolbar">
          <div class="search-wrap sos-search-wrap">
            <AppIcon class="search-icon" name="search" :size="16" />
            <input
              v-model="searchQuery"
              class="search-input"
              placeholder="Rechercher un pelerin, un guide, un groupe ou un type..."
            />
          </div>

          <select v-model="statusFilter" class="search-input sos-select">
            <option value="">Tous les statuts</option>
            <option value="EN_COURS">En cours</option>
            <option value="RESOLUE">Resolue</option>
            <option value="ANNULEE">Annulee</option>
          </select>

          <select v-model="groupeFilter" class="search-input sos-select">
            <option value="">Tous les groupes</option>
            <option v-for="groupe in groupes" :key="groupe" :value="groupe">{{ groupe }}</option>
          </select>
        </div>
      </section>

      <section class="card">
        <div v-if="!filtered.length" class="empty-state sos-empty-state">
          <AppIcon name="alert" :size="32" style="opacity: 0.45" />
          <p>Aucune alerte SOS ne correspond aux filtres actuels.</p>
        </div>

        <div v-else class="sos-table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>Pelerin</th>
                <th>Groupe</th>
                <th>Details</th>
                <th>Declenchee</th>
                <th>Duree</th>
                <th>Resolue par</th>
                <th>Statut</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="alerte in filtered" :key="alerte.id">
                <td>
                  <div class="cell-user">
                    <div class="cell-avatar" :class="avatarClass(alerte.statut)">
                      {{ initials(alerte.pelerin?.utilisateur) }}
                    </div>
                    <div>
                      <div class="cell-name">{{ fullName(alerte.pelerin?.utilisateur) || 'Pelerin inconnu' }}</div>
                      <div class="cell-sub">{{ formatCoordinates(alerte.latitude, alerte.longitude) }}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="cell-name">{{ alerte.groupe?.nom || 'Sans groupe' }}</div>
                  <div class="cell-sub">{{ voyageLabel(alerte.groupe?.typeVoyage) }}</div>
                </td>
                <td>
                  <div class="sos-detail-cell">
                    <span :class="['type-pill', typePillClass(alerte.type)]">{{ typeLabel(alerte.type) }}</span>
                    <div class="cell-sub sos-detail-copy">
                      {{ alerte.message || alerte.description || 'Aucun message detaille' }}
                    </div>
                  </div>
                </td>
                <td>{{ formatDate(alerte.createdAt) }}</td>
                <td>{{ formatDuration(alerte) }}</td>
                <td>{{ fullName(alerte.resolueParGuide?.utilisateur) || '—' }}</td>
                <td>
                  <span :class="['status-pill', statusClass(alerte.statut)]">{{ statusLabel(alerte.statut) }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import { useSosHistory } from '@/features/agence/composables/useSosHistory'

const {
  loading,
  error,
  filtered,
  stats,
  groupes,
  searchQuery,
  statusFilter,
  groupeFilter,
  loadHistory,
} = useSosHistory()

onMounted(loadHistory)

function fullName(user) {
  if (!user) return ''
  return `${user.prenom ?? ''} ${user.nom ?? ''}`.trim()
}

function initials(user) {
  if (!user) return '?'
  return `${user.prenom?.[0] ?? ''}${user.nom?.[0] ?? ''}`.toUpperCase() || '?'
}

function formatCoordinates(latitude, longitude) {
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return 'Position indisponible'
  return `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`
}

function formatDate(value) {
  if (!value) return '—'

  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value))
}

function formatDuration(alerte) {
  if (alerte.statut !== 'RESOLUE' || !alerte.resolueAt) return '—'

  const minutes = Math.round((new Date(alerte.resolueAt) - new Date(alerte.createdAt)) / 60000)
  return `${minutes} min`
}

function voyageLabel(typeVoyage) {
  if (typeVoyage === 'HAJJ') return 'Hajj'
  if (typeVoyage === 'UMRAH') return 'Omra'
  return 'Voyage'
}

const STATUS_LABELS = {
  EN_COURS: 'En cours',
  RESOLUE: 'Resolue',
  ANNULEE: 'Annulee',
}

const TYPE_LABELS = {
  MALADIE: 'Maladie',
  PERTE: 'Perte',
  LOGISTIQUE: 'Logistique',
  AUTRE: 'Autre',
}

function statusLabel(status) {
  return STATUS_LABELS[status] ?? status ?? 'Inconnu'
}

function statusClass(status) {
  if (status === 'RESOLUE') return 'active'
  if (status === 'EN_COURS') return 'pending'
  return 'suspended'
}

function typeLabel(type) {
  return TYPE_LABELS[type] ?? type ?? 'Autre'
}

function typePillClass(type) {
  if (type === 'MALADIE') return 'sos-type-danger'
  if (type === 'PERTE') return 'sos-type-warning'
  if (type === 'LOGISTIQUE') return 'sos-type-info'
  return 'sos-type-muted'
}

function avatarClass(status) {
  return status === 'RESOLUE' ? 'green-av' : ''
}
</script>
