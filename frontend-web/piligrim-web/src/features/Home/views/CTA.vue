<template>
  <section class="cta-section">
    <div class="cta-left">
      <h2 class="cta-left-h">Reservez votre acces<br /><em>avant tout le monde</em></h2>
      <p class="cta-left-p">
        Notre equipe configure votre espace en 24h. Aucun engagement, aucune carte bancaire requise pour commencer.
      </p>

      <div class="faq">
        <div
          v-for="(item, i) in faqs"
          :key="i"
          class="faq-item"
          :class="{ open: openFaq === i }"
        >
          <div class="faq-q" @click="toggleFaq(i)">
            <span>{{ item.q }}</span>
            <span class="faq-plus">+</span>
          </div>
          <div class="faq-a">{{ item.a }}</div>
        </div>
      </div>
    </div>

    <div class="cta-right">
      <div class="form-card">
        <div class="form-card-title">Creer un compte</div>
        <p class="form-card-sub">Reponse garantie sous 24h - Sans engagement</p>

        <AgencyAccessForm />
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref } from 'vue'

import { homepageFaqs } from '@/features/Home/views/composables/homepage'
import AgencyAccessForm from './AgencyAccessForm.vue'

const openFaq = ref(null)

const toggleFaq = (index) => {
  openFaq.value = openFaq.value === index ? null : index
}

const faqs = homepageFaqs
</script>
