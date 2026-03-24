<template>
  <span :class="['status-pill', tone]">
    <slot>{{ label }}</slot>
  </span>
</template>

<script setup>
defineProps({
  tone: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    default: '',
  },
})
</script>
