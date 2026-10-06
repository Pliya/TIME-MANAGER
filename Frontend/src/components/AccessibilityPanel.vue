<script setup>
import { Accessibility, Contrast, AArrowUp, Volume2 } from 'lucide-vue-next'
import { accessibility, speak } from '@/accessibility'

const OPTIONS = [
  { key: 'contrast', label: 'Contraste élevé', icon: Contrast },
  { key: 'largeText', label: 'Texte A+', icon: AArrowUp },
  { key: 'voice', label: 'Lecture vocale', icon: Volume2 },
]

function toggle(option) {
  accessibility[option.key] = !accessibility[option.key]
  if (option.key === 'voice') speak(accessibility.voice ? 'Lecture vocale activée' : 'Lecture vocale désactivée')
}
</script>

<template>
  <div class="rounded-2xl border-2 border-neutral-900 bg-white p-4">
    <p class="flex items-center gap-2 text-sm font-semibold">
      <Accessibility class="h-4 w-4" /> Accessibilité
    </p>
    <div class="mt-3 grid grid-cols-3 gap-2 text-center text-[11px] leading-tight">
      <button
        v-for="option in OPTIONS"
        :key="option.key"
        type="button"
        :aria-pressed="accessibility[option.key]"
        class="flex flex-col items-center gap-1.5 rounded-xl px-1 py-2.5 font-medium transition"
        :class="accessibility[option.key] ? 'bg-neutral-900 text-white' : 'bg-neutral-100 hover:bg-neutral-200'"
        @click="toggle(option)"
      >
        <component :is="option.icon" class="h-4 w-4" />
        {{ option.label }}
      </button>
    </div>
  </div>
</template>
