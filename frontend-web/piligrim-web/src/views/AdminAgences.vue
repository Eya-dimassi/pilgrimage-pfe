<template>
  <div>
    <!-- Filters -->
    <div class="filter-bar">
      <button v-for="f in filters" :key="f.value"
        class="filter-tab" :class="{ active: agenceFilter === f.value }"
        @click="agenceFilter = f.value">
        {{ f.label }}<span class="filter-count">{{ f.count }}</span>
      </button>
    </div>

    <!-- Table -->
    <div class="ad-card">
      <div v-if="loading" class="state-center">
        <svg class="ad-spinner" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" stroke-dasharray="40" stroke-dashoffset="10"/>
        </svg>
      </div>

      <div v-else-if="fetchError" class="state-error">
        <p>{{ fetchError }}</p>
        <button @click="loadAgences" class="btn-retry">Réessayer</button>
      </div>

      <div v-else-if="displayed.length === 0" class="empty-state">
        Aucune agence dans cette catégorie
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
                    <p class="cell-secondary">{{ agence.adresse || '—' }}</p>
                  </div>
                </div>
              </td>
              <td>
                <p class="cell-primary">{{ agence.utilisateur?.email }}</p>
                <p class="cell-secondary">{{ agence.telephone || agence.utilisateur?.telephone || '—' }}</p>
              </td>
              <td>
                <span class="status-badge" :class="statusClass(agence.status)">{{ statusLabel(agence.status) }}</span>
              </td>
              <td class="cell-date">{{ formatDate(agence.createdAt) }}</td>
              <td>
                <div class="cell-stats">
                  <span class="stat-pill stat-pill--purple">{{ agence._count?.pelerins ?? 0 }} pèlerins</span>
                  <span class="stat-pill stat-pill--blue">{{ agence._count?.guides ?? 0 }} guides</span>
                </div>
              </td>
              <td>
                <div class="action-btns">
                  <!-- View detail -->
                  <button @click="openDetail(agence)" class="action-btn action-btn--view" title="Voir détails">
                    <svg width="13" height="13" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </button>
                  <button v-if="agence.status === 'PENDING'" @click="open('approve', agence)" class="action-btn action-btn--green" title="Approuver">
                    <svg width="13" height="13" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
                  </button>
                  <button v-if="agence.status === 'PENDING'" @click="open('reject', agence)" class="action-btn action-btn--red" title="Refuser">
                    <svg width="13" height="13" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>
                  </button>
                  <button v-if="agence.status === 'APPROVED'" @click="open('suspend', agence)" class="action-btn action-btn--gray" title="Suspendre">
                    <svg width="13" height="13" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
                  </button>
                  <button @click="open('delete', agence)" class="action-btn action-btn--delete" title="Supprimer">
                    <svg width="13" height="13" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Approve modal -->
    <div v-if="modal === 'approve'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box">
        <div class="ad-modal-icon ad-modal-icon--green">
          <svg width="22" height="22" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
        </div>
        <h3 class="ad-modal-title">Approuver l'agence</h3>
        <p class="ad-modal-body">Approuver <strong>{{ selected?.nomAgence }}</strong> ? Le compte sera immédiatement activé.</p>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doApprove" :disabled="busy" class="ad-btn ad-btn--green">{{ busy ? 'En cours...' : 'Approuver' }}</button>
        </div>
      </div>
    </div>

    <!-- Reject modal -->
    <div v-if="modal === 'reject'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box">
        <div class="ad-modal-icon ad-modal-icon--red">
          <svg width="22" height="22" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>
        </div>
        <h3 class="ad-modal-title">Refuser l'agence</h3>
        <p class="ad-modal-body">Refuser <strong>{{ selected?.nomAgence }}</strong></p>
        <div class="ad-modal-field">
          <label class="ad-modal-label">Raison du refus <span class="required">*</span></label>
          <textarea v-model="rejectReason" rows="3" class="ad-modal-textarea" placeholder="Expliquez la raison du refus..."></textarea>
        </div>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doReject" :disabled="!rejectReason || rejectReason.length < 10 || busy" class="ad-btn ad-btn--red">{{ busy ? 'En cours...' : 'Refuser' }}</button>
        </div>
      </div>
    </div>

    <!-- Suspend modal -->
    <div v-if="modal === 'suspend'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box">
        <div class="ad-modal-icon ad-modal-icon--orange">
          <svg width="22" height="22" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <h3 class="ad-modal-title">Suspendre l'agence</h3>
        <p class="ad-modal-body">Suspendre <strong>{{ selected?.nomAgence }}</strong> ? L'agence ne pourra plus se connecter.</p>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doSuspend" :disabled="busy" class="ad-btn ad-btn--orange">{{ busy ? 'En cours...' : 'Suspendre' }}</button>
        </div>
      </div>
    </div>

    <!-- Delete modal -->
    <div v-if="modal === 'delete'" class="ad-modal-overlay" @click.self="close">
      <div class="ad-modal-box ad-modal-box--danger">
        <div class="ad-modal-icon ad-modal-icon--red">
          <svg width="22" height="22" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
        </div>
        <h3 class="ad-modal-title">Supprimer définitivement</h3>
        <p class="ad-modal-body">Supprimer <strong>{{ selected?.nomAgence }}</strong> ? Action <strong>irréversible</strong> — tous les guides, pèlerins et groupes seront supprimés.</p>
        <div class="ad-modal-actions">
          <button @click="close" class="ad-btn ad-btn--cancel">Annuler</button>
          <button @click="doDelete" :disabled="busy" class="ad-btn ad-btn--red">{{ busy ? 'Suppression...' : 'Supprimer' }}</button>
        </div>
      </div>
    </div>

    <!-- Detail modal -->
    <AdminAgenceDetail v-if="detailAgence" :agence-id="detailAgence.id" @close="detailAgence = null" />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useAdmin } from '@/composables/useAdmin'
