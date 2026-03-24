<template>
  <header class="topbar">
    <div v-if="searchable" class="topbar-search">
      <AppIcon name="search" :size="15" :stroke-width="2" />
      <input
        :value="modelValue"
        type="text"
        :placeholder="searchPlaceholder"
        class="search-input"
        @input="$emit('update:modelValue', $event.target.value)"
      />
    </div>

    <div v-else class="breadcrumb">
      <span v-if="rootLabel" class="breadcrumb-root">{{ rootLabel }}</span>
      <span v-if="rootLabel" class="breadcrumb-sep">></span>
      <span class="breadcrumb-current">{{ viewTitle }}</span>
    </div>

    <div class="topbar-right">
      <button class="topbar-btn" @click="$emit('toggle-theme')">
        <AppIcon v-if="isDark" name="sun" :size="16" />
        <AppIcon v-else name="moon" :size="16" />
      </button>
      <button class="topbar-btn" title="Actualiser" @click="$emit('refresh')">
        <AppIcon name="refresh" :size="16" />
      </button>
      <div v-if="avatarText" class="topbar-avatar">{{ avatarText }}</div>
    </div>
  </header>
</template>

<script setup>
import AppIcon from '@/components/AppIcon.vue'

defineProps({
  viewTitle: {
    type: String,
    default: '',
  },
  rootLabel: {
    type: String,
    default: '',
  },
  isDark: {
    type: Boolean,
    default: false,
  },
  searchable: {
    type: Boolean,
    default: false,
  },
  modelValue: {
    type: String,
    default: '',
  },
  searchPlaceholder: {
    type: String,
    default: 'Rechercher...',
  },
  avatarText: {
    type: String,
    default: '',
  },
})

defineEmits(['refresh', 'toggle-theme', 'update:modelValue'])
</script>
