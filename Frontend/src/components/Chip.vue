<script setup>
defineProps({ color: { type: String, default: 'gray' } })

const COLORS = {
  gray: 'bg-neutral-100',
  dark: 'bg-neutral-900 text-white',
  red: 'bg-red-50 text-red-600',
  green: 'bg-green-50 text-green-700',
  outline: 'border border-neutral-900 bg-white',
}
</script>

<template>
  <span class="inline-block rounded-full px-2.5 py-1 text-xs font-medium whitespace-nowrap" :class="COLORS[color]">
    <slot />
  </span>
</template>
