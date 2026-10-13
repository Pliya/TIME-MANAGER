<script setup>
defineProps({ name: { type: String, required: true } })

function logo_url(name)
{
  return new URL(`../assets/logo/${name}.png`, import.meta.url).href
}
</script>

<template>
  <img :src="logo_url(name)" alt="" />
</template>
