<script setup>
const on = defineModel({ type: Boolean, default: false })
</script>

<template>
  <button
    type="button"
    class="inline-flex h-5 w-9 shrink-0 items-center rounded-full px-0.5"
    :class="on ? 'justify-end bg-neutral-900' : 'justify-start bg-neutral-300'"
    @click="on = !on"
  >
    <span class="h-4 w-4 rounded-full bg-white"></span>
  </button>
</template>
