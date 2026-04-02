import { ref } from 'vue'
import { groupes, guides, pelerins, useAgenceData } from './useAgenceData'

const TOAST_DURATION_MS = 8500

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

export function useModal() {
  const {
    loadAll,
    createPelerin,
    updatePelerin,
    deletePelerin,
    createGuide,
    updateGuide,
    deleteGuide,
    resendActivation,
    resendPelerinActivation,
    createGroupe,
    updateGroupe,
    deleteGroupe,
    assignerPelerin,
    retirerPelerin,
  } = useAgenceData()

  const modal = ref(null)
  const modalError = ref('')
  const actionLoading = ref(false)
  const bulkAssignLoading = ref(false)
  const resendingId = ref(null)
  const resendingPelerinId = ref(null)
  const form = ref({})
  const editType = ref('')
  const editTarget = ref(null)
  const deleteTarget = ref(null)
  const deleteType = ref('')
  const selectedGroupe = ref(null)
  const toast = ref({ show: false, message: '', type: 'success' })

  function showToast(message, type = 'success') {
    toast.value = { show: true, message, type }
    window.setTimeout(() => {
      toast.value.show = false
    }, TOAST_DURATION_MS)
  }

  function resetModalError() {
    modalError.value = ''
  }

  function closeModal() {
    modal.value = null
    resetModalError()
  }

  function dateToInput(value) {
    if (!value) return ''
    const date = value instanceof Date ? value : new Date(value)
    if (Number.isNaN(date.getTime())) return ''
    return date.toISOString().slice(0, 10)
  }

  function openModal(type) {
    form.value = { typeVoyage: 'HAJJ', annee: new Date().getFullYear() }

    if (type === 'createGroupe') {
      form.value = {
        ...form.value,
        nom: '',
        description: '',
        guideIds: [],
        status: 'PLANIFIE',
        dateDepart: '',
        dateRetour: '',
      }
    }

    resetModalError()
    modal.value = type
  }

  function openEdit(type, target) {
    editType.value = type
    editTarget.value = target
    resetModalError()

    if (type === 'pelerin') {
      form.value = {
        prenom: target.utilisateur?.prenom,
        nom: target.utilisateur?.nom,
        telephone: target.utilisateur?.telephone,
        nationalite: target.nationalite,
        numeroPasseport: target.numeroPasseport,
      }
    } else if (type === 'guide') {
      form.value = {
        prenom: target.utilisateur?.prenom,
        nom: target.utilisateur?.nom,
        telephone: target.utilisateur?.telephone,
        specialite: target.specialite,
      }
    } else if (type === 'groupe') {
      const guideIds = Array.isArray(target.guideIds)
        ? target.guideIds.filter(Boolean)
        : Array.isArray(target.guides)
          ? target.guides.map((g) => g.id).filter(Boolean)
          : target.guideId
            ? [target.guideId]
            : []
      form.value = {
        nom: target.nom,
        annee: target.annee,
        typeVoyage: target.typeVoyage,
        description: target.description,
        guideIds,
        status: target.status ?? 'PLANIFIE',
        dateDepart: dateToInput(target.dateDepart),
        dateRetour: dateToInput(target.dateRetour),
      }
    }

    modal.value = 'edit'
  }

  function openAssign(groupe) {
    selectedGroupe.value = groupe
    form.value = { pelerinIds: [] }
    resetModalError()
    modal.value = 'assign'
  }

  function confirmDelete(type, target) {
    deleteType.value = type
    deleteTarget.value = target
    modal.value = 'delete'
  }

  async function runModalAction(action, onSuccess) {
    actionLoading.value = true
    resetModalError()

    try {
      await action()
      if (onSuccess) await onSuccess()
    } catch (error) {
      modalError.value = error.response?.data?.message || error.message
    } finally {
      actionLoading.value = false
    }
  }

  async function doCreatePelerin() {
    if (!form.value.nom || !form.value.prenom || !form.value.email) {
      modalError.value = 'Nom, prenom et email sont requis'
      return
    }

    await runModalAction(
      () => createPelerin(form.value),
      async () => {
        closeModal()
        showToast("Pelerin cree - email d'activation envoye")
        await loadAll()
      }
    )
  }

  async function doCreateGuide() {
    if (!form.value.nom || !form.value.prenom || !form.value.email) {
      modalError.value = 'Nom, prenom et email sont requis'
      return
    }

    await runModalAction(
      () => createGuide(form.value),
      async () => {
        closeModal()
        showToast("Guide cree - email d'activation envoye")
        await loadAll()
      }
    )
  }

  async function doCreateGroupe() {
    if (!form.value.nom || !form.value.annee || !form.value.typeVoyage) {
      modalError.value = 'Nom, annee et type sont requis'
      return
    }

    await runModalAction(
      () => createGroupe(form.value),
      async () => {
        closeModal()
        showToast('Groupe cree avec succes')
        await loadAll()
      }
    )
  }

  async function doEdit() {
    await runModalAction(
      async () => {
        const id = editTarget.value.id

        if (editType.value === 'pelerin') await updatePelerin(id, form.value)
        else if (editType.value === 'guide') await updateGuide(id, form.value)
        else if (editType.value === 'groupe') await updateGroupe(id, form.value)
      },
      async () => {
        closeModal()
        showToast('Modifie avec succes')
        await loadAll()
      }
    )
  }

  async function doAssign() {
    const idsToAssign = Array.isArray(form.value?.pelerinIds)
      ? form.value.pelerinIds.filter(Boolean)
      : form.value?.pelerinId
        ? [form.value.pelerinId]
        : []

    if (idsToAssign.length === 0) {
      modalError.value = 'Selectionnez au moins un pelerin'
      return
    }

    await runModalAction(
      async () => {
        for (const pelerinId of idsToAssign) {
          await assignerPelerin(selectedGroupe.value.id, pelerinId)
        }
      },
      async () => {
        closeModal()
        showToast(idsToAssign.length === 1 ? 'Pelerin affecte au groupe' : `${idsToAssign.length} pelerins affectes au groupe`)
        await loadAll()
      }
    )
  }

  function removePelerinFromGroupState(pelerinId, groupeId) {
    const groupe = groupes.value.find((item) => item.id === groupeId)
    if (!groupe) return

    if (groupe.pelerins) {
      groupe.pelerins = groupe.pelerins.filter((item) => item.id !== pelerinId)
    }

    if (groupe._count) {
      groupe._count.pelerins = Math.max(0, (groupe._count.pelerins || 0) - 1)
    }
  }

  function addPelerinToGroupState(pelerin, groupeId) {
    const groupe = groupes.value.find((item) => item.id === groupeId)
    if (!groupe) return

    pelerin.groupeId = groupeId
    pelerin.groupe = { id: groupe.id, nom: groupe.nom }

    if (groupe.pelerins && !groupe.pelerins.find((item) => item.id === pelerin.id)) {
      groupe.pelerins.push(pelerin)
    }

    if (groupe._count) {
      groupe._count.pelerins += 1
    }
  }

  async function doDelete() {
    actionLoading.value = true

    try {
      const id = deleteTarget.value.id
      let successMessage = 'Supprime avec succes'

      if (deleteType.value === 'pelerin') {
        const pelerin = pelerins.value.find((item) => item.id === id)
        const oldGroupeId = pelerin?.groupeId

        await deletePelerin(id)
        pelerins.value = pelerins.value.filter((item) => item.id !== id)

        if (oldGroupeId) {
          removePelerinFromGroupState(id, oldGroupeId)
        }
      } else if (deleteType.value === 'guide') {
        await deleteGuide(id)
        guides.value = guides.value.filter((item) => item.id !== id)
      } else if (deleteType.value === 'groupe') {
        const result = await deleteGroupe(id)

        if (result?.action === 'status_changed' && result?.groupe) {
          const index = groupes.value.findIndex((item) => item.id === id)
          if (index >= 0) {
            groupes.value[index] = normalizeGroupe(result.groupe)
          } else {
            groupes.value = [...groupes.value, normalizeGroupe(result.groupe)]
          }
          successMessage = 'Groupe annule (statut ANNULE)'
        } else {
          groupes.value = groupes.value.filter((item) => item.id !== id)
        }
      }

      closeModal()
      showToast(successMessage)
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    } finally {
      actionLoading.value = false
    }
  }

  async function doResendActivation(guide) {
    resendingId.value = guide.id

    try {
      await resendActivation(guide.id)
      showToast("Email d'activation renvoye")
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    } finally {
      resendingId.value = null
    }
  }

  async function doResendPelerinActivation(pelerin) {
    resendingPelerinId.value = pelerin.id

    try {
      await resendPelerinActivation(pelerin.id)
      showToast("Email d'activation renvoye")
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    } finally {
      resendingPelerinId.value = null
    }
  }

  async function doAssignerPelerin({ groupeId, pelerinId }) {
    try {
      await assignerPelerin(groupeId, pelerinId)

      const pelerin = pelerins.value.find((item) => item.id === pelerinId)
      if (!pelerin) {
        showToast('Pelerin affecte au groupe')
        return
      }

      const oldGroupeId = pelerin.groupeId
      if (oldGroupeId && oldGroupeId !== groupeId) {
        removePelerinFromGroupState(pelerinId, oldGroupeId)
      }

      addPelerinToGroupState(pelerin, groupeId)
      showToast('Pelerin affecte au groupe')
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    }
  }

  async function doAssignerGuide({ groupeId, guideId }) {
    if (!groupeId || !guideId) return

    try {
      const groupeIndex = groupes.value.findIndex((item) => item.id === groupeId)
      const existingGroupe = groupeIndex >= 0 ? groupes.value[groupeIndex] : null
      const existingGuideIds = Array.isArray(existingGroupe?.guideIds)
        ? existingGroupe.guideIds
        : Array.isArray(existingGroupe?.guides)
          ? existingGroupe.guides.map((g) => g.id).filter(Boolean)
          : existingGroupe?.guideId
            ? [existingGroupe.guideId]
            : []
      const nextGuideIds = Array.from(new Set([...existingGuideIds, guideId]))
      const oldGuideId = existingGroupe?.guideId ?? existingGroupe?.guide?.id ?? null

      const updated = normalizeGroupe(await updateGroupe(groupeId, { guideIds: nextGuideIds }))

      if (groupeIndex >= 0) {
        groupes.value[groupeIndex] = {
          ...existingGroupe,
          ...updated,
          pelerins: existingGroupe?.pelerins ?? updated.pelerins,
        }
      } else {
        groupes.value = [...groupes.value, updated]
      }

      if (!existingGuideIds.includes(guideId)) {
        const newGuide = guides.value.find((item) => item.id === guideId)
        if (newGuide) {
          if (!newGuide._count) newGuide._count = {}
          newGuide._count.groupes = (newGuide._count.groupes ?? 0) + 1
        }
      }

      showToast('Guide affecte au groupe')
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    }
  }

  async function doRetirerPelerin({ groupeId, pelerinId }) {
    try {
      await retirerPelerin(groupeId, pelerinId)

      const pelerin = pelerins.value.find((item) => item.id === pelerinId)
      if (pelerin) {
        pelerin.groupeId = null
        pelerin.groupe = null
      }

      removePelerinFromGroupState(pelerinId, groupeId)
      showToast('Pelerin retire du groupe')
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    }
  }

  async function doRetirerGuide({ groupeId, guideId }) {
    if (!groupeId || !guideId) return

    try {
      const groupeIndex = groupes.value.findIndex((item) => item.id === groupeId)
      const existingGroupe = groupeIndex >= 0 ? groupes.value[groupeIndex] : null

      const existingGuideIds = Array.isArray(existingGroupe?.guideIds)
        ? existingGroupe.guideIds
        : Array.isArray(existingGroupe?.guides)
          ? existingGroupe.guides.map((g) => g.id).filter(Boolean)
          : existingGroupe?.guideId
            ? [existingGroupe.guideId]
            : []

      const nextGuideIds = existingGuideIds.filter((id) => id !== guideId)
      const updated = normalizeGroupe(await updateGroupe(groupeId, { guideIds: nextGuideIds }))

      if (groupeIndex >= 0) {
        groupes.value[groupeIndex] = {
          ...existingGroupe,
          ...updated,
          pelerins: existingGroupe?.pelerins ?? updated.pelerins,
        }
      } else {
        groupes.value = [...groupes.value, updated]
      }

      const guide = guides.value.find((item) => item.id === guideId)
      if (guide?._count?.groupes != null) {
        guide._count.groupes = Math.max(0, guide._count.groupes - 1)
      }

      showToast('Guide retire du groupe')
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    }
  }

  async function doBulkAssignerPelerins({ groupeId, pelerinIds }) {
    const idsToAssign = Array.isArray(pelerinIds)
      ? pelerinIds.filter(Boolean)
      : []

    if (!groupeId || idsToAssign.length === 0) {
      showToast('Selectionnez un groupe et au moins un pelerin', 'error')
      return
    }

    const pelerinsToAssign = pelerins.value.filter((item) => idsToAssign.includes(item.id))
    const actionablePelerins = pelerinsToAssign.filter((item) => item.groupeId !== groupeId)

    if (actionablePelerins.length === 0) {
      showToast('Les pelerins selectionnes sont deja dans ce groupe')
      return
    }

    bulkAssignLoading.value = true

    try {
      for (const pelerin of actionablePelerins) {
        const oldGroupeId = pelerin.groupeId

        await assignerPelerin(groupeId, pelerin.id)

        if (oldGroupeId && oldGroupeId !== groupeId) {
          removePelerinFromGroupState(pelerin.id, oldGroupeId)
        }

        addPelerinToGroupState(pelerin, groupeId)
      }

      showToast(
        actionablePelerins.length === 1
          ? '1 pelerin affecte au groupe'
          : `${actionablePelerins.length} pelerins affectes au groupe`,
      )
    } catch (error) {
      showToast(error.response?.data?.message || error.message, 'error')
    } finally {
      bulkAssignLoading.value = false
    }
  }

  return {
    modal,
    modalError,
    actionLoading,
    bulkAssignLoading,
    resendingId,
    resendingPelerinId,
    form,
    editType,
    editTarget,
    deleteTarget,
    deleteType,
    selectedGroupe,
    toast,
    showToast,
    closeModal,
    openModal,
    openEdit,
    openAssign,
    confirmDelete,
    doCreatePelerin,
    doCreateGuide,
    doCreateGroupe,
    doEdit,
    doAssign,
    doDelete,
    doResendActivation,
    doResendPelerinActivation,
    doAssignerPelerin,
    doAssignerGuide,
    doBulkAssignerPelerins,
    doRetirerPelerin,
    doRetirerGuide,
  }
}
