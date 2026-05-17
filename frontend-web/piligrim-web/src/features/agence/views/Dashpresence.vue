<template>
  <div class="view-section">
    <div class="dashboard-hero">
      <p class="dashboard-hero-kicker">Suivi presence</p>
      <h1 class="dashboard-hero-title">Historique des appels</h1>
    </div>

    <div class="stats-grid">
      <DashboardStatCard tone="gold" icon-name="calendar" :value="stats.totalAppels" label="Total appels">
        Appels de presence enregistres
      </DashboardStatCard>

      <DashboardStatCard tone="blue" icon-name="alert" :value="stats.appelsEnCours" label="En cours">
        Appels encore ouverts
      </DashboardStatCard>

      <DashboardStatCard tone="green" icon-name="user-check" :value="stats.appelsClotures" label="Clotures">
        Appels termines
      </DashboardStatCard>

      <DashboardStatCard tone="orange" icon-name="users" :value="`${stats.tauxPresenceGlobal}%`" label="Taux presence">
        Moyenne globale de presence
      </DashboardStatCard>
    </div>

    <div class="card">
      <div class="presence-filters-grid">
        <div class="form-field">
          <label>Groupe</label>
          <select v-model="filters.groupeId">
            <option value="">Tous les groupes</option>
            <option v-for="groupe in filterOptions.groupes" :key="groupe.id" :value="groupe.id">
              {{ groupe.nom }}
            </option>
          </select>
        </div>

        <div class="form-field">
          <label>Guide</label>
          <select v-model="filters.guideId">
            <option value="">Tous les guides</option>
            <option v-for="guide in filterOptions.guides" :key="guide.id" :value="guide.id">
              {{ guide.fullName }}
            </option>
          </select>
        </div>

        <div class="form-field">
          <label>Statut</label>
          <select v-model="filters.statut">
            <option value="">Tous</option>
            <option value="EN_COURS">En cours</option>
            <option value="CLOTURE">Cloture</option>
          </select>
        </div>
      </div>

      <div class="presence-filter-actions">
        <button class="btn-primary" :disabled="loading" @click="loadHistory">
          {{ loading ? 'Chargement...' : 'Filtrer' }}
        </button>
        <button class="btn-secondary" :disabled="loading" @click="resetFilters">Reinitialiser</button>
      </div>
    </div>

    <div class="card">
      <div v-if="error" class="error-text">{{ error }}</div>

      <table v-else class="data-table">
        <thead>
          <tr>
            <th>Heure appel</th>
            <th>Groupe</th>
            <th>Guide</th>
            <th>Statut</th>
            <th>Liste pelerins</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="5" class="empty-row">Chargement...</td>
          </tr>

          <tr v-else-if="rows.length === 0">
            <td colspan="5" class="empty-row">Aucun appel trouve</td>
          </tr>

          <tr v-for="row in rows" :key="row.id">
            <td>{{ formatASTDateTime(row.date) }}</td>
            <td>
              <span class="group-tag">{{ row.groupe.nom }}</span>
            </td>
            <td>{{ row.guide.fullName }}</td>
            <td>
              <span class="status-pill" :class="presenceCallStatusClass(row.statut)">
                {{ presenceCallStatusLabel(row.statut) }}
              </span>
            </td>
            <td>
              <button
                class="presence-toggle-btn"
                type="button"
                @click="togglePelerinsList(row.id)"
              >
                {{ isPelerinsListOpen(row.id) ? 'Masquer liste' : `Voir liste (${row.pelerins.length})` }}
              </button>

              <transition name="expand">
                <div v-if="isPelerinsListOpen(row.id)" class="presence-pelerins-list">
                  <div
                    v-for="pelerin in row.pelerins"
                    :key="pelerin.id"
                    class="presence-pelerin-item"
                  >
                    <span class="presence-pelerin-name">{{ pelerin.fullName }}</span>
                    <span class="status-pill" :class="presencePelerinStatusClass(pelerin.statut)">
                      {{ presencePelerinStatusLabel(pelerin.statut) }}
                    </span>
                  </div>
                </div>
              </transition>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import DashboardStatCard from '@/features/agence/components/dashboard/DashboardStatCard.vue'
import { fetchAgencePresenceHistory } from '@/features/agence/services/agence.service'
import { formatASTDateTime } from '@/features/agence/utils/astDate'

const loading = ref(false)
const error = ref('')
const rows = ref([])
const stats = ref({
  totalAppels: 0,
  appelsEnCours: 0,
  appelsClotures: 0,
  tauxPresenceGlobal: 0,
})
const filterOptions = ref({
  groupes: [],
  guides: [],
})
const openPelerinsLists = ref({})

const filters = ref({
  groupeId: '',
  guideId: '',
  statut: '',
})

function presenceCallStatusClass(statut) {
  if (statut === 'EN_COURS') return 'pending'
  return 'active'
}

function presenceCallStatusLabel(statut) {
  if (statut === 'EN_COURS') return 'En cours'
  if (statut === 'CLOTURE') return 'Cloture'
  return statut
}

function presencePelerinStatusClass(statut) {
  if (statut === 'PRESENT') return 'active'
  if (statut === 'ABSENT') return 'suspended'
  return 'pending'
}

function presencePelerinStatusLabel(statut) {
  if (statut === 'PRESENT') return 'Present'
  if (statut === 'ABSENT') return 'Absent'
  if (statut === 'EXCUSE') return 'Excuse'
  return 'En attente'
}

function isPelerinsListOpen(appelId) {
  return Boolean(openPelerinsLists.value[appelId])
}

function togglePelerinsList(appelId) {
  openPelerinsLists.value = {
    ...openPelerinsLists.value,
    [appelId]: !openPelerinsLists.value[appelId],
  }
}

async function loadHistory() {
  loading.value = true
  error.value = ''

  try {
    const params = {
      ...(filters.value.groupeId ? { groupeId: filters.value.groupeId } : {}),
      ...(filters.value.guideId ? { guideId: filters.value.guideId } : {}),
      ...(filters.value.statut ? { statut: filters.value.statut } : {}),
    }

    const data = await fetchAgencePresenceHistory(params)
    rows.value = Array.isArray(data?.rows) ? data.rows : []
    openPelerinsLists.value = {}
    stats.value = data?.stats ?? stats.value
    filterOptions.value = {
      groupes: Array.isArray(data?.filters?.groupes) ? data.filters.groupes : [],
      guides: Array.isArray(data?.filters?.guides) ? data.filters.guides : [],
    }
  } catch (err) {
    error.value = err.response?.data?.message || err.message || "Erreur lors du chargement de l'historique"
  } finally {
    loading.value = false
  }
}

function resetFilters() {
  filters.value = {
    groupeId: '',
    guideId: '',
    statut: '',
  }
  openPelerinsLists.value = {}
  loadHistory()
}

onMounted(() => {
  loadHistory()
})
</script>
