<template>
  <header class="topbar">
    <div class="topbar-left">
      <button class="topbar-btn topbar-btn--sidebar" type="button" @click="$emit('toggle-sidebar')">
        <AppIcon name="menu" :size="17" />
      </button>

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
    </div>

    <div class="topbar-right">
      <div class="topbar-tools">
      <button class="topbar-btn" @click="$emit('toggle-theme')">
        <AppIcon v-if="isDark" name="sun" :size="16" />
        <AppIcon v-else name="moon" :size="16" />
      </button>
      <button class="topbar-btn" title="Actualiser" @click="$emit('refresh')">
        <AppIcon name="refresh" :size="16" />
      </button>
      </div>
      <div
        v-if="showProfileCard"
        ref="profileMenuRef"
        class="topbar-profile-wrap"
      >
        <button
          class="topbar-profile-trigger"
          type="button"
          :aria-expanded="isProfileOpen"
          aria-haspopup="menu"
          @click="toggleProfileMenu"
        >
          <div class="topbar-profile-avatar">
            <img v-if="avatarSrc" :src="avatarSrc" alt="" class="topbar-profile-avatar-image" />
            <template v-else>{{ avatarText }}</template>
          </div>
          <div class="topbar-profile-copy">
            <div class="topbar-profile-name">{{ displayName }}</div>
            <div v-if="displayEmail" class="topbar-profile-email">{{ displayEmail }}</div>
            <div v-else-if="userRole" class="topbar-profile-email">{{ userRole }}</div>
          </div>
          <AppIcon :name="isProfileOpen ? 'chevron-up' : 'chevron-down'" :size="18" />
        </button>

        <transition name="profile-menu">
          <div v-if="isProfileOpen" class="topbar-profile-menu" role="menu">
            <button class="topbar-menu-item" type="button" role="menuitem" @click="handleMenuAction('profile')">
              <AppIcon name="user" :size="18" />
              <span>Profil</span>
            </button>
            <button class="topbar-menu-item" type="button" role="menuitem" @click="handleMenuAction('edit-profile')">
              <AppIcon name="edit" :size="18" />
              <span>Modifier le profil</span>
            </button>
            <div class="topbar-menu-divider" />
            <div class="topbar-menu-item topbar-menu-item--toggle" role="group" aria-label="Mode sombre">
              <div class="topbar-menu-item-main">
                <AppIcon name="moon" :size="18" />
                <span>Mode sombre</span>
              </div>
              <button
                type="button"
                class="topbar-switch"
                :class="{ 'topbar-switch--active': isDark }"
                :aria-pressed="isDark"
                @click.stop="$emit('toggle-theme')"
              >
                <span class="topbar-switch-thumb" />
              </button>
            </div>
            <div class="topbar-menu-divider" />
            <button class="topbar-menu-item topbar-menu-item--danger" type="button" role="menuitem" @click="handleMenuAction('logout')">
              <AppIcon name="logout" :size="18" />
              <span>Se deconnecter</span>
            </button>
          </div>
        </transition>
      </div>
      <div v-else-if="avatarText || avatarSrc" class="topbar-avatar">
        <img v-if="avatarSrc" :src="avatarSrc" alt="" class="topbar-profile-avatar-image" />
        <template v-else>{{ avatarText }}</template>
      </div>
    </div>
  </header>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import AppIcon from '@/components/AppIcon.vue'

const props = defineProps({
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
  avatarSrc: {
    type: String,
    default: '',
  },
  user: {
    type: Object,
    default: () => ({}),
  },
  userRole: {
    type: String,
    default: '',
  },
})

const emit = defineEmits(['refresh', 'toggle-theme', 'toggle-sidebar', 'update:modelValue', 'logout', 'open-profile', 'edit-profile'])

const isProfileOpen = ref(false)
const profileMenuRef = ref(null)

const displayName = computed(() => {
  const prenom = String(props.user?.prenom ?? '').trim()
  const nom = String(props.user?.nom ?? '').trim()
  return `${prenom} ${nom}`.trim() || 'Mon compte'
})

const displayEmail = computed(() => String(props.user?.email ?? '').trim())
const showProfileCard = computed(() => Boolean(props.avatarText || displayName.value || displayEmail.value || props.userRole))

function toggleProfileMenu() {
  isProfileOpen.value = !isProfileOpen.value
}

function closeProfileMenu() {
  isProfileOpen.value = false
}

function handleMenuAction(action) {
  closeProfileMenu()
  if (action === 'logout') emit('logout')
  if (action === 'profile') emit('open-profile')
  if (action === 'edit-profile') emit('edit-profile')
}

function handleDocumentClick(event) {
  if (!profileMenuRef.value?.contains(event.target)) {
    closeProfileMenu()
  }
}

onMounted(() => {
  document.addEventListener('click', handleDocumentClick)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleDocumentClick)
})
</script>
