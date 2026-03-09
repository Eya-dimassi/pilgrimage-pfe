<template>

<section id="fonctionnalites" class="py-32">

<div class="max-w-7xl mx-auto px-6 lg:px-8">

<h2 class="text-5xl font-bold text-center mb-20">Fonctionnalités</h2>

<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">

<div class="feature-card rounded-2xl p-8" v-for="feature in features" :key="feature.title">

<div class="text-5xl mb-6">{{feature.icon}}</div>

<h3 class="text-2xl text-yellow-500 font-bold mb-4">{{feature.title}}</h3>

<p class="text-gray-400">{{feature.text}}</p>

</div>

</div>

</div>

</section>

</template>

<script>
export default {

data(){
return{

features:[

{
title:"Gestion des Pèlerins",
text:"Centralisez toutes les informations de vos pèlerins."
},

{
title:"Organisation des Groupes",
text:"Créez et gérez vos groupes facilement."
},

{

title:"Planning Automatisé",
text:"Planning automatique des étapes du Hajj."
},

{

title:"Suivi GPS",
text:"Localisez vos pèlerins en temps réel."
},

{

title:"Système d'Alertes",
text:"Alertes automatiques importantes."
},

{
title:"Dashboard Analytics",
text:"Statistiques en temps réel."
}

]

}

}

}
</script>