
Toast · VUE
Copy

<template>
  <Teleport to="body">
    <div class="toast" :class="{ show }">
      <div class="t-ico">✓</div>
      <div>
        <div class="t-title">Demande envoyée !</div>
        <div class="t-sub">Notre équipe vous contactera sous 24h</div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
defineProps(['show'])
</script>