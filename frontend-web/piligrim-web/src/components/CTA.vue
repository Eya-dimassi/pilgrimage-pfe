<template>
  <section class="cta-section">
    <div class="cta-left">
      <h2 class="cta-left-h">Réservez votre accès<br /><em>avant tout le monde</em></h2>
      <p class="cta-left-p">
        Notre équipe configure votre espace en 24h. Aucun engagement, aucune carte bancaire requise pour commencer.
      </p>

      <div class="faq">
        <div
          class="faq-item"
          v-for="(item, i) in faqs"
          :key="i"
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
        <div class="form-card-title">Demander l'accès</div>
        <p class="form-card-sub">Réponse garantie sous 24h · Sans engagement</p>

        <form @submit.prevent="handleSubmit">
          <div class="frow">
            <input class="fi" v-model="form.nomAgence" placeholder="Nom de l'agence" required />
            <input class="fi" v-model="form.telephone" placeholder="Téléphone" required />
          </div>

          <input class="fi fi-full" type="email" v-model="form.email" placeholder="Email professionnel" required />
          <input class="fi fi-full" type="password" v-model="form.motDePasse" placeholder="Mot de passe" required />
          <input class="fi fi-full" v-model="form.adresse" placeholder="Adresse (ville, pays)" />
          <input class="fi fi-full" v-model="form.siteWeb" placeholder="Site web (optionnel)" />

          <div class="radio-opts">
            <label class="ropt">
              <input type="radio" name="use" value="hajj" v-model="form.typeVoyage" />
              <span>Gérer des voyages Hajj</span>
            </label>
            <label class="ropt">
              <input type="radio" name="use" value="umrah" v-model="form.typeVoyage" />
              <span>Gérer des voyages Umrah</span>
            </label>
            <label class="ropt">
              <input type="radio" name="use" value="both" v-model="form.typeVoyage" />
              <span>Les deux — Hajj &amp; Umrah</span>
            </label>
          </div>

          <button type="submit" class="btn-form-submit" :disabled="loading">
            {{ loading ? 'Envoi...' : 'Envoyer ma demande →' }}
          </button>

          <p v-if="error" class="cta-error">{{ error }}</p>
          <p v-if="successMessage" class="cta-success">{{ successMessage }}</p>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref } from 'vue'
import { register } from '@/services/auth.service'

const openFaq = ref(null)
const loading = ref(false)
const error = ref('')
const successMessage = ref('')

const createInitialForm = () => ({
  nomAgence: '',
  telephone: '',
  email: '',
  motDePasse: '',
  adresse: '',
  siteWeb: '',
  typeVoyage: 'both',
})

const form = ref(createInitialForm())

const toggleFaq = (index) => {
  openFaq.value = openFaq.value === index ? null : index
}

const handleSubmit = async () => {
  error.value = ''
  successMessage.value = ''
  loading.value = true

  try {
    await register({
      nomAgence: form.value.nomAgence,
      telephone: form.value.telephone,
      email: form.value.email,
      motDePasse: form.value.motDePasse,
      adresse: form.value.adresse,
      siteWeb: form.value.siteWeb,
    })

    successMessage.value = "Demande envoyée avec succès. Notre équipe vous contactera sous 24h."
    form.value = createInitialForm()
  } catch (err) {
    error.value =
      err?.response?.data?.message || err?.message || "Erreur lors de l'envoi"
  } finally {
    loading.value = false
  }
}

const faqs = [
  {
    q: 'Combien coûte la plateforme ?',
    a: "L'accès anticipé est gratuit. Les tarifs seront communiqués lors du lancement, avec une période d'essai offerte à toutes les agences inscrites.",
  },
  {
    q: "L'application mobile est-elle incluse ?",
    a: "Oui. La plateforme web agence et l'app mobile guides sont incluses dans la même souscription, sans frais supplémentaires.",
  },
  {
    q: 'Combien de pèlerins puis-je gérer ?',
    a: "SmartHajj s'adapte à votre volume — de 50 à plusieurs milliers de pèlerins. Des forfaits par taille d'agence seront disponibles au lancement.",
  },
  {
    q: 'La plateforme est-elle disponible en arabe ?',
    a: "Oui, SmartHajj est disponible en français, arabe et anglais. L'interface et les notifications s'adaptent à la langue de chaque utilisateur.",
  },
  {
    q: 'Que se passe-t-il après ma demande ?',
    a: "Notre équipe vous contacte sous 24h pour configurer votre espace agence, vous former et répondre à vos questions.",
  },
]
</script>

<style scoped>
.cta-error {
  color: #e53e3e;
  font-size: 0.8rem;
  margin-top: 0.75rem;
}

.cta-success {
  color: #2d7a4a;
  font-size: 0.8rem;
  margin-top: 0.75rem;
}
</style>