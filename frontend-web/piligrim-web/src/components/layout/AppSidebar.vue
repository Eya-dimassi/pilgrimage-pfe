<template>
  <aside class="sidebar">
    <div class="sidebar-logo">
      <template v-if="logoVariant === 'brand-mark'">
        <BrandMark :size="46" />
        <div>
          <div class="logo-name">{{ brand.name }}</div>
          <div v-if="logoSubtitle" class="logo-sub">{{ logoSubtitle }}</div>
        </div>
      </template>

      <template v-else>
        <div class="logo-mark">
          <AppIcon :name="logoIconName" :size="16" :stroke-width="2.2" />
        </div>
        <span class="logo-name">{{ brand.name }}</span>
      </template>
    </div>

    <nav class="sidebar-nav">
      <p class="nav-section-label">Navigation</p>
      <a
        v-for="item in navItems"
        :key="item.view"
        href="#"
        :class="['nav-item', { active: currentView === item.view }]"
        @click.prevent="$emit('navigate', item.view)"
      >
        <AppIcon class="nav-icon" :name="item.iconName" :size="18" />
        <span>{{ item.label }}</span>
        <span v-if="item.badge && getBadge(item.badge) > 0" class="nav-badge">
          {{ getBadge(item.badge) }}
        </span>
      </a>

      <p v-if="accountSectionLabel" class="nav-section-label nav-section-account">{{ accountSectionLabel }}</p>

      <button class="nav-item nav-logout" @click="$emit('logout')">
        <AppIcon class="nav-icon" name="logout" :size="18" />
        {{ logoutLabel }}
      </button>
    </nav>

    <div :class="footerClass">
      <div :class="profileClass" :style="{ cursor: profileClickable ? 'pointer' : 'default' }" @click="handleProfileClick">
        <div :class="avatarClass">{{ userInitials }}</div>
        <div :class="infoClass">
          <div :class="nameClass">{{ user?.prenom }} {{ user?.nom }}</div>
          <div :class="roleClass">{{ userRole }}</div>
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup>
import { computed } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
import BrandMark from '@/components/BrandMark.vue'
import { brand } from '@/content/brand'

const props = defineProps({
  navItems: {
    type: Array,
    required: true,
  },
  currentView: {
    type: String,
    required: true,
  },
  getBadge: {
    type: Function,
    default: () => 0,
  },
  userInitials: {
    type: String,
    required: true,
  },
  user: {
    type: Object,
    default: () => ({}),
  },
  userRole: {
    type: String,
    required: true,
  },
  logoVariant: {
    type: String,
    default: 'brand-mark',
  },
  logoIconName: {
    type: String,
    default: 'lock',
  },
  logoSubtitle: {
    type: String,
    default: '',
  },
  accountSectionLabel: {
    type: String,
    default: '',
  },
  logoutLabel: {
    type: String,
    default: 'Se deconnecter',
  },
  profileClickable: {
    type: Boolean,
    default: false,
  },
  footerVariant: {
    type: String,
    default: 'card',
  },
})

const emit = defineEmits(['navigate', 'open-profile', 'logout'])

const isProfileFooter = computed(() => props.footerVariant === 'profile')
const footerClass = computed(() => (isProfileFooter.value ? 'sidebar-profile' : 'sidebar-footer'))
const profileClass = computed(() => (isProfileFooter.value ? 'sidebar-profile-card' : 'user-card'))
const avatarClass = computed(() => (isProfileFooter.value ? 'profile-avatar' : 'user-avatar'))
const infoClass = computed(() => (isProfileFooter.value ? 'profile-info' : 'user-info'))
const nameClass = computed(() => (isProfileFooter.value ? 'profile-name' : 'user-name'))
const roleClass = computed(() => (isProfileFooter.value ? 'profile-role' : 'user-role'))

function handleProfileClick() {
  if (props.profileClickable) {
    emit('open-profile')
  }
}
</script>
