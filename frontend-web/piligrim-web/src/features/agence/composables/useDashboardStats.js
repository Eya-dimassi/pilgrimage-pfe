import { computed } from 'vue'

export function useDashboardStats({ pelerins, guides, groupes }) {
  const pelerinsWithoutGroupCount = computed(() =>
    pelerins.value.filter((pelerin) => !pelerin.groupeId).length
  )

  const activatedGuidesCount = computed(() =>
    guides.value.filter((guide) => guide.isActivated).length
  )

  const pendingGuidesCount = computed(() =>
    guides.value.filter((guide) => !guide.isActivated).length
  )

  const pendingPelerinsCount = computed(() =>
    pelerins.value.filter((pelerin) => !pelerin.utilisateur?.actif).length
  )

  const pendingActivationsCount = computed(() =>
    pendingPelerinsCount.value + pendingGuidesCount.value
  )

  const actionsNeeded = computed(() => {
    const actions = []
    const groupsWithoutGuideCount = groupes.value.filter((groupe) => !groupe.guide).length

    if (pelerinsWithoutGroupCount.value > 0) {
      actions.push({
        key: 'sg',
        label: `${pelerinsWithoutGroupCount.value} pelerin${pelerinsWithoutGroupCount.value > 1 ? 's' : ''} sans groupe`,
        view: 'pelerins',
      })
    }

    if (pendingGuidesCount.value > 0) {
      actions.push({
        key: 'gna',
        label: `${pendingGuidesCount.value} guide${pendingGuidesCount.value > 1 ? 's' : ''} non active${pendingGuidesCount.value > 1 ? 's' : ''}`,
        view: 'guides',
      })
    }

    if (pendingPelerinsCount.value > 0) {
      actions.push({
        key: 'pna',
        label: `${pendingPelerinsCount.value} pelerin${pendingPelerinsCount.value > 1 ? 's' : ''} en attente`,
        view: 'pelerins',
      })
    }

    if (groupsWithoutGuideCount > 0) {
      actions.push({
        key: 'gsg',
        label: `${groupsWithoutGuideCount} groupe${groupsWithoutGuideCount > 1 ? 's' : ''} sans guide`,
        view: 'groupes',
      })
    }

    return actions
  })

  return {
    pelerinsWithoutGroupCount,
    activatedGuidesCount,
    pendingGuidesCount,
    pendingPelerinsCount,
    pendingActivationsCount,
    actionsNeeded,
  }
}
