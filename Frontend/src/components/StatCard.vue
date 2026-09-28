<script setup>
defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], required: true },
  hint: { type: String, default: '' },
  icon: { type: [Object, Function], required: true },
})
</script>

<template>
  <div class="rounded-2xl bg-white p-5">
    <div class="mb-4 flex h-9 w-9 items-center justify-center rounded-lg bg-neutral-100 text-neutral-900">
      <component :is="icon" class="h-5 w-5" />
    </div>
    <p class="text-sm text-neutral-500">{{ label }}</p>
    <p class="mt-1 text-3xl font-semibold">{{ value }}</p>
    <p v-if="hint" class="mt-2 text-sm text-neutral-400">{{ hint }}</p>
  </div>
</template>
