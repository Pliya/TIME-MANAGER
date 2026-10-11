<script setup>
import Chip from './Chip.vue'

defineProps({
  head: { type: Array, required: true },
  rows: { type: Array, required: true },
})
</script>

<template>
  <div class="overflow-x-auto">
    <table class="w-full min-w-max text-sm">
      <thead>
        <tr class="bg-neutral-50 text-left text-neutral-500">
          <th v-for="title in head" :key="title" class="px-3 py-3 font-medium first:rounded-l-lg last:rounded-r-lg">{{ title }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(row, i) in rows" :key="i" class="border-b border-neutral-100 last:border-0">
          <td v-for="(cell, j) in row" :key="j" class="px-3 py-3" :class="{ 'font-medium': j === 0 }">
            <Chip v-if="cell && cell.chip" :color="cell.color">{{ cell.chip }}</Chip>
            <template v-else>{{ cell }}</template>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
