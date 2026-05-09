export function useGuideStatus() {
  function guideStatusClass(guide) {
    if (!guide.isActivated) return 'pending'
    if (!guide.utilisateur?.actif) return 'suspended'
    if (guide.disponibilite === 'INDISPONIBLE') return 'suspended'
    return 'active'
  }

  function guideStatusLabel(guide) {
    if (!guide.isActivated) return 'En attente'
    if (!guide.utilisateur?.actif) return 'Suspendu'
    if (guide.disponibilite === 'INDISPONIBLE') return 'Indisponible'
    return 'Disponible'
  }

  return {
    guideStatusClass,
    guideStatusLabel,
  }
}
