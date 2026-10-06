<script setup>
import { ref, computed } from 'vue'
import { CalendarCheck, ChevronLeft, ChevronRight } from 'lucide-vue-next'
import StatCard from '@/components/StatCard.vue'
import Chip from '@/components/Chip.vue'
import { store } from '@/store'
import { loggedUserId } from '@/session'
import { startOfWeek, addDays, dateKey } from '@/utils/kpi'
import { DAY_NAMES, shiftOf, weekDays, plannedNights, plannedHours } from '@/utils/planning'

const monday = ref(startOfWeek())
const userId = loggedUserId

const days = computed(() => weekDays(monday.value))
const publishedOn = computed(() => store.published[dateKey(monday.value)])

const weekTitle = computed(() => monday.value.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' }))

function card(day, i) {
  const shift = shiftOf(userId.value, day)
  const afterNight = i > 0 ? shiftOf(userId.value, days.value[i - 1]) === 'N' : shiftOf(userId.value, addDays(day, -1)) === 'N'
  const label = `${DAY_NAMES[i]} ${day.getDate()}`
  if (shift === 'J') return { label, hours: '08:00 – 16:00', type: 'Jour', style: 'bg-white' }
  if (shift === 'N') return { label, hours: '22:00 – 06:00', type: 'Nuit', style: 'bg-neutral-900 text-white' }
  if (shift === 'A') return { label, hours: '18:00 – 08:00', type: 'Astreinte', style: 'border-2 border-neutral-900 bg-white' }
  if (shift === 'R' && afterNight) return { label, hours: 'Repos', type: 'Après une nuit', style: 'border-2 border-dashed border-neutral-400 text-neutral-500' }
  return { label, hours: '—', type: 'Repos', style: 'text-neutral-400' }
}

const consecutiveNights = computed(() => {
  const month = dateKey(monday.value).slice(0, 7)
  const nights = Object.entries(store.planning[userId.value] || {})
    .filter(([day, shift]) => shift === 'N' && day.startsWith(month))
    .map(([day]) => day)
    .sort()
  let best = 0
  let run = 0
  nights.forEach((day, i) => {
    run = i > 0 && dateKey(addDays(new Date(`${day}T12:00:00`), -1)) === nights[i - 1] ? run + 1 : 1
    best = Math.max(best, run)
  })
  return best
})

const nightsThisMonth = computed(() => plannedNights(userId.value, dateKey(monday.value).slice(0, 7)))
const dutiesThisWeek = computed(() => days.value.filter(day => shiftOf(userId.value, day) === 'A').length)
const hoursThisWeek = computed(() => plannedHours(userId.value, monday.value))
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-white p-5">
      <div class="flex items-center gap-2 text-sm">
        <button class="rounded-lg p-1 hover:bg-neutral-100" @click="monday = addDays(monday, -7)"><ChevronLeft class="h-4 w-4" /></button>
        <button class="rounded-lg p-1 hover:bg-neutral-100" @click="monday = addDays(monday, 7)"><ChevronRight class="h-4 w-4" /></button>
        <CalendarCheck class="h-4 w-4 shrink-0" />
        Semaine du {{ weekTitle }} ·
        <template v-if="publishedOn">publié le {{ new Date(publishedOn).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' }) }}</template>
        <template v-else>pas encore publié</template>
      </div>
      <div class="flex gap-2">
        <Chip>Jour</Chip>
        <Chip color="dark">Nuit</Chip>
        <Chip color="outline">Astreinte</Chip>
      </div>
    </div>

    <div v-if="publishedOn" class="grid grid-cols-1 gap-3 xl:grid-cols-7">
      <div
        v-for="(day, i) in days"
        :key="dateKey(day)"
        class="flex items-center justify-between rounded-2xl p-4 xl:block xl:min-h-32"
        :class="card(day, i).style"
      >
        <p class="text-sm font-semibold">{{ card(day, i).label }}</p>
        <div class="text-right xl:mt-6 xl:text-left">
          <p class="text-sm font-medium">{{ card(day, i).hours }}</p>
          <p class="text-xs opacity-70">{{ card(day, i).type }}</p>
        </div>
      </div>
    </div>
    <p v-else class="rounded-2xl bg-white p-5 text-sm text-neutral-500">
      Ton manager n'a pas encore publié le planning de cette semaine. Il est publié au moins {{ store.rules.planningNoticeDays }} jours à l'avance.
    </p>

    <div class="stat-grid">
      <StatCard label="Nuits ce mois-ci" :value="`${nightsThisMonth} / ${store.rules.maxNightsPerMonth}`" hint="Plafond fixé par les règles" icon="schedule" />
      <StatCard label="Nuits consécutives" :value="`${consecutiveNights} / ${store.rules.maxConsecutiveNights}`" hint="Maximum autorisé" icon="increase" />
      <StatCard label="Astreintes" :value="dutiesThisWeek" hint="Non comptées en heures sup" icon="monitor" />
      <StatCard label="Heures prévues" :value="`${hoursThisWeek}h`" hint="Cette semaine" icon="timetable" />
    </div>
  </div>
</template>
