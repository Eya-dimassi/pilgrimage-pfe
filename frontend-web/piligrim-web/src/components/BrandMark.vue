<template>
  <div
    class="brand-mark"
    :class="{ halo }"
    :style="{
      '--brand-size': `${size}px`,
      '--brand-core': `${Math.round(size * 0.72)}px`,
    }"
  >
    <div class="brand-mark-core">
      <svg
        viewBox="0 0 64 64"
        aria-hidden="true"
        focusable="false"
        class="brand-mark-icon"
      >
        <g fill="currentColor">
          <path d="M18 49v-4h4V32h7v13h6v-5.5c0-2 1.6-3.5 3.5-3.5s3.5 1.5 3.5 3.5V45h6V32h7v13h4v4H18Z" />
          <path d="M24 29v-4.4L35 16l11 8.6V29H24Z" />
          <rect x="18" y="24" width="4" height="13" rx="2" />
          <path d="M20 18c1.8 2.4 2.3 4 0 6.2-2.3-2.2-1.8-3.8 0-6.2Z" />
          <rect x="46" y="23" width="4" height="14" rx="2" />
          <circle cx="48" cy="19" r="4.6" />
        </g>
      </svg>
    </div>
  </div>
</template>

<script setup>
defineProps({
  size: {
    type: Number,
    default: 42,
  },
  halo: {
    type: Boolean,
    default: true,
  },
})
</script>

<style scoped>
.brand-mark {
  width: var(--brand-size);
  height: var(--brand-size);
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle, rgba(244, 226, 164, 0.82) 0%, rgba(244, 226, 164, 0.46) 56%, rgba(244, 226, 164, 0.12) 74%, transparent 78%);
}

.brand-mark.halo {
  box-shadow: 0 0 0 12px rgba(244, 226, 164, 0.18);
}

.brand-mark-core {
  width: var(--brand-core);
  height: var(--brand-core);
  border-radius: 50%;
  background: #12100d;
  color: #e0bb43;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 10px 22px rgba(18, 16, 13, 0.18);
}

.brand-mark-icon {
  width: 64%;
  height: 64%;
  display: block;
}
</style>
