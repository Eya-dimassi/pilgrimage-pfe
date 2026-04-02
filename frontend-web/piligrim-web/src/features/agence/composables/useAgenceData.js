import { ref } from 'vue'
import { useRouter } from 'vue-router'
import {
  assignAgencePelerin,
  createAgenceGuide,
  createAgenceGroupe,
  createAgencePelerin,
  deleteAgenceGuide,
  deleteAgenceGroupe,
  deleteAgencePelerin,
  fetchAgencePelerin,
  fetchAgenceDashboardData,
  fetchAgenceGuideStats,
  fetchAgenceProfile,
  fetchAvailableAgenceGuides,
  removeAgencePelerin,
  resendAgenceGuideActivation,
  resendAgencePelerinActivation,
  updateAgenceGuide,
  updateAgenceGroupe,
  updateAgencePelerin,
  updateAgenceProfile as saveAgenceProfile,
} from '@/features/agence/services/agence.service'
import { getInitials } from '@/features/agence/utils/initials'
import { logout } from '@/services/auth.service'

export const pelerins = ref([])
export const guides = ref([])
export const groupes = ref([])
export const loading = ref(true)
export const fetchError = ref('')

function normalizeGroupe(raw) {
  const guidesList = Array.isArray(raw?.guides)
    ? raw.guides.map((rel) => rel?.guide ?? rel).filter((g) => g?.id)
    : []
  const activeGuide = raw?.guide ?? guidesList[0] ?? null
  const pelerinsList = raw?.pelerins ?? raw?.membres?.map((m) => m?.pelerin).filter(Boolean) ?? []

  return {
    ...raw,
    guides: guidesList,
    guideIds: guidesList.map((g) => g.id),
    guide: activeGuide,
    guideId: raw?.guideId ?? activeGuide?.id ?? null,
    pelerins: pelerinsList,
    _count: {
      ...(raw?._count ?? {}),
      pelerins: raw?._count?.pelerins ?? raw?._count?.membres ?? pelerinsList.length,
    },
  }
}

function normalizePelerin(raw) {
  const membership = raw?.groupe ?? raw?.groupes?.[0]?.groupe ?? null
  const groupeId = raw?.groupeId ?? raw?.groupes?.[0]?.groupeId ?? membership?.id ?? null

  return {
    ...raw,
    groupeId,
    groupe: membership,
  }
}

export function useAgenceData() {
  const router = useRouter()
  const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

  async function handleLogout() {
    await logout()
    router.push('/')
  }

  async function loadAll() {
    loading.value = true
    fetchError.value = ''

    try {
      const { pelerins: pelerinsData, guides: guidesData, groupes: groupesData } = await fetchAgenceDashboardData()
      pelerins.value = (Array.isArray(pelerinsData) ? pelerinsData : []).map(normalizePelerin)
      guides.value = Array.isArray(guidesData) ? guidesData : (guidesData.guides ?? [])
      groupes.value = (Array.isArray(groupesData) ? groupesData : []).map(normalizeGroupe)
    } catch {
      fetchError.value = 'Impossible de charger les donnees. Verifiez que le serveur est demarre.'
    } finally {
      loading.value = false
    }
  }

  function getBadge(type) {
    if (type === 'pelerins') return pelerins.value.filter((pelerin) => !pelerin.utilisateur?.actif).length
    if (type === 'guides') return guides.value.filter((guide) => !guide.isActivated).length
    if (type === 'groupes') return groupes.value.length
    return 0
  }

  function initials(prenom, nom) {
    return getInitials(prenom, nom)
  }

  async function createPelerin(form) {
    return createAgencePelerin(form)
  }

  async function updatePelerin(id, form) {
    return updateAgencePelerin(id, form)
  }

  async function deletePelerin(id) {
    await deleteAgencePelerin(id)
  }

  async function createGuide(form) {
    return createAgenceGuide(form)
  }

  async function updateGuide(id, form) {
    return updateAgenceGuide(id, form)
  }

  async function deleteGuide(id) {
    await deleteAgenceGuide(id)
  }

  async function resendActivation(id) {
    return resendAgenceGuideActivation(id)
  }

  async function resendPelerinActivation(id) {
    return resendAgencePelerinActivation(id)
  }

  async function getPelerinDetails(id) {
    return fetchAgencePelerin(id)
  }

  async function getAvailableGuides() {
    return fetchAvailableAgenceGuides()
  }

  async function getGuideStats(id) {
    return fetchAgenceGuideStats(id)
  }

  async function createGroupe(form) {
    return createAgenceGroupe(form)
  }

  async function updateGroupe(id, form) {
    return updateAgenceGroupe(id, form)
  }

  async function deleteGroupe(id) {
    return deleteAgenceGroupe(id)
  }

  async function assignerPelerin(groupeId, pelerinId) {
    return assignAgencePelerin(groupeId, pelerinId)
  }

  async function retirerPelerin(groupeId, pelerinId) {
    return removeAgencePelerin(groupeId, pelerinId)
  }

  async function getProfile() {
    return fetchAgenceProfile()
  }

  async function updateProfile(form) {
    const data = await saveAgenceProfile(form)
    if (form.nomAgence) user.value.nom = form.nomAgence
    if (form.telephone) user.value.telephone = form.telephone
    return data
  }

  return {
    user,
    handleLogout,
    pelerins,
    guides,
    groupes,
    loading,
    fetchError,
    loadAll,
    getBadge,
    initials,
    createPelerin,
    updatePelerin,
    deletePelerin,
    createGuide,
    updateGuide,
    deleteGuide,
    resendActivation,
    resendPelerinActivation,
    getPelerinDetails,
    getAvailableGuides,
    getGuideStats,
    createGroupe,
    updateGroupe,
    deleteGroupe,
    assignerPelerin,
    retirerPelerin,
    getProfile,
    updateProfile,
  }
}
