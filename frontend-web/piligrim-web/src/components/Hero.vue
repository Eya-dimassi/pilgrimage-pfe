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
          Demander l'acces
        </button>
      </div>

      <div class="hero-proof">
        <div class="avatar-row">
          <div class="av">OPS</div>
          <div class="av">GPS</div>
          <div class="av gold-av">24h</div>
          <div class="av">CRM</div>
        </div>
        <span><b>Agences, guides et familles</b> relies dans une meme interface</span>
      </div>
    </div>

    <div class="hero-right">
      <div class="hero-card">
        <div class="hero-card-img">
          <div class="carousel-wrapper">
            <img
              v-for="(img, i) in slides"
              :key="img.src"
              :src="img.src"
              :alt="img.alt"
              class="carousel-img"
              :class="{ active: currentSlide === i }"
            />
          </div>

          <div class="carousel-caption">
            {{ slides[currentSlide].caption }}
          </div>
        </div>

        <div class="fc fc-1">
          <div class="fc-ico g">
            <AppIcon name="users" :size="16" :stroke-width="2" color="#B8962E" />
          </div>
          <div class="fc-body">
            <span class="fc-title">Gestion des groupes</span>
            <span class="fc-sub">Creer et assigner des pelerins</span>
          </div>
          <div class="fc-right-ico">
            <AppIcon name="chevron-down" :size="14" :stroke-width="2" style="transform: rotate(-90deg)" />
          </div>
        </div>

        <div class="fc fc-2">
          <div class="fc-ico gr">
            <AppIcon name="map-pin" :size="16" :stroke-width="2" color="#2D7A4A" />
          </div>
          <div class="fc-body">
            <span class="fc-title">Suivi GPS en direct</span>
            <span class="fc-sub">Localiser chaque guide en temps reel</span>
          </div>
          <div class="fc-right-ico">
            <AppIcon name="chevron-down" :size="14" :stroke-width="2" style="transform: rotate(-90deg)" />
          </div>
        </div>
      </div>

      <div class="hero-dots">
        <button
          v-for="(_, i) in slides"
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
import AppIcon from './AppIcon.vue'

defineEmits(['openModal'])

const currentSlide = ref(0)
let timer

const slides = [
  {
    src: 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?w=1200&q=80',
    alt: 'Masjid Al-Haram - La Mecque',
    caption: 'Masjid Al-Haram - La Mecque',
  },
  {
    src: 'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=1200&q=80',
    alt: 'La Kaaba',
    caption: 'La Kaaba - Coeur du Hajj',
  },
  {
    src: 'https://images.unsplash.com/photo-1563492065599-3520f775eeed?w=1200&q=80',
    alt: 'Masjid An-Nabawi - Medine',
    caption: 'Masjid An-Nabawi - Medine',
  },
  {
    src: 'https://images.unsplash.com/photo-1590108589108-3600131de843?q=80&w=1200',
    alt: 'Pelerins en priere',
    caption: 'Hajj - Rassemblement mondial',
  },
]

const next = () => {
  currentSlide.value = (currentSlide.value + 1) % slides.length
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
