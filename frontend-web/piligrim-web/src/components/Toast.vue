<template>

<div
v-if="show"
class="fixed bottom-8 right-8 bg-green-500 text-white px-6 py-4 rounded-xl"
>
Demande envoyée !
</div>

</template>

<script>
export default{
props:["show"]
}
</script>