<template>
  <div class="card">
    <div class="card-header">
      <h3>{{ title }}</h3>
      <button class="card-link" type="button" @click="$emit('view-all')">{{ viewAllText }}</button>
    </div>
    <div class="mini-table">
      <div v-if="isEmpty" class="empty-row">
        <div class="empty-state-stack">
          <AppIcon :name="emptyIconName" :size="28" class="empty-state-icon" />
          <span>{{ emptyText }}</span>
          <button class="card-link" type="button" @click="$emit('empty-action')">{{ emptyActionText }}</button>
        </div>
      </div>
      <slot v-else />
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
  viewAllText: {
    type: String,
    default: 'Voir tout',
  },
  isEmpty: {
    type: Boolean,
    required: true,
  },
  emptyIconName: {
    type: String,
    required: true,
  },
  emptyText: {
    type: String,
    required: true,
  },
  emptyActionText: {
    type: String,
    required: true,
  },
})

defineEmits(['view-all', 'empty-action'])
</script>

<style scoped>
.empty-state-stack {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px;
}

.empty-state-icon {
  opacity: 0.3;
}
</style>
