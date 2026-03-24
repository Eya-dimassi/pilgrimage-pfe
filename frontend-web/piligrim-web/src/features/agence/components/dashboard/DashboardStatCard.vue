<template>
  <button
    class="stat-card"
    :class="[tone, { clickable }]"
    :type="clickable ? 'button' : undefined"
    @click="handleClick"
  >
    <div class="stat-icon-wrap" :class="`${tone}-icon`">
      <AppIcon :name="iconName" :size="22" />
    </div>
    <div class="stat-body">
      <div class="stat-value">{{ value }}</div>
      <div class="stat-label">{{ label }}</div>
    </div>
    <div class="stat-sub">
      <slot />
    </div>
  </button>
</template>

<script setup>
import AppIcon from '@/components/AppIcon.vue'

const props = defineProps({
  tone: {
    type: String,
    required: true,
  },
  iconName: {
    type: String,
    required: true,
  },
  value: {
    type: [Number, String],
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
  clickable: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['select'])

function handleClick() {
  if (props.clickable) {
    emit('select')
  }
}
</script>

<style scoped>
.stat-card {
  text-align: left;
}

.stat-card.clickable {
  cursor: pointer;
}
</style>
