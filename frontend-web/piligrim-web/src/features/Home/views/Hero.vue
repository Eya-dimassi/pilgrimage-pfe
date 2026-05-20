<template>
  <section class="hero">
    <div class="hero-left">
      <div class="hero-pill">
        <span class="pill-dot"></span>
        {{ brand.heroLabel }}
      </div>

      <h1 class="hero-h1">
        Pilotez.<br />
        <em>Coordonnez.</em><br />
        Rassurez chaque<br />voyage.
      </h1>

      <p class="hero-sub">
        {{ brand.heroDescription }}
      </p>

      <div class="hero-form">
        <input class="hero-input" type="email" placeholder="Email de votre agence" />
        <button class="hero-btn" type="button" @click="$emit('openModal')">
          Creer un compte
        </button>
      </div>

      <div class="hero-proof">
        <div class="avatar-row">
          <div
            v-for="item in heroProofItems"
            :key="item"
            class="av"
            :class="{ 'gold-av': item === 'Famille' }"
          >
            {{ item }}
          </div>
        </div>
        <span><b>Agences, guides et familles</b> relies dans une meme interface</span>
      </div>
    </div>

    <div class="hero-right">
      <div class="hero-card">
        <div class="hero-card-img">
          <div class="carousel-wrapper">
            <img
              v-for="(img, i) in heroSlides"
              :key="img.src"
              :src="img.src"
              :alt="img.alt"
              class="carousel-img"
              :class="{ active: currentSlide === i }"
            />
          </div>

          <div class="carousel-caption">
            {{ heroSlides[currentSlide].caption }}
          </div>
        </div>

        <div class="fc fc-1">
          <div class="fc-ico g">
            <AppIcon name="users" :size="16" :stroke-width="2" color="#B8962E" />
          </div>
          <div class="fc-body">
            <span class="fc-title">Gestion des groupes</span>
            <span class="fc-sub">Creer, organiser et assigner</span>
          </div>
          <div class="fc-right-ico">
            <AppIcon name="chevron-down" :size="14" :stroke-width="2" style="transform: rotate(-90deg)" />
          </div>
        </div>

        <div class="fc fc-2">
          <div class="fc-ico gr">
            <AppIcon name="calendar" :size="16" :stroke-width="2" color="#2D7A4A" />
          </div>
          <div class="fc-body">
            <span class="fc-title">Planning partage</span>
            <span class="fc-sub">Voir l'etape actuelle et la suivante</span>
          </div>
          <div class="fc-right-ico">
            <AppIcon name="chevron-down" :size="14" :stroke-width="2" style="transform: rotate(-90deg)" />
          </div>
        </div>
      </div>

      <div class="hero-dots">
        <button
          v-for="(_, i) in heroSlides"
          :key="i"
          type="button"
          class="hdot"
          :class="{ a: currentSlide === i }"
          @click="goTo(i)"
        ></button>
      </div>
    </div>
  </section>
</template>

<script setup>
import { onMounted, onUnmounted, ref } from 'vue'

import { brand } from '@/content/brand'
import { heroProofItems, heroSlides } from '@/features/Home/views/composables/homepage'
import AppIcon from '@/components/AppIcon.vue'

defineEmits(['openModal'])

const currentSlide = ref(0)
let timer

const next = () => {
  currentSlide.value = (currentSlide.value + 1) % heroSlides.length
}

const startTimer = () => {
  timer = setInterval(next, 4500)
}

const stopTimer = () => {
  if (timer) clearInterval(timer)
}

const resetTimer = () => {
  stopTimer()
  startTimer()
}

const goTo = (index) => {
  currentSlide.value = index
  resetTimer()
}

onMounted(startTimer)
onUnmounted(stopTimer)
</script>
