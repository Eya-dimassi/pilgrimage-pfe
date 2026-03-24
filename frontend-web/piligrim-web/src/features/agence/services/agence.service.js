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

export async function fetchAvailableAgenceGuides() {
  const { data } = await api.get('/agence/guides/available')
  return Array.isArray(data) ? data : (data.guides ?? [])
}

export async function fetchAgenceGuideStats(id) {
  const { data } = await api.get(`/agence/guides/${id}/stats`)
  return data
}

export async function createAgenceGroupe(form) {
  const body = { ...form, guideId: form.guideId || undefined }
  const { data } = await api.post('/agence/groupes', body)
  return data
}

export async function updateAgenceGroupe(id, form) {
  const { data } = await api.patch(`/agence/groupes/${id}`, form)
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

export async function fetchAgenceProfile() {
  const { data } = await api.get('/agence/profile')
  return data
}

export async function updateAgenceProfile(form) {
  const { data } = await api.patch('/agence/profile', form)
  return data
}
