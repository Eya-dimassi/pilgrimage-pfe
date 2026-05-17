import { computed, ref } from 'vue'
import { fetchSosHistory } from '@/features/agence/services/sos.service'

export function useSosHistory() {
  const loading = ref(false)
  const error = ref('')
  const alertes = ref([])

  const searchQuery = ref('')
  const statusFilter = ref('')
  const groupeFilter = ref('')

  async function loadHistory() {
    loading.value = true
    error.value = ''

    try {
      alertes.value = await fetchSosHistory()
    } catch (err) {
      error.value = err.response?.data?.message || err.message || "Impossible de charger l'historique SOS."
    } finally {
      loading.value = false
    }
  }

  const filtered = computed(() => {
    const query = searchQuery.value.trim().toLowerCase()

    return alertes.value.filter((alerte) => {
      const pelerinName = `${alerte.pelerin?.utilisateur?.prenom ?? ''} ${alerte.pelerin?.utilisateur?.nom ?? ''}`
        .trim()
        .toLowerCase()
      const guideName = `${alerte.resolueParGuide?.utilisateur?.prenom ?? ''} ${alerte.resolueParGuide?.utilisateur?.nom ?? ''}`
        .trim()
        .toLowerCase()
      const groupeNom = String(alerte.groupe?.nom ?? '').toLowerCase()
      const type = String(alerte.type ?? '').toLowerCase()

      const matchQuery = !query
        || pelerinName.includes(query)
        || guideName.includes(query)
        || groupeNom.includes(query)
        || type.includes(query)
      const matchStatus = !statusFilter.value || alerte.statut === statusFilter.value
      const matchGroupe = !groupeFilter.value || alerte.groupe?.nom === groupeFilter.value

      return matchQuery && matchStatus && matchGroupe
    })
  })

  const stats = computed(() => {
    const total = alertes.value.length
    const resolues = alertes.value.filter((alerte) => alerte.statut === 'RESOLUE').length
    const enCours = alertes.value.filter((alerte) => alerte.statut === 'EN_COURS').length
    const durations = alertes.value
      .filter((alerte) => alerte.statut === 'RESOLUE' && alerte.resolueAt && alerte.createdAt)
      .map((alerte) => (new Date(alerte.resolueAt) - new Date(alerte.createdAt)) / 60000)

    const avgMin = durations.length
      ? Math.round(durations.reduce((sum, duration) => sum + duration, 0) / durations.length)
      : null

    return { total, resolues, enCours, avgMin }
  })

  const groupes = computed(() =>
    [...new Set(alertes.value.map((alerte) => alerte.groupe?.nom).filter(Boolean))]
  )

  return {
    loading,
    error,
    alertes,
    filtered,
    stats,
    groupes,
    searchQuery,
    statusFilter,
    groupeFilter,
    loadHistory,
  }
}
