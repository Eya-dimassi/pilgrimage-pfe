<template>
  <!-- WHY SECTION -->
  <section class="why" id="why">
    <div class="why-header">
      <h2 class="why-h2">
        Parce que gérer<br/>un pèlerinage<br/>ne devrait pas<br/>être <em>si compliqué</em>
      </h2>
      <div class="why-right-col">
        <p class="why-desc">
          Nous avons vécu le chaos de la gestion Hajj sur Excel et WhatsApp — alors nous avons construit une solution plus simple, plus rapide, plus humaine.
        </p>
        <div class="why-stat-row">
          <div class="ws"><span class="ws-val">500<em>+</em></span><span class="ws-lbl">Agences inscrites</span></div>
          <div class="ws"><span class="ws-val">120<em>k</em></span><span class="ws-lbl">Pèlerins gérés</span></div>
          <div class="ws"><span class="ws-val">99<em>%</em></span><span class="ws-lbl">Satisfaction</span></div>
        </div>
      </div>
    </div>

    <div class="why-grid">
      <div class="wcard" v-for="card in whyCards" :key="card.title">
        <div class="wc-ico" v-html="card.icon"></div>
        <div class="wc-h">{{ card.title }}</div>
        <p class="wc-p">{{ card.text }}</p>
      </div>
    </div>
  </section>

  <!-- EVERYONE SECTION -->
  <section class="everyone" id="everyone">
    <div class="ev-top">
      <h2 class="ev-h2">Pour chaque agence<br/>qui <em>aspire à mieux</em></h2>
      <p class="ev-sub">Que vous gériez 50 ou 5 000 pèlerins, SmartHajj s'adapte à votre façon de travailler.</p>
    </div>

    <div class="tab-toggle">
      <button class="tab-btn" :class="{ active: activeTab === 'agence' }" @click="activeTab = 'agence'">Agence · Web</button>
      <button class="tab-btn" :class="{ active: activeTab === 'guide' }" @click="activeTab = 'guide'">Guides · Mobile</button>
    </div>

    <!-- Agence tab -->
    <div class="bento" v-show="activeTab === 'agence'" id="fonctionnalites">
      <div class="bc bc-a">
        <div class="bc-tag">Gestion</div>
        <div class="bc-h">Créer un groupe</div>
        <p class="bc-p">Ajoutez des pèlerins, assignez un guide, définissez l'itinéraire en quelques clics.</p>
        <div class="mini-ui">
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Groupe G-07 — Alger</span><span class="mval">48 pèlerins</span></div>
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Groupe G-08 — Oran</span><span class="mval">36 pèlerins</span></div>
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Groupe G-09 — Constantine</span><span class="mval">52 pèlerins</span></div>
        </div>
        <span class="bc-ghost">G</span>
      </div>

      <div class="bc bc-b">
        <div class="bc-tag">Affectation</div>
        <div class="bc-h">Recruter un guide</div>
        <p class="bc-p">Choisissez parmi vos guides certifiés et assignez-les selon leur profil et disponibilité.</p>
        <div class="mini-ui">
          <div class="mcard">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6B7FD7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
            <span class="mlabel">Ahmed Benali · ⭐ 4.9</span><span class="mtag blue">Disponible</span>
          </div>
          <div class="mcard">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6B7FD7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
            <span class="mlabel">Sara Mekki · ⭐ 5.0</span><span class="mtag gold">Assignée</span>
          </div>
          <div class="mcard">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#6B7FD7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
            <span class="mlabel">Karim Boudali · ⭐ 4.8</span><span class="mtag green">Actif</span>
          </div>
        </div>
        <span class="bc-ghost">R</span>
      </div>

      <div class="bc bc-c">
        <div class="bc-tag">Communication</div>
        <div class="bc-h">Notifications push</div>
        <p class="bc-p">Envoyez des alertes à tous vos pèlerins ou à un groupe spécifique en un seul clic.</p>
        <div class="mini-ui">
          <div class="mcard">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2D7A4A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
            <div><div class="mlabel">Rappel — Tawaf 14h00</div><div style="font-size:0.7rem;color:var(--gray2)">1 284 pèlerins</div></div>
            <span class="mtag green">Envoyé ✓</span>
          </div>
          <div class="mcard">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#B8962E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
            <div><div class="mlabel">Alerte météo — Zone B</div><div style="font-size:0.7rem;color:var(--gray2)">Groupe G-07</div></div>
            <span class="mtag gold">Planifié</span>
          </div>
        </div>
        <span class="bc-ghost">N</span>
      </div>

      <div class="bc bc-d">
        <div class="bc-tag">Analytique</div>
        <div class="bc-h">Tableau de bord</div>
        <p class="bc-p">Visualisez en temps réel les performances, incidents, et satisfaction de vos pèlerins.</p>
        <div class="mini-ui">
          <div style="display:flex;gap:0.65rem">
            <div class="mcard" style="flex:1;flex-direction:column;align-items:flex-start;gap:0.1rem"><span class="mlabel" style="font-size:1.1rem;font-family:'Instrument Serif',serif">1 284</span><span style="font-size:0.72rem;color:var(--gray2)">Pèlerins actifs</span></div>
            <div class="mcard" style="flex:1;flex-direction:column;align-items:flex-start;gap:0.1rem"><span class="mlabel" style="font-size:1.1rem;font-family:'Instrument Serif',serif">24</span><span style="font-size:0.72rem;color:var(--gray2)">Groupes</span></div>
            <div class="mcard" style="flex:1;flex-direction:column;align-items:flex-start;gap:0.1rem"><span class="mlabel" style="font-size:1.1rem;font-family:'Instrument Serif',serif">98%</span><span style="font-size:0.72rem;color:var(--gray2)">Satisfaction</span></div>
          </div>
        </div>
        <span class="bc-ghost">D</span>
      </div>
    </div>

    <!-- Guide tab -->
    <div class="bento" v-show="activeTab === 'guide'">
      <div class="bc bc-c">
        <div class="bc-tag">Mobile · Guides</div>
        <div class="bc-h">Mon groupe</div>
        <p class="bc-p">Accédez à la liste de vos pèlerins, leur statut et leurs informations depuis l'app.</p>
        <div class="mini-ui">
          <div class="mcard"><div class="mdot gn"></div><span class="mlabel">Fatima K.</span><span class="mtag green">Présente</span></div>
          <div class="mcard"><div class="mdot go"></div><span class="mlabel">Mohamed B.</span><span class="mtag gold">En route</span></div>
          <div class="mcard"><div class="mdot bl"></div><span class="mlabel">Amina R.</span><span class="mtag blue">Chambre 412</span></div>
        </div>
        <span class="bc-ghost">M</span>
      </div>
      <div class="bc bc-a">
        <div class="bc-tag">Localisation</div>
        <div class="bc-h">Carte GPS live</div>
        <p class="bc-p">Voyez la position de chaque pèlerin de votre groupe sur la carte en temps réel.</p>
        <div class="mini-ui">
          <div class="mcard">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#B8962E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
            <div><div class="mlabel">Masjid Al-Haram · Zone A</div><div style="font-size:0.7rem;color:var(--gray2)">Mis à jour: maintenant</div></div>
            <span class="mtag gold">Live</span>
          </div>
        </div>
        <span class="bc-ghost">G</span>
      </div>
      <div class="bc bc-b">
        <div class="bc-tag">Urgence</div>
        <div class="bc-h">Alertes &amp; incidents</div>
        <p class="bc-p">Signalez un incident, déclenchez une alerte ou contactez l'agence en un tap.</p>
        <div class="mini-ui">
          <div class="mcard">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#e53e3e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span class="mlabel">Signaler un incident</span>
          </div>
          <div class="mcard">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#6B7FD7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.38 2 2 0 0 1 3.58 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.96a16 16 0 0 0 6.29 6.29l1.42-1.42a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
            <span class="mlabel">Appeler l'agence</span>
          </div>
        </div>
        <span class="bc-ghost">A</span>
      </div>
      <div class="bc bc-d">
        <div class="bc-tag">Messagerie</div>
        <div class="bc-h">Tous vos messages</div>
        <p class="bc-p">Tous vos échanges avec l'agence et vos pèlerins dans une seule boîte de réception.</p>
        <div class="mini-ui">
          <div class="mcard">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#6A6560" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
            <div><div class="mlabel">Agence SmartHajj</div><div style="font-size:0.7rem;color:var(--gray2)">Rendez-vous à 14h à la porte 1</div></div>
            <span class="mval">09:00</span>
          </div>
          <div class="mcard">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#6A6560" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
            <div><div class="mlabel">Groupe G-07</div><div style="font-size:0.7rem;color:var(--gray2)">Tout le monde est arrivé</div></div>
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

const activeTab = ref('agence')

const whyCards = [
  {
    icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B8962E" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 17h3m0 0h3m-3 0v-3m0 3v3"/></svg>`,
    title: 'Tout en un seul endroit',
    text: "Plus besoin d'Excel, de WhatsApp et de papiers. Groupes, guides, pèlerins et documents — tout centralisé dans une interface moderne."
  },
  {
    icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B8962E" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>`,
    title: 'Suivi GPS en temps réel',
    text: "Localisez chaque guide et groupe à tout moment. Recevez des alertes si un pèlerin s'écarte de son groupe dans le Haram."
  },
  {
    icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#B8962E" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>`,
    title: 'Sécurité & conformité',
    text: "Toutes les données sont hébergées de façon sécurisée. Conformité RGPD garantie. Accès contrôlé par agence et par rôle."
  },
]
</script>