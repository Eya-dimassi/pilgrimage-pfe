import { ref, computed } from 'vue'
import api from '@/services/api'

// ── Shared state (singleton across components) ─────────────────────────────
const agences      = ref([])
const loading      = ref(false)
const fetchError   = ref('')
const isDark       = ref(localStorage.getItem('admin-dark') === 'true')

// ── Dark mode ──────────────────────────────────────────────────────────────
function applyDark(val) {
  isDark.value = val
  localStorage.setItem('admin-dark', val)
  document.documentElement.classList.toggle('admin-dark', val)
}

function toggleDark() { applyDark(!isDark.value) }

// ── Computed counts ────────────────────────────────────────────────────────
const pendingCount   = computed(() => agences.value.filter(a => a.status === 'PENDING').length)
const approvedCount  = computed(() => agences.value.filter(a => a.status === 'APPROVED').length)
const rejectedCount  = computed(() => agences.value.filter(a => a.status === 'REJECTED').length)
const suspendedCount = computed(() => agences.value.filter(a => a.status === 'SUSPENDED').length)
const totalPelerins  = computed(() => agences.value.reduce((s, a) => s + (a._count?.pelerins ?? 0), 0))
const totalGuides    = computed(() => agences.value.reduce((s, a) => s + (a._count?.guides ?? 0), 0))

// ── API calls ──────────────────────────────────────────────────────────────
async function loadAgences() {
  loading.value = true
  fetchError.value = ''
  try {
    const res = await api.get('/admin/agences')
    agences.value = res.data
  } catch {
    fetchError.value = 'Impossible de charger les agences.'
  } finally {
    loading.value = false
  }
}

async function getAgenceById(id) {
  const res = await api.get(`/admin/agences/${id}`)
  return res.data
}

async function approveAgence(id) {
  await api.patch(`/admin/agences/${id}/approve`)
  const a = agences.value.find(x => x.id === id)
  if (a) a.status = 'APPROVED'
}

async function rejectAgence(id, reason) {
  await api.patch(`/admin/agences/${id}/reject`, { reason })
  const a = agences.value.find(x => x.id === id)
  if (a) a.status = 'REJECTED'
}

async function suspendAgence(id) {
  await api.patch(`/admin/agences/${id}/suspend`)
  const a = agences.value.find(x => x.id === id)
  if (a) a.status = 'SUSPENDED'
}

async function deleteAgence(id) {
  await api.delete(`/admin/agences/${id}`)
  agences.value = agences.value.filter(x => x.id !== id)
}

// ── Helpers ────────────────────────────────────────────────────────────────
function statusLabel(s) {
  return { PENDING: 'En attente', APPROVED: 'Approuvée', REJECTED: 'Refusée', SUSPENDED: 'Suspendue' }[s] ?? s
}

function statusClass(s) {
  return { PENDING: 'badge--orange', APPROVED: 'badge--green', REJECTED: 'badge--red', SUSPENDED: 'badge--gray' }[s] ?? 'badge--gray'
}

function formatDate(iso) {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}

export function useAdmin() {
  return {
    // state
    agences, loading, fetchError, isDark,
    // counts
    pendingCount, approvedCount, rejectedCount, suspendedCount, totalPelerins, totalGuides,
    // dark mode
    toggleDark, applyDark,
    // api
    loadAgences, getAgenceById, approveAgence, rejectAgence, suspendAgence, deleteAgence,
    // helpers
    statusLabel, statusClass, formatDate,
  }
}