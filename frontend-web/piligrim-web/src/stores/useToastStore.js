import { ref } from 'vue'
import { defineStore } from 'pinia'

const DEFAULT_DURATION = 7000
let activeTimer = null

export const useToastStore = defineStore('toast', () => {
  const show = ref(false)
  const type = ref('success')
  const title = ref('')
  const message = ref('')

  function clearTimer() {
    if (activeTimer) {
      window.clearTimeout(activeTimer)
      activeTimer = null
    }
  }

  function hideToast() {
    clearTimer()
    show.value = false
  }

  function showToast({
    title: nextTitle = '',
    message: nextMessage = '',
    type: nextType = 'success',
    duration = DEFAULT_DURATION,
  }) {
    clearTimer()
    title.value = nextTitle
    message.value = nextMessage
    type.value = nextType
    show.value = true

    if (duration > 0) {
      activeTimer = window.setTimeout(() => {
        show.value = false
        activeTimer = null
      }, duration)
    }
  }

  function success(nextMessage, nextTitle = 'Succes', duration = DEFAULT_DURATION) {
    showToast({
      title: nextTitle,
      message: nextMessage,
      type: 'success',
      duration,
    })
  }

  function error(nextMessage, nextTitle = 'Erreur', duration = DEFAULT_DURATION) {
    showToast({
      title: nextTitle,
      message: nextMessage,
      type: 'error',
      duration,
    })
  }

  return {
    show,
    type,
    title,
    message,
    showToast,
    hideToast,
    success,
    error,
  }
})
