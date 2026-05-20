<template>
  <div>
    <Navbar
      :is-dark="isDark"
      @open-modal="openSignup"
      @open-login="openLogin"
      @toggle-dark="toggleDark"
    />
    <Hero @open-modal="openSignup" />
    <Features />
    <CTA />
    <Footer />

    <Modal
      :show="showSignup"
      @close="closeSignup"
      @submit="handleSignupSuccess"
    />
    <LoginModal
      :show="showLogin"
      @close="closeLogin"
      @switch-to-signup="closeLogin(); openSignup()"
    />
  </div>
</template>

<script setup>
import CTA from '@/features/Home/views/CTA.vue'
import Features from '@/features/Home/views/Features.vue'
import Footer from '@/features/Home/views/Footer.vue'
import Hero from '@/features/Home/views/Hero.vue'
import Navbar from '@/features/Home/views/Navbar.vue'
import LoginModal from '@/features/auth/views/LoginModal.vue'
import Modal from '@/features/auth/views/Modal.vue'
import { useHomePageState } from '@/features/Home/views/composables/useHomePageState'

const {
  showSignup,
  showLogin,
  isDark,
  openSignup,
  closeSignup,
  openLogin,
  closeLogin,
  toggleDark,
  handleSignupSuccess,
} = useHomePageState()
</script>
