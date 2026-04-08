<template>
  <div>
    <div class="filter-bar">
      <button
        v-for="filter in filters"
        :key="filter.value"
        class="filter-tab"
        :class="{ active: agenceFilter === filter.value }"
        @click="agenceFilter = filter.value"
      >
        {{ filter.label }}<span class="filter-count">{{ filter.count }}</span>
      </button>
    </div>

    <div class="ad-card ad-card--table-shell">
      <div v-if="loading" class="state-center">
        <AppIcon class="ad-spinner" name="spinner" :size="24" :stroke-width="3" spin />
      </div>

      <div v-else-if="fetchError" class="state-error">
        <p>{{ fetchError }}</p>
        <button @click="loadAgences" class="btn-retry">Reessayer</button>
      </div>

      <div v-else-if="displayed.length === 0" class="empty-state">
        Aucune agence dans cette categorie
      </div>

      <div v-else class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>AGENCE</th>
              <th>CONTACT</th>
              <th>STATUT</th>
              <th>INSCRIT LE</th>
              <th>STATS</th>
              <th>ACTIONS</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="agence in displayed" :key="agence.id">
              <td>
                <div class="cell-agency">
                  <div class="agency-avatar">{{ agence.nomAgence?.[0]?.toUpperCase() }}</div>
                  <div>
                    <p class="cell-primary">{{ agence.nomAgence }}</p>
                    <p class="cell-secondary">{{ agence.adresse || '-' }}</p>
                  </div>
                </div>
              </td>
              <td>
                <p class="cell-primary">{{ agence.utilisateur?.email }}</p>
                <p class="cell-secondary">{{ agence.telephone || agence.utilisateur?.telephone || '-' }}</p>
              </td>
              <td>
                <span class="status-badge" :class="statusClass(agence.status)">{{ statusLabel(agence.status) }}</span>
              </td>
              <td class="cell-date">{{ formatDate(agence.createdAt) }}</td>
              <td>
                <div class="cell-stats">
                  <span class="stat-pill stat-pill--purple">{{ agence._count?.pelerins ?? 0 }} pelerins</span>
                  <span class="stat-pill stat-pill--blue">{{ agence._count?.guides ?? 0 }} guides</span>
                </div>
              </td>
              <td>
                <div class="action-btns">
                  <button @click="openDetail(agence)" class="action-btn action-btn--view" title="Voir details">
                    <AppIcon name="eye" :size="13" :stroke-width="2" />
                  </button>
                  <button
                    v-if="agence.status === 'PENDING'"
                    @click="open('approve', agence)"
                    class="action-btn action-btn--green"
                    title="Approuver"
                  >
                    <AppIcon name="check" :size="13" :stroke-width="2.5" />
                  </button>
                  <button
                    v-if="agence.status === 'PENDING'"
                    @click="open('reject', agence)"
                    class="action-btn action-btn--red"
                    title="Refuser"
                  >
                    <AppIcon name="x" :size="13" :stroke-width="2.5" />
                  </button>
                  <button
                    v-if="agence.status === 'APPROVED'"
                    @click="open('suspend', agence)"
                    class="action-btn action-btn--gray"
                    title="Suspendre"
                  >
                    <AppIcon name="alert" :size="13" :stroke-width="2" />
                  </button>
                  <button @click="open('delete', agence)" class="action-btn action-btn--delete" title="Supprimer">
                    <AppIcon name="trash" :size="13" :stroke-width="2" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="modal === 'approve'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box">
        <div class="ad-modal-icon ad-modal-icon--green">
          <AppIcon name="check" :size="22" :stroke-width="2.5" />
        </div>
        <h3 class="ad-modal-title">Approuver l'agence</h3>
        <p class="ad-modal-body">
          Approuver <strong>{{ selected?.nomAgence }}</strong> ? Le compte sera immediatement active.
        </p>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doApprove" :disabled="busy" class="ad-btn ad-btn--green">
            {{ busy ? 'En cours...' : 'Approuver' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'reject'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box">
        <div class="ad-modal-icon ad-modal-icon--red">
          <AppIcon name="x" :size="22" :stroke-width="2.5" />
        </div>
        <h3 class="ad-modal-title">Refuser l'agence</h3>
        <p class="ad-modal-body">Refuser <strong>{{ selected?.nomAgence }}</strong></p>
        <div class="ad-modal-field">
          <label class="ad-modal-label">Raison du refus <span class="required">*</span></label>
          <textarea
            v-model="rejectReason"
            rows="3"
            class="ad-modal-textarea"
            placeholder="Expliquez la raison du refus..."
          ></textarea>
        </div>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doReject" :disabled="!rejectReason || rejectReason.length < 10 || busy" class="ad-btn ad-btn--red">
            {{ busy ? 'En cours...' : 'Refuser' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'suspend'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box">
        <div class="ad-modal-icon ad-modal-icon--orange">
          <AppIcon name="alert" :size="22" :stroke-width="2" />
        </div>
        <h3 class="ad-modal-title">Suspendre l'agence</h3>
        <p class="ad-modal-body">
          Suspendre <strong>{{ selected?.nomAgence }}</strong> ? L'agence ne pourra plus se connecter.
        </p>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doSuspend" :disabled="busy" class="ad-btn ad-btn--orange">
            {{ busy ? 'En cours...' : 'Suspendre' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="modal === 'delete'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box ad-modal-box--danger">
        <div class="ad-modal-icon ad-modal-icon--red">
          <AppIcon name="trash" :size="22" :stroke-width="2" />
        </div>
        <h3 class="ad-modal-title">Supprimer definitivement</h3>
        <p class="ad-modal-body">
          Supprimer <strong>{{ selected?.nomAgence }}</strong> ? Action <strong>irreversible</strong> -
          tous les guides, pelerins et groupes seront supprimes.
        </p>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doDelete" :disabled="busy" class="ad-btn ad-btn--red">
            {{ busy ? 'Suppression...' : 'Supprimer' }}
          </button>
        </div>
      </div>
    </div>

    <AdminAgenceDetail v-if="detailAgence" :agence-id="detailAgence.id" @close="detailAgence = null" />
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { useAdmin } from '@/features/admin/composables/useAdmin'
import { useAdminToast } from '@/features/admin/composables/useAdminToast'
import AppIcon from '@/components/AppIcon.vue'
import AdminAgenceDetail from './AdminAgenceDetail.vue'

const props = defineProps({
  search: { type: String, default: '' },
})

const {
  agences,
  loading,
  fetchError,
  pendingCount,
  approvedCount,
  rejectedCount,
  suspendedCount,
  loadAgences,
  approveAgence,
  rejectAgence,
  suspendAgence,
  deleteAgence,
  statusLabel,
  statusClass,
  formatDate,
} = useAdmin()

const { toast } = useAdminToast()

const agenceFilter = ref('ALL')
const modal = ref(null)
const selected = ref(null)
const rejectReason = ref('')
const busy = ref(false)
const detailAgence = ref(null)

const filters = computed(() => [
  { value: 'ALL', label: 'Toutes', count: agences.value.length },
  { value: 'PENDING', label: 'En attente', count: pendingCount.value },
  { value: 'APPROVED', label: 'Approuvees', count: approvedCount.value },
  { value: 'REJECTED', label: 'Refusees', count: rejectedCount.value },
  { value: 'SUSPENDED', label: 'Suspendues', count: suspendedCount.value },
])

const filtered = computed(() =>
  agenceFilter.value === 'ALL' ? agences.value : agences.value.filter((a) => a.status === agenceFilter.value)
)

const displayed = computed(() => {
  const query = props.search.toLowerCase().trim()
  if (!query) return filtered.value

  return filtered.value.filter(
    (a) =>
      a.nomAgence?.toLowerCase().includes(query) ||
      a.utilisateur?.email?.toLowerCase().includes(query) ||
      a.adresse?.toLowerCase().includes(query)
  )
})

function open(type, agence) {
  modal.value = type
  selected.value = agence
  rejectReason.value = ''
}

function close() {
  modal.value = null
  selected.value = null
  rejectReason.value = ''
}

function openDetail(agence) {
  detailAgence.value = agence
}

async function doApprove() {
  busy.value = true
  try {
    await approveAgence(selected.value.id)
    toast('Agence approuvee')
    close()
  } catch (e) {
    toast(e.response?.data?.message || 'Erreur', 'error')
  } finally {
    busy.value = false
  }
}

async function doReject() {
  busy.value = true
  try {
    await rejectAgence(selected.value.id, rejectReason.value)
    toast('Agence refusee')
    close()
  } catch (e) {
    toast(e.response?.data?.message || 'Erreur', 'error')
  } finally {
    busy.value = false
  }
}

async function doSuspend() {
  busy.value = true
  try {
    await suspendAgence(selected.value.id)
    toast('Agence suspendue')
    close()
  } catch (e) {
    toast(e.response?.data?.message || 'Erreur', 'error')
  } finally {
    busy.value = false
  }
}

async function doDelete() {
  busy.value = true
  try {
    await deleteAgence(selected.value.id)
    toast('Agence supprimee')
    close()
  } catch (e) {
    toast(e.response?.data?.message || 'Erreur', 'error')
  } finally {
    busy.value = false
  }
}
</script>
