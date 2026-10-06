<script setup>
import LogoIcon from './LogoIcon.vue'

defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], required: true },
  hint: { type: String, default: '' },
  icon: { type: String, required: true },
})
</script>

<template>
  <div class="overflow-hidden rounded-2xl bg-white">
    <div class="flex items-center justify-between gap-2 bg-brand px-4 py-2.5 text-xs font-semibold tracking-wide text-white uppercase sm:px-5 sm:text-sm">
      <span class="truncate">{{ label }}</span>
      <LogoIcon :name="icon" class="h-5 w-5 shrink-0 invert" />
    </div>
    <div class="p-4 sm:p-5">
      <p class="text-2xl font-bold text-neutral-900 sm:text-4xl">{{ value }}</p>
      <p v-if="hint" class="mt-1 text-xs text-neutral-400 sm:text-sm">{{ hint }}</p>
    </div>
  </div>
</template>
