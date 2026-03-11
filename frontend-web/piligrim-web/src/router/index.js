import { createRouter, createWebHistory } from 'vue-router'
import HomePageView from '@/views/HomePageView.vue'

const routes = [
  // login is now a modal on the homepage — redirect /login to /
  { path: '/login', redirect: '/' },

  { path: '/', component: HomePageView },

  {
    path: '/dashboard',
    component: () => import('@/views/DashboardView.vue'),
    meta: { requiresAuth: true, role: 'AGENCE' }
  },
  {
    path: '/admin',
    component: () => import('@/views/AdminView.vue'),
    meta: { requiresAuth: true, role: 'SUPER_ADMIN' }
  },
  {
  path: '/auth/set-password',
  component: () => import('@/views/SetPasswordView.vue')
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