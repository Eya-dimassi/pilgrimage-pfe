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
          <div v-for="stat in whyStats" :key="stat.label" class="ws">
            <span class="ws-val">
              {{ stat.value }}<em v-if="stat.suffix">{{ stat.suffix }}</em>
            </span>
            <span class="ws-lbl">{{ stat.label }}</span>
          </div>
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
      <p class="ev-sub">
        Que vous geriez 50 ou 5 000 pelerins, {{ brand.name }} s'adapte a votre facon de travailler.
      </p>
    </div>

    <div class="tab-toggle">
      <button class="tab-btn" :class="{ active: activeTab === 'agence' }" @click="activeTab = 'agence'">
        Agence - Web
      </button>
      <button class="tab-btn" :class="{ active: activeTab === 'guide' }" @click="activeTab = 'guide'">
        Guides - Mobile
      </button>
    </div>

    <div v-show="activeTab === 'agence'" id="fonctionnalites" class="bento">
      <div
        v-for="(card, index) in agenceFeatureCards"
        :key="card.title"
        class="bc"
        :class="[`bc-${String.fromCharCode(97 + index)}`]"
      >
        <div class="bc-tag">{{ card.tag }}</div>
        <div class="bc-h">{{ card.title }}</div>
        <p class="bc-p">{{ card.text }}</p>
        <div class="mini-ui">
          <template v-if="card.stats">
            <div style="display:flex;gap:0.65rem">
              <div
                v-for="stat in card.stats"
                :key="stat.label"
                class="mcard"
                style="flex:1;flex-direction:column;align-items:flex-start;gap:0.1rem"
              >
                <span class="mlabel" style="font-size:1.1rem;font-family:'Instrument Serif',serif">
                  {{ stat.value }}
                </span>
                <span style="font-size:0.72rem;color:var(--gray2)">{{ stat.label }}</span>
              </div>
            </div>
          </template>
          <template v-else>
            <div
              v-for="row in card.mockRows"
              :key="`${card.title}-${row.label}-${row.value ?? row.detail ?? ''}`"
              class="mcard"
            >
              <div v-if="row.dot" class="mdot" :class="row.dot"></div>
              <AppIcon
                v-else-if="row.icon"
                :name="row.icon"
                :size="row.type === 'iconTag' ? 14 : 15"
                :stroke-width="2"
                :color="row.iconColor || '#6A6560'"
              />
              <div v-if="row.detail">
                <div class="mlabel">{{ row.label }}</div>
                <div style="font-size:0.7rem;color:var(--gray2)">{{ row.detail }}</div>
              </div>
              <span v-else class="mlabel">{{ row.label }}</span>
              <span v-if="row.type === 'status' || row.type === 'detailValue'" class="mval">{{ row.value }}</span>
              <span v-else-if="row.value" class="mtag" :class="row.tone">{{ row.value }}</span>
            </div>
          </template>
        </div>
        <span class="bc-ghost">{{ card.ghost }}</span>
      </div>
    </div>

    <div v-show="activeTab === 'guide'" class="bento">
      <div
        v-for="(card, index) in guideFeatureCards"
        :key="card.title"
        class="bc"
        :class="[`bc-${['c', 'a', 'b', 'd'][index]}`]"
      >
        <div class="bc-tag">{{ card.tag }}</div>
        <div class="bc-h">{{ card.title }}</div>
        <p class="bc-p">{{ card.text }}</p>
        <div class="mini-ui">
          <div
            v-for="row in card.mockRows"
            :key="`${card.title}-${row.label}-${row.value ?? row.detail ?? ''}`"
            class="mcard"
          >
            <div v-if="row.dot" class="mdot" :class="row.dot"></div>
            <AppIcon
              v-else-if="row.icon"
              :name="row.icon"
              :size="15"
              :stroke-width="2"
              :color="row.iconColor || '#6A6560'"
            />
            <div v-if="row.detail">
              <div class="mlabel">{{ row.label }}</div>
              <div style="font-size:0.7rem;color:var(--gray2)">{{ row.detail }}</div>
            </div>
            <span v-else class="mlabel">{{ row.label }}</span>
            <span v-if="row.type === 'detailValue'" class="mval">{{ row.value }}</span>
            <span v-else-if="row.value" class="mtag" :class="row.tone">{{ row.value }}</span>
          </div>
        </div>
        <span class="bc-ghost">{{ card.ghost }}</span>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref } from 'vue'

import AppIcon from '@/components/AppIcon.vue'
import { brand } from '@/content/brand'
import {
  agenceFeatureCards,
  guideFeatureCards,
  whyCards,
  whyStats,
} from '@/features/Home/views/composables/homepage'

const activeTab = ref('agence')
</script>