import { useAdminToast } from '@/composables/useAdminToast'
import AdminAgenceDetail from './AdminAgenceDetail.vue'

const props = defineProps({ search: { type: String, default: '' } })

const {
  agences, loading, fetchError,
  pendingCount, approvedCount, rejectedCount, suspendedCount,
  loadAgences, approveAgence, rejectAgence, suspendAgence, deleteAgence,
  statusLabel, statusClass, formatDate,
} = useAdmin()

const { toast } = useAdminToast()

const agenceFilter = ref('ALL')
const modal        = ref(null)   // 'approve' | 'reject' | 'suspend' | 'delete' | null
const selected     = ref(null)
const rejectReason = ref('')
const busy         = ref(false)
const detailAgence = ref(null)

const filters = computed(() => [
  { value: 'ALL',       label: 'Toutes',     count: agences.value.length },
  { value: 'PENDING',   label: 'En attente', count: pendingCount.value },
  { value: 'APPROVED',  label: 'Approuvées', count: approvedCount.value },
  { value: 'REJECTED',  label: 'Refusées',   count: rejectedCount.value },
  { value: 'SUSPENDED', label: 'Suspendues', count: suspendedCount.value },
])

const filtered = computed(() =>
  agenceFilter.value === 'ALL' ? agences.value : agences.value.filter(a => a.status === agenceFilter.value)
)

const displayed = computed(() => {
  const q = props.search.toLowerCase().trim()
  if (!q) return filtered.value
  return filtered.value.filter(a =>
    a.nomAgence?.toLowerCase().includes(q) ||
    a.utilisateur?.email?.toLowerCase().includes(q) ||
    a.adresse?.toLowerCase().includes(q)
  )
})

function open(type, agence) { modal.value = type; selected.value = agence; rejectReason.value = '' }
function close() { modal.value = null; selected.value = null; rejectReason.value = '' }
function openDetail(agence) { detailAgence.value = agence }

async function doApprove() {
  busy.value = true
  try { await approveAgence(selected.value.id); toast('Agence approuvée'); close() }
  catch (e) { toast(e.response?.data?.message || 'Erreur', 'error') }
  finally { busy.value = false }
}

async function doReject() {
  busy.value = true
  try { await rejectAgence(selected.value.id, rejectReason.value); toast('Agence refusée'); close() }
  catch (e) { toast(e.response?.data?.message || 'Erreur', 'error') }
  finally { busy.value = false }
}

async function doSuspend() {
  busy.value = true
  try { await suspendAgence(selected.value.id); toast('Agence suspendue'); close() }
  catch (e) { toast(e.response?.data?.message || 'Erreur', 'error') }
  finally { busy.value = false }
}

async function doDelete() {
  busy.value = true
  try { await deleteAgence(selected.value.id); toast('Agence supprimée'); close() }
  catch (e) { toast(e.response?.data?.message || 'Erreur', 'error') }
  finally { busy.value = false }
}
</script>