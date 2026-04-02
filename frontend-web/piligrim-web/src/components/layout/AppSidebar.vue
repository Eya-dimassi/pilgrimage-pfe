<template>
  <aside class="sidebar">
    <div v-if="!hideHeader" class="sidebar-logo">
      <div class="sidebar-header-row">
        <template v-if="headerShowLogo">
          <template v-if="logoVariant === 'brand-mark'">
            <BrandMark :size="46" />
          </template>

          <template v-else>
            <div class="logo-mark">
              <AppIcon :name="logoIconName" :size="16" :stroke-width="2.2" />
            </div>
          </template>
        </template>

        <div>
          <div class="logo-name">{{ headerTitle || brand.name }}</div>
          <div v-if="headerSubtitle || logoSubtitle" class="logo-sub">{{ headerSubtitle || logoSubtitle }}</div>
        </div>
      </div>

      <div
        v-if="profilePosition === 'top'"
        :class="['sidebar-header-profile', profileClass]"
        :style="{ cursor: profileClickable ? 'pointer' : 'default' }"
        @click="handleProfileClick"
      >
        <div :class="avatarClass">{{ userInitials }}</div>
        <div :class="infoClass">
          <div :class="nameClass">{{ displayUserName }}</div>
          <div :class="roleClass">{{ userRole }}</div>
        </div>
      </div>
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

      <button v-if="logoutPosition !== 'bottom'" class="nav-item nav-logout" @click="$emit('logout')">
        <AppIcon class="nav-icon" name="logout" :size="18" />
        {{ logoutLabel }}
      </button>
    </nav>

    <div :class="footerContainerClass">
      <div class="sidebar-footer-main">
        <div v-if="footerBrand || footerLogo" class="sidebar-footer-brand">
          <BrandMark :size="28" />
          <span class="sidebar-footer-brand-name">{{ brand.name }}</span>
        </div>
        <div
          v-if="profilePosition === 'bottom'"
          :class="profileClass"
          :style="{ cursor: profileClickable ? 'pointer' : 'default' }"
          @click="handleProfileClick"
        >
          <div :class="avatarClass">{{ userInitials }}</div>
          <div :class="infoClass">
            <div :class="nameClass">{{ displayUserName }}</div>
            <div :class="roleClass">{{ userRole }}</div>
          </div>
        </div>
      </div>

      <button
        v-if="logoutPosition === 'bottom'"
        class="nav-item nav-logout sidebar-logout-bottom"
        @click="$emit('logout')"
      >
        <AppIcon class="nav-icon" name="logout" :size="18" />
        {{ logoutLabel }}
      </button>
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
  headerTitle: {
    type: String,
    default: '',
  },
  headerSubtitle: {
    type: String,
    default: '',
  },
  headerShowLogo: {
    type: Boolean,
    default: true,
  },
  hideHeader: {
    type: Boolean,
    default: false,
  },
  accountSectionLabel: {
    type: String,
    default: '',
  },
  logoutLabel: {
    type: String,
    default: 'Se deconnecter',
  },
  logoutPosition: {
    type: String,
    default: 'nav',
  },
  profileClickable: {
    type: Boolean,
    default: false,
  },
  footerVariant: {
    type: String,
    default: 'card',
  },
  footerLogo: {
    type: Boolean,
    default: false,
  },
  footerBrand: {
    type: Boolean,
    default: false,
  },
  profilePosition: {
    type: String,
    default: 'bottom',
  },
})

const emit = defineEmits(['navigate', 'open-profile', 'logout'])

const isProfileFooter = computed(() => props.footerVariant === 'profile')
const footerClass = computed(() => (isProfileFooter.value ? 'sidebar-profile' : 'sidebar-footer'))
const footerContainerClass = computed(() => [
  footerClass.value,
  { 'sidebar-bottom--stack': props.logoutPosition === 'bottom' },
])
const profileClass = computed(() => (isProfileFooter.value ? 'sidebar-profile-card' : 'user-card'))
const avatarClass = computed(() => (isProfileFooter.value ? 'profile-avatar' : 'user-avatar'))
const infoClass = computed(() => (isProfileFooter.value ? 'profile-info' : 'user-info'))
const nameClass = computed(() => (isProfileFooter.value ? 'profile-name' : 'user-name'))
const roleClass = computed(() => (isProfileFooter.value ? 'profile-role' : 'user-role'))

const displayUserName = computed(() => {
  const rawPrenom = String(props.user?.prenom ?? '').trim()
  const rawNom = String(props.user?.nom ?? '').trim()

  const prenom = rawPrenom === '-' || rawPrenom === '—' || rawPrenom === 'â€”' ? '' : rawPrenom
  const nom = rawNom === '-' || rawNom === '—' || rawNom === 'â€”' ? '' : rawNom

  return `${prenom} ${nom}`.trim() || '-'
})

function handleProfileClick() {
  if (props.profileClickable) {
    emit('open-profile')
  }
}
</script>
