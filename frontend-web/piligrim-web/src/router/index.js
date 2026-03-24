import { createRouter, createWebHistory } from 'vue-router'
import HomePageView from '@/views/HomePageView.vue'
import ActivateAccountView from '@/views/ActivateAccountView.vue'
import ForgotPasswordView from '@/views/ForgotPasswordView.vue'
import SetPasswordView from '@/views/SetPasswordView.vue'

const routes = [
  // Login now lives in the homepage modal, so /login redirects home.
  { path: '/login', redirect: '/' },
  { path: '/', component: HomePageView },
  {
    path: '/forgot-password',
    name: 'ForgotPassword',
    component: ForgotPasswordView,
    meta: { requiresAuth: false },
  },
  {
    path: '/auth/set-password',
    name: 'SetPassword',
    component: SetPasswordView,
    meta: { requiresAuth: false },
  },
  {
    path: '/dashboard',
    component: () => import('@/features/agence/views/DashboardView.vue'),
    meta: { requiresAuth: true, role: 'AGENCE' },
  },
  {
    path: '/admin',
    component: () => import('@/features/admin/views/AdminView.vue'),
    meta: { requiresAuth: true, role: 'SUPER_ADMIN' },
  },
  {
    path: '/activate-account',
    name: 'ActivateAccount',
    component: ActivateAccountView,
    meta: { requiresAuth: false },
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('accessToken')
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  if (to.meta.requiresAuth && !token) {
    return next('/')
  }

  if (to.meta.role && user.role !== to.meta.role) {
    return next('/')
  }

  next()
})

export default router
