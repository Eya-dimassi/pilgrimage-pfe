<template>
<section class="relative min-h-screen flex items-center justify-center pt-20">

<div class="max-w-5xl mx-auto px-6 text-center">
  <div class="mb-12 flex justify-center">
                <div class="w-40 h-40 glow-icon">
                    <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
                        <defs>
                            <linearGradient id="iconGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                                <stop offset="0%" style="stop-color:#D4AF37;stop-opacity:1" />
                                <stop offset="50%" style="stop-color:#FFD700;stop-opacity:1" />
                                <stop offset="100%" style="stop-color:#D4AF37;stop-opacity:1" />
                            </linearGradient>
                        </defs>
                        <rect x="40" y="40" width="120" height="120" rx="30" fill="url(#iconGradient)"/>
                        <text x="100" y="125" font-size="80" text-anchor="middle" fill="white">🕌</text>
                    </svg>
                </div>
            </div>

<h1 class="text-6xl text-white md:text-7xl font-bold mb-6">
Gérez vos pèlerins.
</h1>

<h2 class="text-5xl  text-white md:text-6xl font-bold  mb-8">
En toute simplicité.
</h2>

<p class="text-xl text-gray-400 max-w-3xl mx-auto mb-12">
La plateforme intelligente qui transforme la gestion de votre agence Hajj & Umrah.
</p>

<button
@click="$emit('openModal')"
class="px-10 py-5 btn-primary text-white rounded-xl font-bold text-lg"
>
Demander un Accès
</button>

<div class="section-line mx-auto"></div>

            <!-- Description -->
            <div class="mt-20 max-w-3xl mx-auto">
                <p class="text-gray-400 text-lg leading-relaxed">
                    SmartHajj est la solution complète pour les agences qui souhaitent digitaliser leur gestion. 
                    De la création des groupes au suivi GPS en temps réel, tout est centralisé dans une interface moderne et intuitive. 
                    Plus besoin d'Excel ou de paperasse : gérez vos pèlerins,groupes et guides en quelques clics.
                </p>
            </div>
        </div>
</section>
</template>