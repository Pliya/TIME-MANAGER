<script setup>
import { ref, computed, watch } from 'vue'
import { Clock, CalendarCheck, TrendingUp, History } from 'lucide-vue-next'
import api from '@/api'
import StatCard from './StatCard.vue'
import ChartInterface from './ChartInterface.vue'
import { DARK, chartOptions } from '@/utils/charts'
import {
  WEEK_DAYS, workingTimesToSessions, summarize, localDateKey, formatTime,
  formatDuration, formatDecimalHours, hoursBetween, weekdayIndex, startOfWeek,
} from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const HEATMAP_SLOTS = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]

const sessions = ref([])
const error = ref('')

async function loadSessions() {
  try {
    const { data } = await api.get(`/workingtime/${props.userId}`)
    sessions.value = workingTimesToSessions(data.data)
    error.value = ''
  } catch {
    sessions.value = []
    error.value = 'Impossible de charger les temps de travail.'
  }
}

watch(() => props.userId, loadSessions, { immediate: true })

const weekSessions = computed(() => sessions.value.filter(s => s.start >= startOfWeek()))

const stats = computed(() => summarize(weekSessions.value))

const lastSession = computed(() => sessions.value.at(-1))

const weekHours = computed(() => {
  const hours = [0, 0, 0, 0, 0, 0, 0]
  weekSessions.value.forEach(s => { hours[weekdayIndex(s.start)] += hoursBetween(s.start, s.end) })
  const today = weekdayIndex(new Date())
  return hours.map((h, day) => (day <= today ? Number(h.toFixed(1)) : null))
})

const weekTotal = computed(() => formatDecimalHours(weekHours.value.reduce((a, b) => a + b, 0)))

const weekChart = computed(() => ({
  labels: WEEK_DAYS,
  datasets: [{
    label: 'Heures',
    data: weekHours.value,
    borderColor: DARK,
    backgroundColor: DARK,
    borderWidth: 3,
    tension: 0.35,
    pointRadius: 4,
  }],
}))

const heatmap = computed(() => {
  const counts = HEATMAP_SLOTS.map(() => [0, 0, 0, 0, 0, 0, 0])
  sessions.value.forEach(s => { counts[Math.floor(s.start.getHours() / 2)][weekdayIndex(s.start)]++ })
  return counts
})

const peakSlot = computed(() => {
  const totals = heatmap.value.map(row => row.reduce((a, b) => a + b, 0))
  const max = Math.max(...totals)
  const slot = HEATMAP_SLOTS[totals.indexOf(max)]
  return max ? `${slot}h - ${slot + 2}h` : '--'
})

function heatColor(count) {
  if (count >= 3) return 'bg-neutral-900'
  if (count === 2) return 'bg-neutral-500'
  if (count === 1) return 'bg-neutral-300'
  return 'bg-neutral-100'
}

const recentSessions = computed(() => {
  const list = sessions.value.slice(-6).reverse()
  const longest = Math.max(1, ...list.map(s => s.end - s.start))
  return list.map(s => ({
    id: s.id,
    date: localDateKey(s.start),
    start: formatTime(s.start),
    end: formatTime(s.end),
    duration: formatDuration(s.end - s.start),
    percent: Math.round(((s.end - s.start) / longest) * 100),
  }))
})
</script>

<template>
  <div class="space-y-6">
    <p v-if="error" class="rounded-xl bg-red-50 px-3 py-3 sm:px-4 text-sm text-red-600">{{ error }}</p>

    <div class="grid grid-cols-2 gap-4 lg:gap-6 xl:grid-cols-4">
      <StatCard label="Heures cette semaine" :value="stats.total" hint="Depuis lundi" :icon="Clock" />
      <StatCard label="Jours travaillés" :value="stats.days" hint="Cette semaine" :icon="CalendarCheck" />
      <StatCard label="Moyenne par jour" :value="stats.average" hint="Cette semaine" :icon="TrendingUp" />
      <StatCard
        label="Dernière session"
        :value="lastSession ? formatTime(lastSession.end) : '--:--'"
        :hint="lastSession ? localDateKey(lastSession.end) : 'Aucune session'"
        :icon="History"
      />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="font-medium">Heures de la semaine</p>
        <p class="mt-4 text-3xl font-semibold">{{ weekTotal }}</p>
        <p class="text-sm text-neutral-400">travaillées depuis lundi</p>
        <div class="mt-6 h-64">
          <ChartInterface type="line" :chart-data="weekChart" :chart-options="chartOptions({ suffix: 'h', max: 24, stepSize: 4, formatValue: formatDecimalHours })" />
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6">
        <p class="font-medium">Heures d'arrivée</p>
        <p class="mt-4 text-3xl font-semibold">{{ peakSlot }}</p>
        <p class="text-sm text-neutral-400">créneau d'arrivée le plus fréquent</p>
        <div class="mt-6 grid grid-cols-[2.5rem_repeat(7,1fr)] gap-1 text-xs text-neutral-400">
          <template v-for="(row, index) in heatmap" :key="index">
            <span class="flex items-center">{{ HEATMAP_SLOTS[index] }}h</span>
            <div v-for="(count, day) in row" :key="day" class="h-5 rounded" :class="heatColor(count)"></div>
          </template>
          <span></span>
          <span v-for="day in WEEK_DAYS" :key="day" class="text-center">{{ day }}</span>
        </div>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-6">
      <div class="mb-4 flex items-center justify-between">
        <p class="font-medium">Sessions récentes</p>
        <router-link to="/workingTimes" class="text-sm font-medium text-neutral-900 hover:underline">Voir tout</router-link>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 sm:px-4 font-medium">Date</th>
              <th class="px-3 py-3 sm:px-4 font-medium">Arrivée</th>
              <th class="px-3 py-3 sm:px-4 font-medium">Départ</th>
              <th class="rounded-r-lg px-3 py-3 sm:px-4 font-medium">Durée</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="session in recentSessions" :key="session.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 sm:px-4 font-medium">{{ session.date }}</td>
              <td class="px-3 py-3 sm:px-4">{{ session.start }}</td>
              <td class="px-3 py-3 sm:px-4">{{ session.end }}</td>
              <td class="px-3 py-3 sm:px-4">
                <div class="flex items-center gap-3">
                  <div class="hidden h-2 w-32 rounded-full bg-neutral-200 sm:block">
                    <div class="h-2 rounded-full bg-neutral-900" :style="{ width: `${session.percent}%` }"></div>
                  </div>
                  <span>{{ session.duration }}</span>
                </div>
              </td>
            </tr>
            <tr v-if="recentSessions.length === 0">
              <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune session enregistrée.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
