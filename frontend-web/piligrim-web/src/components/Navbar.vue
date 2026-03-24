<template>
  <nav class="nav">
    <div class="nav-inner">
      <a class="nav-logo" href="#">
        <BrandIdentity :size="46" :halo="false" />
      </a>

      <div class="nav-links">
        <a href="#why">{{ brand.homeQuestion }}</a>
        <a href="#everyone">Pour qui ?</a>
        <a href="#fonctionnalites">Fonctionnalites</a>
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
          <AppIcon v-if="isDark" name="sun" :size="16" :stroke-width="2" />
          <AppIcon v-else name="moon" :size="16" :stroke-width="2" />
        </button>

        <button class="nav-login" type="button" @click="$emit('openLogin')">
          Connexion
        </button>

        <button class="nav-cta" type="button" @click="$emit('openModal')">
          Demander l'acces
        </button>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { brand } from '@/content/brand'
import AppIcon from './AppIcon.vue'
import BrandIdentity from './BrandIdentity.vue'

defineProps({
  isDark: {
    type: Boolean,
    default: false,
  },
})

defineEmits(['openModal', 'toggleDark', 'openLogin'])
</script>
