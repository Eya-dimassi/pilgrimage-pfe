<template>
<nav class="fixed top-0 w-full z-50 bg-black/80 backdrop-blur-md border-b border-white/10">
<div class="max-w-7xl mx-auto px-6 lg:px-8">
<div class="flex justify-between items-center h-20">

<div class="flex items-center gap-3">
<div class="text-2xl">🕌</div>
<span class="text-xl  text-white font-bold">Hajj&Umrah</span>
</div>

<div class="hidden md:flex items-center gap-8">
<a href="#fonctionnalites" class="text-gray-400 hover:text-white transition text-sm">Fonctionnalités</a>
<a href="#avantages" class="text-gray-400 hover:text-white transition text-sm">Avantages</a>
<a href="#contact" class="text-gray-400 hover:text-white transition text-sm">Contact</a>

<button
@click="$emit('openModal')"
class="px-6 py-2.5 btn-primary text-white rounded-lg font-medium text-sm"
>
Demander un Accès
</button>
<a href="login"><button class="px-6 py-2  btn-primary text-white font-medium rounded-lg">
connexion</button></a>

</div>

</div>
</div>
</nav>
</template>