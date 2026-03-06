import api from './api'

export const login = async (email, motDePasse) => {
  const response = await api.post('/auth/login', { email, motDePasse })
  return response.data
}

export const getMe = async () => {
  const response = await api.get('/auth/me')
  return response.data
}