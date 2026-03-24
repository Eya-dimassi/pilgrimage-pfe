export function useGuideStatus() {
  function guideStatusClass(guide) {
    if (!guide.isActivated) return 'pending'
    if (!guide.utilisateur?.actif) return 'suspended'
    return 'active'
  }

  function guideStatusLabel(guide) {
    if (!guide.isActivated) return 'En attente'
    if (!guide.utilisateur?.actif) return 'Suspendu'
    return 'Actif'
  }

  return {
    guideStatusClass,
    guideStatusLabel,
  }
}
