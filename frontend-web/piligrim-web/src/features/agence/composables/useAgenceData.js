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
  fetchAgenceDashboardData,
  fetchAgenceGuideStats,
  fetchAgenceProfile,
  fetchAvailableAgenceGuides,
  removeAgencePelerin,
  resendAgenceGuideActivation,
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
      pelerins.value = pelerinsData
      guides.value = Array.isArray(guidesData) ? guidesData : (guidesData.guides ?? [])
      groupes.value = groupesData
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
    await deleteAgenceGroupe(id)
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
