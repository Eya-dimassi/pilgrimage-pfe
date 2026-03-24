import { computed, ref } from 'vue'
import {
  approveAdminAgence,
  fetchAdminAgenceById,
  fetchAdminAgences,
  rejectAdminAgence,
  removeAdminAgence,
  suspendAdminAgence,
} from '@/features/admin/services/admin.service'

const agences = ref([])
const loading = ref(false)
const fetchError = ref('')
const isDark = ref(localStorage.getItem('admin-dark') === 'true')

function applyDark(val) {
  isDark.value = val
  localStorage.setItem('admin-dark', val)
  document.documentElement.classList.toggle('admin-dark', val)
}

function toggleDark() {
  applyDark(!isDark.value)
}

const pendingCount = computed(() => agences.value.filter((agence) => agence.status === 'PENDING').length)
const approvedCount = computed(() => agences.value.filter((agence) => agence.status === 'APPROVED').length)
const rejectedCount = computed(() => agences.value.filter((agence) => agence.status === 'REJECTED').length)
const suspendedCount = computed(() => agences.value.filter((agence) => agence.status === 'SUSPENDED').length)
const totalPelerins = computed(() => agences.value.reduce((sum, agence) => sum + (agence._count?.pelerins ?? 0), 0))
const totalGuides = computed(() => agences.value.reduce((sum, agence) => sum + (agence._count?.guides ?? 0), 0))

async function loadAgences() {
  loading.value = true
  fetchError.value = ''

  try {
    agences.value = await fetchAdminAgences()
  } catch {
    fetchError.value = 'Impossible de charger les agences.'
  } finally {
    loading.value = false
  }
}

async function getAgenceById(id) {
  return fetchAdminAgenceById(id)
}

async function approveAgence(id) {
  await approveAdminAgence(id)
  const agence = agences.value.find((item) => item.id === id)
  if (agence) agence.status = 'APPROVED'
}

async function rejectAgence(id, reason) {
  await rejectAdminAgence(id, reason)
  const agence = agences.value.find((item) => item.id === id)
  if (agence) agence.status = 'REJECTED'
}

async function suspendAgence(id) {
  await suspendAdminAgence(id)
  const agence = agences.value.find((item) => item.id === id)
  if (agence) agence.status = 'SUSPENDED'
}

async function deleteAgence(id) {
  await removeAdminAgence(id)
  agences.value = agences.value.filter((item) => item.id !== id)
}

function statusLabel(status) {
  return {
    PENDING: 'En attente',
    APPROVED: 'Approuvee',
    REJECTED: 'Refusee',
    SUSPENDED: 'Suspendue',
  }[status] ?? status
}

function statusClass(status) {
  return {
    PENDING: 'badge--orange',
    APPROVED: 'badge--green',
    REJECTED: 'badge--red',
    SUSPENDED: 'badge--gray',
  }[status] ?? 'badge--gray'
}

function formatDate(iso) {
  if (!iso) return '-'
  return new Date(iso).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

export function useAdmin() {
  return {
    agences,
    loading,
    fetchError,
    isDark,
    pendingCount,
    approvedCount,
    rejectedCount,
    suspendedCount,
    totalPelerins,
    totalGuides,
    toggleDark,
    applyDark,
    loadAgences,
    getAgenceById,
    approveAgence,
    rejectAgence,
    suspendAgence,
    deleteAgence,
    statusLabel,
    statusClass,
    formatDate,
  }
}
