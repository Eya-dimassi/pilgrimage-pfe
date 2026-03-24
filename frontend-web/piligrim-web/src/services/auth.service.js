import api from './api'

export async function register(payload) {
  const { data } = await api.post('/auth/signup', payload)
  return data
}

export async function login(email, password) {
  const { data } = await api.post('/auth/login', {
    email,
    motDePasse: password,
  })
  return data
}

export async function logout() {
  const refreshToken = localStorage.getItem('refreshToken')
  try {
    await api.post('/auth/logout', { refreshToken })
  } finally {
    clearSession()
  }
}

export async function refresh() {
  const refreshToken = localStorage.getItem('refreshToken')
  if (!refreshToken) throw new Error('No refresh token found')

  const { data } = await api.post('/auth/refresh', { refreshToken })

  localStorage.setItem('accessToken', data.accessToken)
  localStorage.setItem('refreshToken', data.refreshToken)

  return data
}

export async function getMe() {
  const { data } = await api.get('/auth/me')
  return data
}

export async function forgotPassword(email) {
  const { data } = await api.post('/auth/forgot-password', { email })
  return data
}

export async function setPassword(token, newPassword) {
  const { data } = await api.post('/auth/set-password', {
    token,
    newPassword,
  })
  return data
}

export async function verifyActivationToken(token) {
  const { data } = await api.post('/auth/verify-activation-token', { token })
  return data
}

export function saveSession(data) {
  localStorage.setItem('accessToken', data.accessToken)
  localStorage.setItem('refreshToken', data.refreshToken)
  localStorage.setItem('user', JSON.stringify(data.utilisateur))
}

export function clearSession() {
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('user')
}
