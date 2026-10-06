<script setup>
defineProps({ name: { type: String, required: true } })

function logoUrl(name) {
  return new URL(`../assets/logo/${name}.png`, import.meta.url).href
}
</script>

<template>
  <img :src="logoUrl(name)" alt="" />
</template>
