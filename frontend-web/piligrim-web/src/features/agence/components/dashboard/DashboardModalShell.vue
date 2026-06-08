<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal" :class="{ 'modal-sm': small }">
      <button class="modal-close-button" type="button" aria-label="Fermer" @click="$emit('close')">
        <AppIcon name="x" :size="15" :stroke-width="2.5" />
      </button>
      <h3 class="modal-title" :class="{ danger }">{{ title }}</h3>
      <slot />
      <p v-if="error" class="modal-error">{{ error }}</p>
      <div v-if="$slots.actions" class="modal-actions">
        <slot name="actions" />
      </div>
    </div>
  </div>
</template>

<script setup>
import AppIcon from '@/components/AppIcon.vue'

defineProps({
  title: {
    type: String,
    required: true,
  },
  error: {
    type: String,
    default: '',
  },
  danger: {
    type: Boolean,
    default: false,
  },
  small: {
    type: Boolean,
    default: false,
  },
})

defineEmits(['close'])
</script>
