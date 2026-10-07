<script setup>
import { ref, computed, watch } from 'vue'
import { CalendarCheck, ChevronLeft, ChevronRight } from 'lucide-vue-next'
import StatCard from '@/components/StatCard.vue'
import Chip from '@/components/Chip.vue'
import { store } from '@/store'
import { logged_user_id } from '@/session'
import { start_of_week, add_days, date_key } from '@/utils/kpi'
import { DAY_NAMES, shift_of, week_days, planned_nights, planned_hours } from '@/utils/planning'

const monday = ref(start_of_week())
const user_id = logged_user_id

const days = computed(() => week_days(monday.value))
const published_on = computed(() => store.published[date_key(monday.value)])

// Semaines publiées par le manager, de la plus proche à la plus lointaine
const published_weeks = computed(() => Object.keys(store.published).sort().map(key => new Date(`${key}T00:00:00`)))
const upcoming_weeks = computed(() => published_weeks.value.filter(week => week >= start_of_week()))

// À l'ouverture : la semaine en cours si elle est publiée, sinon le prochain planning publié
const navigated = ref(false)

function go_to(week)
{
  monday.value = week
  navigated.value = true
}

watch(upcoming_weeks, weeks =>
{
  if (navigated.value || published_on.value || !weeks.length) return
  monday.value = weeks[0]
}, { immediate: true })

const week_label = week => week.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' })

const week_title = computed(() => monday.value.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' }))

function card(day, i)
{
  const shift = shift_of(user_id.value, day)
  const after_night = i > 0 ? shift_of(user_id.value, days.value[i - 1]) === 'N' : shift_of(user_id.value, add_days(day, -1)) === 'N'
  const label = `${DAY_NAMES[i]} ${day.getDate()}`
  if (shift === 'J') return { label, hours: '08:00 - 16:00', type: 'Jour', style: 'bg-white' }
  if (shift === 'N') return { label, hours: '22:00 - 06:00', type: 'Nuit', style: 'bg-neutral-900 text-white' }
  if (shift === 'A') return { label, hours: '18:00 - 08:00', type: 'Astreinte', style: 'border-2 border-neutral-900 bg-white' }
  if (shift === 'R' && after_night) return { label, hours: 'Repos', type: 'Après une nuit', style: 'border-2 border-dashed border-neutral-400 text-neutral-500' }
  return { label, hours: '—', type: 'Repos', style: 'text-neutral-400' }
}

const consecutive_nights = computed(() =>
{
  const month = date_key(monday.value).slice(0, 7)
  const nights = Object.entries(store.planning[user_id.value] || {})
    .filter(([day, shift]) => shift === 'N' && day.startsWith(month))
    .map(([day]) => day)
    .sort()
  let best = 0
  let run = 0
  nights.forEach((day, i) =>
  {
    run = i > 0 && date_key(add_days(new Date(`${day}T12:00:00`), -1)) === nights[i - 1] ? run + 1 : 1
    best = Math.max(best, run)
  })
  return best
})

const nights_this_month = computed(() => planned_nights(user_id.value, date_key(monday.value).slice(0, 7)))
const duties_this_week = computed(() => days.value.filter(day => shift_of(user_id.value, day) === 'A').length)
const hours_this_week = computed(() => planned_hours(user_id.value, monday.value))
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-white p-5">
      <div class="flex items-center gap-2 text-sm">
        <button class="rounded-lg p-1 hover:bg-neutral-100" @click="go_to(add_days(monday, -7))"><ChevronLeft class="h-4 w-4" /></button>
        <button class="rounded-lg p-1 hover:bg-neutral-100" @click="go_to(add_days(monday, 7))"><ChevronRight class="h-4 w-4" /></button>
        <CalendarCheck class="h-4 w-4 shrink-0" />
        Semaine du {{ week_title }} ·
        <template v-if="published_on">publié le {{ new Date(published_on).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' }) }}</template>
        <template v-else>pas encore publié</template>
      </div>
      <div class="flex gap-2">
        <Chip>Jour</Chip>
        <Chip color="dark">Nuit</Chip>
        <Chip color="outline">Astreinte</Chip>
      </div>
    </div>

    <div v-if="published_on" class="grid grid-cols-1 gap-3 xl:grid-cols-7">
      <div
        v-for="(day, i) in days"
        :key="date_key(day)"
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
    <div v-else class="rounded-2xl bg-white p-5 text-sm text-neutral-500">
      <p>Ton manager n'a pas encore publié le planning de cette semaine. Il est publié au moins {{ store.rules.planningNoticeDays }} jours à l'avance.</p>
      <div v-if="upcoming_weeks.length" class="mt-3 flex flex-wrap items-center gap-2">
        <span>Plannings publiés :</span>
        <button
          v-for="week in upcoming_weeks"
          :key="date_key(week)"
          class="rounded-full bg-neutral-900 px-3 py-1 text-xs font-semibold text-white"
          @click="go_to(week)"
        >
          Semaine du {{ week_label(week) }}
        </button>
      </div>
    </div>

    <div class="stat-grid">
      <StatCard label="Nuits ce mois-ci" :value="`${nights_this_month} / ${store.rules.maxNightsPerMonth}`" hint="Plafond fixé par les règles" icon="schedule" />
      <StatCard label="Nuits consécutives" :value="`${consecutive_nights} / ${store.rules.maxConsecutiveNights}`" hint="Maximum autorisé" icon="increase" />
      <StatCard label="Astreintes" :value="duties_this_week" hint="Non comptées en heures sup" icon="monitor" />
      <StatCard label="Heures prévues" :value="`${hours_this_week}h`" hint="Cette semaine" icon="timetable" />
    </div>
  </div>
</template>
