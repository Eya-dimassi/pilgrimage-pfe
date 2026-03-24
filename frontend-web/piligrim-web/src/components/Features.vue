<template>
  <section class="why" id="why">
    <div class="why-header">
      <h2 class="why-h2">
        Parce que gerer<br />un pelerinage<br />ne devrait pas<br />etre <em>si complique</em>
      </h2>
      <div class="why-right-col">
        <p class="why-desc">
          Nous avons vecu le chaos de la gestion Hajj sur Excel et WhatsApp, alors nous avons construit
          une solution plus simple, plus rapide, plus humaine.
        </p>
        <div class="why-stat-row">
          <div class="ws"><span class="ws-val">500<em>+</em></span><span class="ws-lbl">Agences inscrites</span></div>
          <div class="ws"><span class="ws-val">120<em>k</em></span><span class="ws-lbl">Pelerins geres</span></div>
          <div class="ws"><span class="ws-val">99<em>%</em></span><span class="ws-lbl">Satisfaction</span></div>
        </div>
      </div>
    </div>

    <div class="why-grid">
      <div v-for="card in whyCards" :key="card.title" class="wcard">
        <div class="wc-ico">
          <AppIcon :name="card.icon" :size="22" :stroke-width="1.8" color="#B8962E" />
        </div>
        <div class="wc-h">{{ card.title }}</div>
        <p class="wc-p">{{ card.text }}</p>
      </div>
    </div>
  </section>

  <section class="everyone" id="everyone">
    <div class="ev-top">
      <h2 class="ev-h2">Pour chaque agence<br />qui <em>aspire a mieux</em></h2>
      <p class="ev-sub">Que vous geriez 50 ou 5 000 pelerins, {{ brand.name }} s'adapte a votre facon de travailler.</p>
    </div>

    <div class="tab-toggle">
      <button class="tab-btn" :class="{ active: activeTab === 'agence' }" @click="activeTab = 'agence'">Agence · Web</button>
      <button class="tab-btn" :class="{ active: activeTab === 'guide' }" @click="activeTab = 'guide'">Guides · Mobile</button>
    </div>

    <div v-show="activeTab === 'agence'" id="fonctionnalites" class="bento">
      <div class="bc bc-a">
        <div class="bc-tag">Gestion</div>
        <div class="bc-h">Creer un groupe</div>
        <p class="bc-p">Ajoutez des pelerins, assignez un guide, definissez l'itineraire en quelques clics.</p>
        <div class="mini-ui">
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Groupe G-07 — Alger</span><span class="mval">48 pelerins</span></div>
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Groupe G-08 — Oran</span><span class="mval">36 pelerins</span></div>
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Groupe G-09 — Constantine</span><span class="mval">52 pelerins</span></div>
        </div>
        <span class="bc-ghost">G</span>
      </div>

      <div class="bc bc-b">
        <div class="bc-tag">Affectation</div>
        <div class="bc-h">Recruter un guide</div>
        <p class="bc-p">Choisissez parmi vos guides certifies et assignez-les selon leur profil et disponibilite.</p>
        <div class="mini-ui">
          <div class="mcard">
            <AppIcon name="user" :size="14" :stroke-width="2" color="#6B7FD7" />
            <span class="mlabel">Ahmed Benali · ⭐ 4.9</span><span class="mtag blue">Disponible</span>
          </div>
          <div class="mcard">
            <AppIcon name="user" :size="14" :stroke-width="2" color="#6B7FD7" />
            <span class="mlabel">Sara Mekki · ⭐ 5.0</span><span class="mtag gold">Assignee</span>
          </div>
          <div class="mcard">
            <AppIcon name="user" :size="14" :stroke-width="2" color="#6B7FD7" />
            <span class="mlabel">Karim Boudali · ⭐ 4.8</span><span class="mtag green">Actif</span>
          </div>
        </div>
        <span class="bc-ghost">R</span>
      </div>

      <div class="bc bc-c">
        <div class="bc-tag">Communication</div>
        <div class="bc-h">Notifications push</div>
        <p class="bc-p">Envoyez des alertes a tous vos pelerins ou a un groupe specifique en un seul clic.</p>
        <div class="mini-ui">
          <div class="mcard">
            <AppIcon name="alert" :size="15" :stroke-width="2" color="#2D7A4A" />
            <div><div class="mlabel">Rappel — Tawaf 14h00</div><div style="font-size:0.7rem;color:var(--gray2)">1 284 pelerins</div></div>
            <span class="mtag green">Envoye</span>
          </div>
          <div class="mcard">
            <AppIcon name="alert" :size="15" :stroke-width="2" color="#B8962E" />
            <div><div class="mlabel">Alerte meteo — Zone B</div><div style="font-size:0.7rem;color:var(--gray2)">Groupe G-07</div></div>
            <span class="mtag gold">Planifie</span>
          </div>
        </div>
        <span class="bc-ghost">N</span>
      </div>

      <div class="bc bc-d">
        <div class="bc-tag">Analytique</div>
        <div class="bc-h">Tableau de bord</div>
        <p class="bc-p">Visualisez en temps reel les performances, incidents, et satisfaction de vos pelerins.</p>
        <div class="mini-ui">
          <div style="display:flex;gap:0.65rem">
            <div class="mcard" style="flex:1;flex-direction:column;align-items:flex-start;gap:0.1rem"><span class="mlabel" style="font-size:1.1rem;font-family:'Instrument Serif',serif">1 284</span><span style="font-size:0.72rem;color:var(--gray2)">Pelerins actifs</span></div>
            <div class="mcard" style="flex:1;flex-direction:column;align-items:flex-start;gap:0.1rem"><span class="mlabel" style="font-size:1.1rem;font-family:'Instrument Serif',serif">24</span><span style="font-size:0.72rem;color:var(--gray2)">Groupes</span></div>
            <div class="mcard" style="flex:1;flex-direction:column;align-items:flex-start;gap:0.1rem"><span class="mlabel" style="font-size:1.1rem;font-family:'Instrument Serif',serif">98%</span><span style="font-size:0.72rem;color:var(--gray2)">Satisfaction</span></div>
          </div>
        </div>
        <span class="bc-ghost">D</span>
      </div>
    </div>

    <div v-show="activeTab === 'guide'" class="bento">
      <div class="bc bc-c">
        <div class="bc-tag">Mobile · Guides</div>
        <div class="bc-h">Mon groupe</div>
        <p class="bc-p">Accedez a la liste de vos pelerins, leur statut et leurs informations depuis l'app.</p>
        <div class="mini-ui">
          <div class="mcard"><div class="mdot gn"></div><span class="mlabel">Fatima K.</span><span class="mtag green">Presente</span></div>
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Mohamed B.</span><span class="mtag gold">En route</span></div>
          <div class="mcard"><div class="mdot bl"></div><span class="mlabel">Amina R.</span><span class="mtag blue">Chambre 412</span></div>
        </div>
        <span class="bc-ghost">M</span>
      </div>

      <div class="bc bc-a">
        <div class="bc-tag">Localisation</div>
        <div class="bc-h">Carte GPS live</div>
        <p class="bc-p">Voyez la position de chaque pelerin de votre groupe sur la carte en temps reel.</p>
        <div class="mini-ui">
          <div class="mcard">
            <AppIcon name="map-pin" :size="15" :stroke-width="2" color="#B8962E" />
            <div><div class="mlabel">Masjid Al-Haram · Zone A</div><div style="font-size:0.7rem;color:var(--gray2)">Mis a jour: maintenant</div></div>
            <span class="mtag gold">Live</span>
          </div>
        </div>
        <span class="bc-ghost">G</span>
      </div>

      <div class="bc bc-b">
        <div class="bc-tag">Urgence</div>
        <div class="bc-h">Alertes &amp; incidents</div>
        <p class="bc-p">Signalez un incident, declenchez une alerte ou contactez l'agence en un tap.</p>
        <div class="mini-ui">
          <div class="mcard">
            <AppIcon name="alert" :size="15" :stroke-width="2" color="#e53e3e" />
            <span class="mlabel">Signaler un incident</span>
          </div>
          <div class="mcard">
            <AppIcon name="phone" :size="15" :stroke-width="2" color="#6B7FD7" />
            <span class="mlabel">Appeler l'agence</span>
          </div>
        </div>
        <span class="bc-ghost">A</span>
      </div>

      <div class="bc bc-d">
        <div class="bc-tag">Messagerie</div>
        <div class="bc-h">Tous vos messages</div>
        <p class="bc-p">Tous vos echanges avec l'agence et vos pelerins dans une seule boite de reception.</p>
        <div class="mini-ui">
          <div class="mcard">
            <AppIcon name="mail" :size="15" :stroke-width="2" color="#6A6560" />
            <div><div class="mlabel">Agence {{ brand.name }}</div><div style="font-size:0.7rem;color:var(--gray2)">Rendez-vous a 14h a la porte 1</div></div>
            <span class="mval">09:00</span>
          </div>
          <div class="mcard">
            <AppIcon name="mail" :size="15" :stroke-width="2" color="#6A6560" />
            <div><div class="mlabel">Groupe G-07</div><div style="font-size:0.7rem;color:var(--gray2)">Tout le monde est arrive</div></div>
            <span class="mval">08:42</span>
          </div>
        </div>
        <span class="bc-ghost">C</span>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref } from 'vue'
import { brand } from '@/content/brand'
import AppIcon from './AppIcon.vue'

const activeTab = ref('agence')

const whyCards = [
  {
    icon: 'building',
    title: 'Tout en un seul endroit',
    text: "Plus besoin d'Excel, de WhatsApp et de papiers. Groupes, guides, pelerins et documents, tout centralise dans une interface moderne.",
  },
  {
    icon: 'map-pin',
    title: 'Suivi GPS en temps reel',
    text: "Localisez chaque guide et groupe a tout moment. Recevez des alertes si un pelerin s'ecarte de son groupe dans le Haram.",
  },
  {
    icon: 'lock',
    title: 'Securite & conformite',
    text: "Toutes les donnees sont hebergees de facon securisee. Conformite RGPD garantie. Acces controle par agence et par role.",
  },
]
</script>
