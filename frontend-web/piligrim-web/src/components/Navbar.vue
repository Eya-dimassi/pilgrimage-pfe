<template>
  <nav class="nav">
    <div class="nav-inner">
      <a class="nav-logo" href="#">
        <div class="nav-logo-mark">
          <svg
            width="15"
            height="15"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2.2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <rect x="3" y="8" width="18" height="13" rx="1" />
            <path d="M7 8V6a5 5 0 0 1 10 0v2" />
            <line x1="12" y1="12" x2="12" y2="16" />
          </svg>
        </div>
        <span class="nav-logo-name">SmartHajj</span>
      </a>

      <div class="nav-links">
        <a href="#why">Pourquoi SmartHajj ?</a>
        <a href="#everyone">Pour qui ?</a>
        <a href="#fonctionnalites">Fonctionnalités</a>
        <a href="#contact">Contact</a>
      </div>

      <div class="nav-spacer"></div>

      <div class="nav-right">
        <button
          class="theme-toggle"
          type="button"
          :aria-label="isDark ? 'Mode clair' : 'Mode sombre'"
          @click="$emit('toggleDark')"
        >
          <svg
            v-if="isDark"
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <circle cx="12" cy="12" r="4" />
            <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
          </svg>

          <svg
            v-else
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
          </svg>
        </button>

        <button class="nav-login" type="button" @click="$emit('openLogin')">
          Connexion
        </button>

        <button class="nav-cta" type="button" @click="$emit('openModal')">
          Demander l'accès
        </button>
      </div>
    </div>
  </nav>
</template>

<script setup>
defineProps({
  isDark: {
    type: Boolean,
    default: false,
  },
})

defineEmits(['openModal', 'toggleDark', 'openLogin'])
</script>