import api from '@/services/api'

export async function fetchAdminAgences() {
  const { data } = await api.get('/admin/agences')
  return data
}

export async function fetchAdminAgenceById(id) {
  const { data } = await api.get(`/admin/agences/${id}`)
  return data
}

export async function approveAdminAgence(id) {
  const { data } = await api.patch(`/admin/agences/${id}/approve`)
  return data
}

export async function rejectAdminAgence(id, reason) {
  const { data } = await api.patch(`/admin/agences/${id}/reject`, { reason })
  return data
}

export async function suspendAdminAgence(id) {
  const { data } = await api.patch(`/admin/agences/${id}/suspend`)
  return data
}

export async function removeAdminAgence(id) {
  const { data } = await api.delete(`/admin/agences/${id}`)
  return data
}
