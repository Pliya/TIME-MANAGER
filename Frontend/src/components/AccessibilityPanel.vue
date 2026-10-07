<script setup>
import { Accessibility, Contrast, AArrowUp, Volume2 } from 'lucide-vue-next'
import { accessibility, speak } from '@/accessibility'

defineProps({ large: Boolean })

const OPTIONS = [
  { key: 'contrast', label: 'Contraste élevé', icon: Contrast },
  { key: 'largeText', label: 'Texte A+', icon: AArrowUp },
  { key: 'voice', label: 'Lecture vocale', icon: Volume2 },
]

function toggle(option)
{
  accessibility[option.key] = !accessibility[option.key]
  if (option.key === 'voice') speak(accessibility.voice ? 'Lecture vocale activée' : 'Lecture vocale désactivée')
}
</script>

<template>
  <div class="rounded-2xl border-2 border-neutral-900 bg-white" :class="large ? 'p-5' : 'p-4'">
    <p class="flex items-center gap-2 font-semibold" :class="large ? 'text-base' : 'text-sm'">
      <Accessibility :class="large ? 'h-5 w-5' : 'h-4 w-4'" /> Accessibilité
    </p>
    <div class="mt-3 grid grid-cols-3 gap-2 text-center leading-tight" :class="large ? 'text-sm' : 'text-[11px]'">
      <button
        v-for="option in OPTIONS"
        :key="option.key"
        type="button"
        :aria-pressed="accessibility[option.key]"
        class="flex flex-col items-center gap-1.5 rounded-xl px-1 font-medium transition"
        :class="[accessibility[option.key] ? 'bg-neutral-900 text-white' : 'bg-neutral-100 hover:bg-neutral-200', large ? 'py-4' : 'py-2.5']"
        @click="toggle(option)"
      >
        <component :is="option.icon" :class="large ? 'h-6 w-6' : 'h-4 w-4'" />
        {{ option.label }}
      </button>
    </div>
  </div>
</template>
