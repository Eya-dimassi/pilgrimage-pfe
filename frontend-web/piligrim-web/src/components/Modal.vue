<template>

<div v-if="show" class="fixed inset-0 bg-black/80 flex items-center justify-center">

<div class="bg-black rounded-2xl p-8 max-w-xl w-full">

<h2 class="text-3xl font-bold text-white">Demande d'Accès</h2>
<p class="text-gray-400 mt-1">Notre équipe vous contactera sous 24h</p>
                

<form @submit.prevent="submit">

<!-- nom agence -->
<input
v-model="form.nomAgence"
placeholder="Nom de l'agence"
class="w-full mb-4 p-3 bg-white border border-gray-700 rounded"
/>

<!-- email -->
<input
v-model="form.email"
type="email"
placeholder="Email"
class="w-full mb-4 p-3 bg-white border border-gray-700 rounded"
/>

<!-- mot de passe -->
<input
v-model="form.motDePasse"
type="password"
placeholder="Mot de passe"
class="w-full mb-4 p-3 bg-white border border-gray-700 rounded"
/>

<!-- adresse -->
<input
v-model="form.adresse"
placeholder="Adresse"
class="w-full mb-4 p-3 bg-white border border-gray-700 rounded"
/>

<!-- telephone -->
<input
v-model="form.telephone"
placeholder="Téléphone"
class="w-full mb-4 p-3 bg-white border border-gray-700 rounded"
/>

<!-- site web -->
<input
v-model="form.siteWeb"
placeholder="Site Web"
class="w-full mb-6 p-3 bg-white border border-gray-700 rounded"
/>

<div class="flex gap-4">

<button
type="button"
@click="$emit('close')"
class="flex-1 bg-gray-700 py-3 rounded"
>
Annuler
</button>

<button
type="submit"
class="flex-1 bg-yellow-400 py-3 rounded text-white"
>
Demander
</button>

</div>

</form>

</div>

</div>

</template>

<script>
export default {

props:["show"],

data(){
return{

form:{
nomAgence:"",
email:"",
motDePasse:"",
adresse:"",
telephone:"",
siteWeb:""
}

}
},

methods:{

submit(){

// envoyer les données au parent
this.$emit("submit", this.form)

this.$emit("success")
this.$emit("close")

}

}

}
</script>