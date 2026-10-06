<script setup>
import Toggle from '@/components/Toggle.vue'
import { store } from '@/store'

const sections = [
  {
    title: 'Heures supplémentaires',
    rules: [
      ['weekHours', 'Seuil hebdomadaire', 'Au-delà, les heures sont majorées', 'h'],
      ['overtimeRate', 'Majoration', 'Taux appliqué aux heures sup', '×'],
      ['lateCountsAsOvertime', 'Heures tardives', 'Rester tard le soir compte comme heure sup'],
      ['weekendCountsAsOvertime', 'Week-end', 'Le travail du week-end compte comme heure sup'],
      ['dutyNotOvertime', 'Astreinte', 'Non comptée comme heure sup'],
    ],
  },
  {
    title: 'Travail de nuit',
    rules: [
      ['nightStart', 'Début de la nuit', 'Heure à partir de laquelle on compte la nuit', 'h'],
      ['nightEnd', 'Fin de la nuit', 'Heure à laquelle la nuit se termine', 'h'],
      ['nightRate', 'Majoration de nuit', 'Taux appliqué', '×'],
      ['maxConsecutiveNights', 'Nuits consécutives', 'Maximum avant alerte'],
      ['maxNightsPerMonth', 'Nuits par mois', 'Plafond par agent'],
      ['restAfterNight', 'Repos après une nuit', 'Jour de repos imposé'],
    ],
  },
  {
    title: 'Pauses et trajets',
    rules: [
      ['lunchMinutes', 'Pause déjeuner', 'Durée déduite par défaut', 'min'],
      ['workedLunch', 'Pause travaillée', "Non déduite si l'agent la déclare travaillée"],
      ['travelIsWork', 'Trajets entre sites', 'Comptés comme temps de travail'],
      ['mileage', 'Kilométrage', 'Saisie des kilomètres pour les frais'],
    ],
  },
  {
    title: 'Suivi',
    rules: [
      ['minQuota', 'Quota minimum', 'Part du temps à justifier', '%'],
      ['justificationAdjustsQuota', 'Justification acceptée', 'Une période creuse validée ajuste le quota'],
      ['maxReminders', 'Relances', 'Nombre maximum par oubli'],
      ['correctionsUntilValidation', 'Demande de correction', "Possible jusqu'à la validation du mois"],
      ['managerDelayHours', 'Réponse du manager', 'Délai maximum pour décider', 'h'],
      ['refusalNeedsReason', 'Refus motivé', "Motif obligatoire, visible par l'agent"],
      ['planningNoticeDays', 'Planning', 'Délai de publication', 'jours'],
    ],
  },
]
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <div v-for="section in sections" :key="section.title" class="rounded-2xl bg-white p-5">
      <p class="card-title mb-2 font-medium">{{ section.title }}</p>
      <div
        v-for="[key, name, text, unit] in section.rules"
        :key="key"
        class="flex items-center justify-between gap-4 border-b border-neutral-100 py-3 last:border-0"
      >
        <div>
          <p class="text-sm font-medium">{{ name }}</p>
          <p class="text-xs text-neutral-500">{{ text }}</p>
        </div>
        <Toggle v-if="typeof store.rules[key] === 'boolean'" v-model="store.rules[key]" />
        <label v-else class="flex items-center gap-1 rounded-lg border border-neutral-200 px-3 py-1.5 text-sm font-semibold whitespace-nowrap">
          <span v-if="unit === '×'">×</span>
          <input v-model.number="store.rules[key]" type="number" min="0" step="any" class="w-12 text-right outline-none" />
          <span v-if="unit && unit !== '×'">{{ unit }}</span>
        </label>
      </div>
    </div>
  </div>
</template>
