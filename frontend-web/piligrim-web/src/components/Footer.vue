<template>
  <footer class="footer" id="contact">
    <div class="footer-top">
      <div>
        <a class="f-brand-logo" href="#">
          <BrandIdentity :size="42" :caption="brand.tagline" />
        </a>
        <p class="f-tagline">{{ brand.tagline }}</p>
        <div class="f-socials">
          <a class="fsoc" href="#">f</a>
          <a class="fsoc" href="#">in</a>
          <a class="fsoc" href="#">X</a>
          <a class="fsoc" href="#">@</a>
        </div>
      </div>
      <div class="footer-cols">
        <div>
          <div class="fc-h">Produit</div>
          <ul class="fc-ul">
            <li><a href="#">Tarifs</a></li>
            <li><a href="#">Entreprise</a></li>
            <li><a href="#">Integrations</a></li>
            <li><a href="#">Nouveautes</a></li>
          </ul>
        </div>
        <div>
          <div class="fc-h">Cas d'usage</div>
          <ul class="fc-ul">
            <li><a href="#">Gestion Hajj</a></li>
            <li><a href="#">Gestion Umrah</a></li>
            <li><a href="#">Groupes &amp; Guides</a></li>
            <li><a href="#">Suivi pelerins</a></li>
          </ul>
        </div>
        <div>
          <div class="fc-h">Ressources</div>
          <ul class="fc-ul">
            <li><a href="#">Blog</a></li>
            <li><a href="#">Centre d'aide</a></li>
            <li><a href="#">Guide de demarrage</a></li>
            <li><a href="#">API Docs</a></li>
          </ul>
        </div>
        <div>
          <div class="fc-h">Entreprise</div>
          <ul class="fc-ul">
            <li><a href="#">A propos</a></li>
            <li><a href="#">Carrieres</a></li>
            <li><a href="#">Contact</a></li>
            <li><a href="#">Presse</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="footer-bot">
      <span class="f-copy">{{ brand.footerCopy }}</span>
      <div class="f-legal">
        <a href="#">CGU</a>
        <a href="#">Confidentialite</a>
        <a href="#">Securite</a>
      </div>
    </div>
  </footer>
</template>

<script setup>
import { brand } from '@/content/brand'
import BrandIdentity from './BrandIdentity.vue'
</script>
