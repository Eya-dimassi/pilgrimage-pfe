import { ref } from 'vue'

const showToast    = ref(false)
const toastMessage = ref('')
const toastType    = ref('success')
let timer = null

export function useAdminToast() {
  function toast(message, type = 'success') {
    if (timer) clearTimeout(timer)
    toastMessage.value = message
    toastType.value    = type
    showToast.value    = true
    timer = setTimeout(() => { showToast.value = false }, 3000)
  }

  return { showToast, toastMessage, toastType, toast }
}