import api from '@/services/api'

export async function fetchAgenceDashboardData() {
  const [pelerinsResponse, guidesResponse, groupesResponse] = await Promise.all([
    api.get('/agence/pelerins'),
    api.get('/agence/guides'),
    api.get('/agence/groupes'),
  ])

  return {
    pelerins: pelerinsResponse.data,
    guides: guidesResponse.data,
    groupes: groupesResponse.data,
  }
}

export async function createAgencePelerin(form) {
  const { data } = await api.post('/agence/pelerins', form)
  return data
}

export async function importAgencePelerins(rows) {
  const { data } = await api.post('/agence/pelerins/import', { rows })
  return data
}

export async function updateAgencePelerin(id, form) {
  const { data } = await api.patch(`/agence/pelerins/${id}`, form)
  return data
}

export async function deleteAgencePelerin(id) {
  const { data } = await api.delete(`/agence/pelerins/${id}`)
  return data
}

export async function createAgenceGuide(form) {
  const { data } = await api.post('/agence/guides', form)
  return data
}

export async function updateAgenceGuide(id, form) {
  const { data } = await api.patch(`/agence/guides/${id}`, form)
  return data
}

export async function deleteAgenceGuide(id) {
  const { data } = await api.delete(`/agence/guides/${id}`)
  return data
}

export async function resendAgenceGuideActivation(id) {
  const { data } = await api.post(`/agence/guides/${id}/resend-activation`)
  return data
}

export async function resendAgencePelerinActivation(id) {
  const { data } = await api.post(`/agence/pelerins/${id}/resend-activation`)
  return data
}

export async function fetchAgencePelerin(id) {
  const { data } = await api.get(`/agence/pelerins/${id}`)
  return data
}

export async function fetchAvailableAgenceGuides() {
  const { data } = await api.get('/agence/guides/available')
  return Array.isArray(data) ? data : (data.guides ?? [])
}

export async function fetchAgenceGuideStats(id) {
  const { data } = await api.get(`/agence/guides/${id}/stats`)
  return data
}

export async function createAgenceGroupe(form) {
  const body = {
    ...form,
    guideId: form.guideId || undefined,
    guideIds: Array.isArray(form.guideIds) ? form.guideIds : undefined,
    dateDepart: form.dateDepart || undefined,
    dateRetour: form.dateRetour || undefined,
    hajjStartDate: form.hajjStartDate || undefined,
    status: form.status || undefined,
  }
  const { data } = await api.post('/agence/groupes', body)
  return data
}

export async function updateAgenceGroupe(id, form) {
  const body = {
    ...form,
    guideId: form.guideId === '' ? null : form.guideId,
    guideIds: Array.isArray(form.guideIds) ? form.guideIds : undefined,
    dateDepart: form.dateDepart === '' ? null : form.dateDepart,
    dateRetour: form.dateRetour === '' ? null : form.dateRetour,
    hajjStartDate: form.hajjStartDate === '' ? null : form.hajjStartDate,
  }
  const { data } = await api.patch(`/agence/groupes/${id}`, body)
  return data
}

export async function deleteAgenceGroupe(id) {
  const { data } = await api.delete(`/agence/groupes/${id}`)
  return data
}

export async function assignAgencePelerin(groupeId, pelerinId) {
  const { data } = await api.post(`/agence/groupes/${groupeId}/pelerins`, { pelerinId })
  return data
}

export async function removeAgencePelerin(groupeId, pelerinId) {
  const { data } = await api.delete(`/agence/groupes/${groupeId}/pelerins/${pelerinId}`)
  return data
}

export async function fetchAgencePlanning(groupeId) {
  const { data } = await api.get(`/agence/groupes/${groupeId}/plannings`)
  return data
}

export async function createAgencePlanningDay(groupeId, form) {
  const { data } = await api.post(`/agence/groupes/${groupeId}/plannings`, form)
  return data
}

export async function generateAgencePlanningTemplate(groupeId) {
  const { data } = await api.post(`/agence/groupes/${groupeId}/plannings/generate-template`)
  return data
}

export async function shiftAgencePlanning(groupeId, form) {
  const { data } = await api.post(`/agence/groupes/${groupeId}/plannings/shift`, form)
  return data
}

export async function deleteAgencePlanning(groupeId) {
  const { data } = await api.delete(`/agence/groupes/${groupeId}/plannings`)
  return data
}

export async function updateAgencePlanningDay(planningId, form) {
  const { data } = await api.patch(`/agence/groupes/plannings/${planningId}`, form)
  return data
}

export async function deleteAgencePlanningDay(planningId) {
  const { data } = await api.delete(`/agence/groupes/plannings/${planningId}`)
  return data
}

export async function createAgencePlanningEvent(planningId, form) {
  const { data } = await api.post(`/agence/groupes/plannings/${planningId}/evenements`, form)
  return data
}

export async function updateAgencePlanningEvent(eventId, form) {
  const { data } = await api.patch(`/agence/groupes/evenements/${eventId}`, form)
  return data
}

export async function deleteAgencePlanningEvent(eventId) {
  const { data } = await api.delete(`/agence/groupes/evenements/${eventId}`)
  return data
}

export async function fetchAgenceProfile() {
  const { data } = await api.get('/agence/profile')
  return data
}

export async function updateAgenceProfile(form) {
  const { data } = await api.patch('/agence/profile', form)
  return data
}

