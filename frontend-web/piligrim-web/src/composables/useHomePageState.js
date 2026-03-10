import { ref, onMounted } from 'vue'

export function useHomePageState() {
  const showSignup = ref(false)
  const showLogin  = ref(false)
  const showToast  = ref(false)
  const isDark     = ref(false)

  const openSignup  = () => { showSignup.value = true }
  const closeSignup = () => { showSignup.value = false }
  const openLogin   = () => { showLogin.value = true }
  const closeLogin  = () => { showLogin.value = false }

  // Called by Modal @submit — closes modal and briefly shows toast
  const handleSignupSuccess = () => {
    showSignup.value = false
    showToast.value = true
    setTimeout(() => { showToast.value = false }, 3600)
  }

  function applyDark(value) {
    isDark.value = value
    // Apply to <html> so ALL views (dashboard, admin) pick up the CSS vars
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
    showToast,
    isDark,
    openSignup,
    closeSignup,
    openLogin,
    closeLogin,
    toggleDark,
    handleSignupSuccess,
  }
}