<template>
  <section class="hero">
    <div class="hero-left">
      <div class="hero-pill">
        <span class="pill-dot"></span>
        Accès anticipé ouvert aux agences
      </div>

      <h1 class="hero-h1">
        Gérez.<br />
        <em>Coordonnez.</em><br />
        Guidez, tout<br />en un endroit.
      </h1>

      <p class="hero-sub">
        La plateforme tout-en-un pour les agences Hajj &amp; Umrah — groupes, guides, suivi GPS et documents, centralisés en un seul endroit.
      </p>

      <div class="hero-form">
        <input
          class="hero-input"
          type="email"
          placeholder="Email de votre agence"
        />
        <button class="hero-btn" type="button" @click="$emit('openModal')">
          Demander l'accès
        </button>
      </div>

      <div class="hero-proof">
        <div class="avatar-row">
          <div class="av">AB</div>
          <div class="av">MK</div>
          <div class="av gold-av">SR</div>
          <div class="av">+</div>
        </div>
        <span><b>500+ agences</b> déjà inscrites pour l'accès anticipé</span>
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
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#B8962E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
              <circle cx="9" cy="7" r="4" />
              <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
              <path d="M16 3.13a4 4 0 0 1 0 7.75" />
            </svg>
          </div>
          <div class="fc-body">
            <span class="fc-title">Gestion des groupes</span>
            <span class="fc-sub">Créer &amp; assigner des pèlerins</span>
          </div>
          <div class="fc-right-ico">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
        </div>

        <div class="fc fc-2">
          <div class="fc-ico gr">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2D7A4A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
          </div>
          <div class="fc-body">
            <span class="fc-title">Suivi GPS en direct</span>
            <span class="fc-sub">Localiser chaque guide en temps réel</span>
          </div>
          <div class="fc-right-ico">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="9 18 15 12 9 6" />
            </svg>
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
import { ref, onMounted, onUnmounted } from 'vue'

defineEmits(['openModal'])

const currentSlide = ref(0)
let timer

const slides = [
  {
    src: 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?w=1200&q=80',
    alt: 'Masjid Al-Haram — La Mecque',
    caption: 'Masjid Al-Haram · La Mecque',
  },
  {
    src: 'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=1200&q=80',
    alt: 'La Kaaba',
    caption: 'La Kaaba · Cœur du Hajj',
  },
  {
    src: 'https://images.unsplash.com/photo-1563492065599-3520f775eeed?w=1200&q=80',
    alt: 'Masjid An-Nabawi — Médine',
    caption: 'Masjid An-Nabawi · Médine',
  },
  {
    src: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=1200&q=80',
    alt: 'Pèlerins en prière',
    caption: 'Hajj · Rassemblement mondial',
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