<template>
  <svg
    :width="size"
    :height="size"
    :viewBox="icon.viewBox"
    fill="none"
    :stroke="color"
    :stroke-width="strokeWidth"
    stroke-linecap="round"
    stroke-linejoin="round"
    :class="{ spin }"
    aria-hidden="true"
    v-html="icon.body"
  />
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  name: {
    type: String,
    required: true,
  },
  size: {
    type: [Number, String],
    default: 16,
  },
  color: {
    type: String,
    default: 'currentColor',
  },
  strokeWidth: {
    type: [Number, String],
    default: 1.75,
  },
  spin: {
    type: Boolean,
    default: false,
  },
})

const icons = {
  alert: {
    viewBox: '0 0 24 24',
    body: '<circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />',
  },
  building: {
    viewBox: '0 0 24 24',
    body: '<path d="M19 21V5a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v16" /><path d="M3 21h18" /><path d="M9 7h1" /><path d="M14 7h1" /><path d="M9 11h1" /><path d="M14 11h1" /><path d="M10 21v-4a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v4" />',
  },
  'calendar-plus': {
    viewBox: '0 0 24 24',
    body: '<rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /><line x1="12" y1="13.5" x2="12" y2="18.5" /><line x1="9.5" y1="16" x2="14.5" y2="16" />',
  },
  calendar: {
    viewBox: '0 0 24 24',
    body: '<rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />',
  },
  check: {
    viewBox: '0 0 24 24',
    body: '<path d="M5 13l4 4L19 7" />',
  },
  'chevron-down': {
    viewBox: '0 0 24 24',
    body: '<polyline points="6 9 12 15 18 9" />',
  },
  'chevron-up': {
    viewBox: '0 0 24 24',
    body: '<polyline points="18 15 12 9 6 15" />',
  },
  edit: {
    viewBox: '0 0 24 24',
    body: '<path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />',
  },
  download: {
    viewBox: '0 0 24 24',
    body: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />',
  },
  filter: {
    viewBox: '0 0 24 24',
    body: '<path d="M22 3H2l8 9v7l4 2v-9l8-9Z" />',
  },
  'filter-sort': {
    viewBox: '0 0 24 24',
    body: '<line x1="4" y1="6" x2="14" y2="6" /><line x1="4" y1="10" x2="12" y2="10" /><line x1="4" y1="14" x2="10" y2="14" /><line x1="18" y1="6" x2="18" y2="18" /><polyline points="15 15 18 18 21 15" />',
  },
  'eye-off': {
    viewBox: '0 0 24 24',
    body: '<path d="M17.94 17.94A10.94 10.94 0 0 1 12 20c-5 0-9.27-3-11-8a21.77 21.77 0 0 1 5.06-7.94" /><path d="M9.9 4.24A10.94 10.94 0 0 1 12 4c5 0 9.27 3 11 8a22.2 22.2 0 0 1-4.24 6.08" /><line x1="1" y1="1" x2="23" y2="23" /><path d="M9.53 9.53a3 3 0 0 0 4.24 4.24" />',
  },
  eye: {
    viewBox: '0 0 24 24',
    body: '<path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12z" /><circle cx="12" cy="12" r="3" />',
  },
  globe: {
    viewBox: '0 0 24 24',
    body: '<circle cx="12" cy="12" r="10" /><line x1="2" y1="12" x2="22" y2="12" /><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />',
  },
  grid: {
    viewBox: '0 0 24 24',
    body: '<rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" />',
  },
  layers: {
    viewBox: '0 0 24 24',
    body: '<polygon points="12 2 3 7 12 12 21 7 12 2" /><polyline points="3 12 12 17 21 12" /><polyline points="3 17 12 22 21 17" />',
  },
  list: {
    viewBox: '0 0 24 24',
    body: '<line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" /><line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" />',
  },
  home: {
    viewBox: '0 0 24 24',
    body: '<path d="M3 12l2-2 7-7 7 7 2 2" /><path d="M5 10v10a1 1 0 0 0 1 1h3m10-11v10a1 1 0 0 1-1 1h-3" /><path d="M9 21v-6a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v6" />',
  },
  lock: {
    viewBox: '0 0 24 24',
    body: '<rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />',
  },
  logout: {
    viewBox: '0 0 24 24',
    body: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />',
  },
  mail: {
    viewBox: '0 0 24 24',
    body: '<path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" /><polyline points="22,6 12,13 2,6" />',
  },
  menu: {
    viewBox: '0 0 24 24',
    body: '<line x1="4" y1="7" x2="20" y2="7" /><line x1="4" y1="12" x2="20" y2="12" /><line x1="4" y1="17" x2="20" y2="17" />',
  },
  moon: {
    viewBox: '0 0 24 24',
    body: '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />',
  },
  'map-pin': {
    viewBox: '0 0 24 24',
    body: '<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />',
  },
  phone: {
    viewBox: '0 0 24 24',
    body: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.38 2 2 0 0 1 3.58 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.96a16 16 0 0 0 6.29 6.29l1.42-1.42a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />',
  },
  plus: {
    viewBox: '0 0 24 24',
    body: '<line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />',
  },
  sparkles: {
    viewBox: '0 0 24 24',
    body: '<path d="M12 3l1.6 4.4L18 9l-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6L12 3z" /><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8L19 15z" /><path d="M5 14l.9 2.1L8 17l-2.1.9L5 20l-.9-2.1L2 17l2.1-.9L5 14z" />',
  },
  'arrow-right-left': {
    viewBox: '0 0 24 24',
    body: '<path d="M4 7h12" /><polyline points="13 4 16 7 13 10" /><path d="M20 17H8" /><polyline points="11 14 8 17 11 20" />',
  },
  refresh: {
    viewBox: '0 0 24 24',
    body: '<polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" /><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10" /><path d="M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />',
  },
  search: {
    viewBox: '0 0 24 24',
    body: '<circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />',
  },
  spinner: {
    viewBox: '0 0 24 24',
    body: '<path d="M21 12a9 9 0 1 1-6.219-8.56" />',
  },
  sun: {
    viewBox: '0 0 24 24',
    body: '<circle cx="12" cy="12" r="4" /><path d="M12 2v2" /><path d="M12 20v2" /><path d="m4.93 4.93 1.41 1.41" /><path d="m17.66 17.66 1.41 1.41" /><path d="M2 12h2" /><path d="M20 12h2" /><path d="m6.34 17.66-1.41 1.41" /><path d="m19.07 4.93-1.41 1.41" />',
  },
  trash: {
    viewBox: '0 0 24 24',
    body: '<polyline points="3 6 5 6 21 6" /><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" /><path d="M10 11v6" /><path d="M14 11v6" /><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />',
  },
  user: {
    viewBox: '0 0 24 24',
    body: '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />',
  },
  'user-check': {
    viewBox: '0 0 24 24',
    body: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><polyline points="16 11 18 13 22 9" />',
  },
  users: {
    viewBox: '0 0 24 24',
    body: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />',
  },
  x: {
    viewBox: '0 0 24 24',
    body: '<line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />',
  },
}

const icon = computed(() => icons[props.name] ?? icons.x)
</script>

<style scoped>
.spin {
  animation: app-icon-spin 0.8s linear infinite;
}

@keyframes app-icon-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
