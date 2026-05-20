import { ref, onMounted } from 'vue'
import { useToastStore } from '@/stores/useToastStore'

export function useHomePageState() {
  const showSignup = ref(false)
  const showLogin = ref(false)
  const isDark = ref(false)
  const toast = useToastStore()

  const openSignup = () => { showSignup.value = true }
  const closeSignup = () => { showSignup.value = false }
  const openLogin = () => { showLogin.value = true }
  const closeLogin = () => { showLogin.value = false }

  const handleSignupSuccess = () => {
    showSignup.value = false
    toast.success('Notre equipe vous contactera sous 24h', 'Demande envoyee !', 3600)
  }

  function applyDark(value) {
    isDark.value = value
    document.documentElement.classList.toggle('dark', value)
  }

  const toggleDark = () => {
    const next = !isDark.value
    localStorage.setItem('smarthajj-theme', next ? 'dark' : 'light')
    applyDark(next)
  }

  onMounted(() => {
    applyDark(localStorage.getItem('smarthajj-theme') === 'dark')
  })

  return {
    showSignup,
    showLogin,
    isDark,
    openSignup,
    closeSignup,
    openLogin,
    closeLogin,
    toggleDark,
    handleSignupSuccess,
  }
}
