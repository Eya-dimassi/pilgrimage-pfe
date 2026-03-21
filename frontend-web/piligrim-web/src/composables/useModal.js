import { ref } from 'vue'
import { useAgenceData, pelerins, guides, groupes } from './useAgenceData'

export function useModal() {
  const {
    loadAll,
    createPelerin, updatePelerin, deletePelerin,
    createGuide,   updateGuide,   deleteGuide,   resendActivation,
    createGroupe,  updateGroupe,  deleteGroupe,  assignerPelerin, retirerPelerin,
  } = useAgenceData()

  // ── State ─────────────────────────────────────────────────
  const modal         = ref(null)
  const modalError    = ref('')
  const actionLoading = ref(false)
  const resendingId   = ref(null)
  const form          = ref({})
  const editType      = ref('')
  const editTarget    = ref(null)
  const deleteTarget  = ref(null)
  const deleteType    = ref('')
  const selectedGroupe = ref(null)
  const toast         = ref({ show: false, message: '', type: 'success' })

  // ── Toast ─────────────────────────────────────────────────
  function showToast(message, type = 'success') {
    toast.value = { show: true, message, type }
    setTimeout(() => { toast.value.show = false }, 8500)
  }

  function closeModal() {
    modal.value = null
    modalError.value = ''
  }

  // ── Open helpers ──────────────────────────────────────────
  function openModal(type) {
    form.value = { typeVoyage: 'HAJJ', annee: new Date().getFullYear() }
    modalError.value = ''
    modal.value = type
  }

  function openEdit(type, target) {
    editType.value = type
    editTarget.value = target
    modalError.value = ''
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
      form.value = {
        nom: target.nom,
        annee: target.annee,
        typeVoyage: target.typeVoyage,
        description: target.description,
        guideId: target.guideId ?? '',
      }
    }
    modal.value = 'edit'
  }

  function openAssign(groupe) {
    selectedGroupe.value = groupe
    form.value = { pelerinId: '' }
    modalError.value = ''
    modal.value = 'assign'
  }

  function confirmDelete(type, target) {
    deleteType.value = type
    deleteTarget.value = target
    modal.value = 'delete'
  }

  // ── CRUD actions ──────────────────────────────────────────
  async function doCreatePelerin() {
    if (!form.value.nom || !form.value.prenom || !form.value.email) {
      modalError.value = 'Nom, prénom et email sont requis'
      return
    }
    actionLoading.value = true
    modalError.value = ''
    try {
      await createPelerin(form.value)
      closeModal()
      showToast("Pèlerin créé — email d'activation envoyé")
      await loadAll()
    } catch (e) {
      modalError.value = e.response?.data?.message || e.message
    } finally { actionLoading.value = false }
  }

  async function doCreateGuide() {
    if (!form.value.nom || !form.value.prenom || !form.value.email) {
      modalError.value = 'Nom, prénom et email sont requis'
      return
    }
    actionLoading.value = true
    modalError.value = ''
    try {
      await createGuide(form.value)
      closeModal()
      showToast("Guide créé — email d'activation envoyé")
      await loadAll()
    } catch (e) {
      modalError.value = e.response?.data?.message || e.message
    } finally { actionLoading.value = false }
  }

  async function doCreateGroupe() {
    if (!form.value.nom || !form.value.annee || !form.value.typeVoyage) {
      modalError.value = 'Nom, année et type sont requis'
      return
    }
    actionLoading.value = true
    modalError.value = ''
    try {
      await createGroupe(form.value)
      closeModal()
      showToast('Groupe créé avec succès')
      await loadAll()
    } catch (e) {
      modalError.value = e.response?.data?.message || e.message
    } finally { actionLoading.value = false }
  }

  async function doEdit() {
    actionLoading.value = true
    modalError.value = ''
    try {
      const id = editTarget.value.id
      if (editType.value === 'pelerin')     await updatePelerin(id, form.value)
      else if (editType.value === 'guide')  await updateGuide(id, form.value)
      else if (editType.value === 'groupe') await updateGroupe(id, form.value)
      closeModal()
      showToast('Modifié avec succès')
      await loadAll()
    } catch (e) {
      modalError.value = e.response?.data?.message || e.message
    } finally { actionLoading.value = false }
  }

  async function doAssign() {
    actionLoading.value = true
    modalError.value = ''
    try {
      await assignerPelerin(selectedGroupe.value.id, form.value.pelerinId)
      closeModal()
      showToast('Pèlerin affecté au groupe')
      await loadAll()
    } catch (e) {
      modalError.value = e.response?.data?.message || e.message
    } finally { actionLoading.value = false }
  }

  async function doDelete() {
    actionLoading.value = true
    try {
      const id = deleteTarget.value.id
      if (deleteType.value === 'pelerin') {
        await deletePelerin(id)
        // find which group this pelerin belongs to before removing
        const pelerin = pelerins.value.find(p => p.id === id)
        const oldGroupeId = pelerin?.groupeId
        pelerins.value = pelerins.value.filter(p => p.id !== id)
        // only decrement the group that actually owned this pelerin
        if (oldGroupeId) {
          const groupe = groupes.value.find(g => g.id === oldGroupeId)
          if (groupe) {
            if (groupe.pelerins) groupe.pelerins = groupe.pelerins.filter(p => p.id !== id)
            if (groupe._count) groupe._count.pelerins = Math.max(0, (groupe._count.pelerins || 0) - 1)
          }
        }
      } else if (deleteType.value === 'guide') {
        await deleteGuide(id)
        guides.value = guides.value.filter(g => g.id !== id)  // ← was missing
      } else if (deleteType.value === 'groupe') {
        await deleteGroupe(id)
        groupes.value = groupes.value.filter(g => g.id !== id)
      }
      closeModal()
      showToast('Supprimé avec succès')
    } catch (e) {
      showToast(e.response?.data?.message || e.message, 'error')
    } finally { actionLoading.value = false }
  }

  async function doResendActivation(guide) {
    resendingId.value = guide.id
    try {
      await resendActivation(guide.id)
      showToast("Email d'activation renvoyé")
    } catch (e) {
      showToast(e.response?.data?.message || e.message, 'error')
    } finally { resendingId.value = null }
  }

  async function doAssignerPelerin({ groupeId, pelerinId }) {
    try {
      await assignerPelerin(groupeId, pelerinId)
      const pelerin = pelerins.value.find(p => p.id === pelerinId)
      const newGroupe = groupes.value.find(g => g.id === groupeId)

      if (pelerin) {
        // remove from old group first
        const oldGroupeId = pelerin.groupeId
        if (oldGroupeId && oldGroupeId !== groupeId) {
          const oldGroupe = groupes.value.find(g => g.id === oldGroupeId)
          if (oldGroupe) {
            if (oldGroupe.pelerins) oldGroupe.pelerins = oldGroupe.pelerins.filter(p => p.id !== pelerinId)
            if (oldGroupe._count) oldGroupe._count.pelerins = Math.max(0, (oldGroupe._count.pelerins || 0) - 1)
          }
        }
        // assign to new group
        pelerin.groupeId = groupeId
        pelerin.groupe = newGroupe ? { id: newGroupe.id, nom: newGroupe.nom } : null
        if (newGroupe) {
          if (newGroupe.pelerins && !newGroupe.pelerins.find(p => p.id === pelerinId)) {
            newGroupe.pelerins.push(pelerin)
          }
          if (newGroupe._count) newGroupe._count.pelerins++
        }
      }
      showToast('Pèlerin affecté au groupe')
    } catch (e) {
      showToast(e.response?.data?.message || e.message, 'error')
    }
  }

  async function doRetirerPelerin({ groupeId, pelerinId }) {
    try {
      await retirerPelerin(groupeId, pelerinId)
      // optimistic: clear pelerin's groupeId in local state
      const pelerin = pelerins.value.find(p => p.id === pelerinId)
      const groupe = groupes.value.find(g => g.id === groupeId)
      if (pelerin) {
        pelerin.groupeId = null
        pelerin.groupe = null
      }
      if (groupe) {
        if (groupe.pelerins) groupe.pelerins = groupe.pelerins.filter(p => p.id !== pelerinId)
        if (groupe._count) groupe._count.pelerins--
      }
      showToast('Pèlerin retiré du groupe')
    } catch (e) {
      showToast(e.response?.data?.message || e.message, 'error')
    }
  }

  return {
    // state
    modal, modalError, actionLoading, resendingId, form,
    editType, editTarget, deleteTarget, deleteType,
    selectedGroupe, toast,
    // helpers
    showToast, closeModal,
    // open
    openModal, openEdit, openAssign, confirmDelete,
    // actions
    doCreatePelerin, doCreateGuide, doCreateGroupe,
    doEdit, doAssign, doDelete, doResendActivation,
    doAssignerPelerin, doRetirerPelerin,
  }
}