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

import { brand } from '@/content/brand'
import AgencyAccessForm from './AgencyAccessForm.vue'

const openFaq = ref(null)

const toggleFaq = (index) => {
  openFaq.value = openFaq.value === index ? null : index
}

const faqs = [
  {
    q: 'Combien coute la plateforme ?',
    a: "L'acces anticipe est gratuit. Les tarifs seront communiques lors du lancement, avec une periode d'essai offerte a toutes les agences inscrites.",
  },
  {
    q: "L'application mobile est-elle incluse ?",
    a: "Oui. La plateforme web agence et l'app mobile guides sont incluses dans la meme souscription, sans frais supplementaires.",
  },
  {
    q: 'Combien de pelerins puis-je gerer ?',
    a: `${brand.name} s'adapte a votre volume, de 50 a plusieurs milliers de pelerins. Des forfaits par taille d'agence seront disponibles au lancement.`,
  },
  {
    q: 'La plateforme est-elle disponible en arabe ?',
    a: `Oui, ${brand.name} est disponible en francais, arabe et anglais. L'interface et les notifications s'adaptent a la langue de chaque utilisateur.`,
  },
  {
    q: 'Que se passe-t-il apres ma demande ?',
    a: "Notre equipe vous contacte sous 24h pour configurer votre espace agence, vous former et repondre a vos questions.",
  },
]
</script>
