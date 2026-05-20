import { storeToRefs } from 'pinia'
import { useToastStore } from '@/stores/useToastStore'

export function useAdminToast() {
  const toastStore = useToastStore()
  const { show: showToast, message: toastMessage, type: toastType } = storeToRefs(toastStore)

  function toast(message, type = 'success') {
    if (type === 'error') {
      toastStore.error(message)
      return
    }

    toastStore.success(message)
  }

  return { showToast, toastMessage, toastType, toast }
}
