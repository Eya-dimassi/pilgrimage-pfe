<template>

<Navbar @openModal="openModal"/>

<Hero @openModal="openModal"/>

<Features/>

<CTA @openModal="openModal"/>

<Footer/>

<Modal
:show="modal"
@close="modal=false"
@success="showToast"
/>

<Toast :show="toast"/>

</template>

<script>

import Navbar from "../components/Navbar.vue"
import Hero from "../components/Hero.vue"
import Features from "../components/Features.vue"
import CTA from "../components/CTA.vue"
import Footer from "../components/Footer.vue"
import Modal from "../components/Modal.vue"
import Toast from "../components/Toast.vue"

export default{

components:{
Navbar,
Hero,
Features,
CTA,
Footer,
Modal,
Toast
},

data(){
return{
modal:false,
toast:false
}
},

methods:{
openModal(){
this.modal=true
},

showToast(){
this.toast=true
setTimeout(()=> this.toast=false ,3000)
}

}

}

</script>