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
    <Toast :show="showToast" />
  </div>
</template>

<script setup>
import Navbar     from '../components/Navbar.vue'
import Hero       from '../components/Hero.vue'
import Features   from '../components/Features.vue'
import CTA        from '../components/CTA.vue'
import Footer     from '../components/Footer.vue'
import Modal      from '../components/Modal.vue'
import LoginModal from '../components/LoginModal.vue'
import Toast      from '../components/Toast.vue'
import { useHomePageState } from '../composables/useHomePageState'

const {
  showSignup,
  showLogin,
  showToast,
  isDark,
  openSignup,
  closeSignup,
  openLogin,
  closeLogin,
  toggleDark,
  handleSignupSuccess,
} = useHomePageState()
</script>
