import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/services/api'
import { logout } from '@/services/auth.service'

// ── Shared state (singleton) ──────────────────────────────────
export const pelerins  = ref([])
export const guides    = ref([])
export const groupes   = ref([])
export const loading   = ref(true)
export const fetchError = ref('')

export function useAgenceData() {
  const router = useRouter()
  const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

  // ── Auth ────────────────────────────────────────────────────
  async function handleLogout() {
    await logout()
    router.push('/')
  }

  // ── Data loading ────────────────────────────────────────────
  async function loadAll() {
    loading.value = true
    fetchError.value = ''
    try {
      const [rP, rG, rGr] = await Promise.all([
        api.get('/agence/pelerins'),
        api.get('/agence/guides'),
        api.get('/agence/groupes'),
      ])
      pelerins.value = rP.data
      const guidesData = rG.data
      guides.value = Array.isArray(guidesData) ? guidesData : (guidesData.guides ?? [])
      groupes.value = rGr.data
    } catch {
      fetchError.value = 'Impossible de charger les données. Vérifiez que le serveur est démarré.'
    } finally {
      loading.value = false
    }
  }

  // ── Helpers ─────────────────────────────────────────────────
  function getBadge(type) {
    if (type === 'pelerins') return pelerins.value.filter(p => !p.utilisateur?.actif).length
    if (type === 'guides')   return guides.value.filter(g => !g.isActivated).length
    if (type === 'groupes')  return groupes.value.length
    return 0
  }

  function initials(prenom, nom) {
    return ((prenom?.[0] ?? '') + (nom?.[0] ?? '')).toUpperCase() || '?'
  }

  // ── Pèlerins ────────────────────────────────────────────────
  async function createPelerin(form) {
    const { data } = await api.post('/agence/pelerins', form)
    return data
  }

  async function updatePelerin(id, form) {
    const { data } = await api.patch(`/agence/pelerins/${id}`, form)
    return data
  }

  async function deletePelerin(id) {
    await api.delete(`/agence/pelerins/${id}`)
  }

  // ── Guides ──────────────────────────────────────────────────
  async function createGuide(form) {
    const { data } = await api.post('/agence/guides', form)
    return data
  }

  async function updateGuide(id, form) {
    const { data } = await api.patch(`/agence/guides/${id}`, form)
    return data
  }

  async function deleteGuide(id) {
    await api.delete(`/agence/guides/${id}`)
  }

  async function resendActivation(id) {
    const { data } = await api.post(`/agence/guides/${id}/resend-activation`)
    return data
  }

  async function getAvailableGuides() {
    const { data } = await api.get('/agence/guides/available')
    return Array.isArray(data) ? data : (data.guides ?? [])
  }

  async function getGuideStats(id) {
    const { data } = await api.get(`/agence/guides/${id}/stats`)
    return data
  }

  // ── Groupes ─────────────────────────────────────────────────
  async function createGroupe(form) {
    const body = { ...form, guideId: form.guideId || undefined }
    const { data } = await api.post('/agence/groupes', body)
    return data
  }

  async function updateGroupe(id, form) {
    const { data } = await api.patch(`/agence/groupes/${id}`, form)
    return data
  }

  async function deleteGroupe(id) {
    await api.delete(`/agence/groupes/${id}`)
  }

  async function assignerPelerin(groupeId, pelerinId) {
    const { data } = await api.post(`/agence/groupes/${groupeId}/pelerins`, { pelerinId })
    return data
  }

  async function retirerPelerin(groupeId, pelerinId) {
    const { data } = await api.delete(`/agence/groupes/${groupeId}/pelerins/${pelerinId}`)
    return data
  }
   // ── Agence profile ───────────────────────────────────────
  async function getProfile() {
    const { data } = await api.get('/agence/profile')
    return data
  }
 
  async function updateProfile(form) {
    const { data } = await api.patch('/agence/profile', form)
    // update local user name if nomAgence changed
    if (form.nomAgence) user.value.nom = form.nomAgence
    if (form.telephone) user.value.telephone = form.telephone
    return data
  }

  return {
    // state
    user, handleLogout,
    pelerins, guides, groupes, loading, fetchError, loadAll,
    // helpers
    getBadge, initials,
    // pelerins
    createPelerin, updatePelerin, deletePelerin,
    // guides
    createGuide, updateGuide, deleteGuide,
    resendActivation, getAvailableGuides, getGuideStats,
    // groupes
    createGroupe, updateGroupe, deleteGroupe,
    assignerPelerin, retirerPelerin,
    // profile
    getProfile, updateProfile,
  }
}