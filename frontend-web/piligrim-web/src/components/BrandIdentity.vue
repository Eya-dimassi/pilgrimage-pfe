<template>
  <div class="brand-identity" :class="{ compact }">
    <BrandMark :size="size" :halo="halo" />
    <div class="brand-copy">
      <span class="brand-name">{{ brand.name }}</span>
      <span v-if="caption" class="brand-caption">{{ caption }}</span>
    </div>
  </div>
</template>

<script setup>
import { brand } from '@/content/brand'
import BrandMark from './BrandMark.vue'

defineProps({
  caption: {
    type: String,
    default: '',
  },
  size: {
    type: Number,
    default: 42,
  },
  halo: {
    type: Boolean,
    default: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
})
</script>

<style scoped>
.brand-identity {
  display: inline-flex;
  align-items: center;
  gap: 0.85rem;
}

.brand-copy {
  display: flex;
  flex-direction: column;
  gap: 0.05rem;
}

.brand-name {
  font-size: 1.02rem;
  font-weight: 700;
  color: var(--text);
  letter-spacing: -0.02em;
}

.brand-caption {
  font-size: 0.74rem;
  color: var(--text-faint);
  letter-spacing: 0.01em;
}

.brand-identity.compact {
  gap: 0.65rem;
}

.brand-identity.compact .brand-name {
  font-size: 0.95rem;
}

.brand-identity.compact .brand-caption {
  font-size: 0.7rem;
}
</style>
