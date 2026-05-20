<template>
  <Teleport to="body">
    <div class="toast" :class="[type, { show }]">
      <div class="t-ico">{{ icon }}</div>
      <div>
        <div class="t-title">{{ resolvedTitle }}</div>
        <div v-if="message" class="t-sub">{{ message }}</div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useToastStore } from '@/stores/useToastStore'

const toastStore = useToastStore()
const { show, type, title, message } = storeToRefs(toastStore)

const resolvedTitle = computed(() => {
  if (title.value) return title.value
  return type.value === 'error' ? 'Erreur' : 'Succes'
})

const icon = computed(() => (type.value === 'error' ? '!' : '✓'))
</script>
