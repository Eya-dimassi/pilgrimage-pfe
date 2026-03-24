<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal" :class="{ 'modal-sm': small }">
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
