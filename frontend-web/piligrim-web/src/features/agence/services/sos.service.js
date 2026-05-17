import api from '@/services/api'

export async function fetchSosHistory() {
  const { data } = await api.get('/agence/sos')
  return Array.isArray(data) ? data : []
}
