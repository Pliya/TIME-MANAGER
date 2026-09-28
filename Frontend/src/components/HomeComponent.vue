<script setup>
import { ref, computed, watch } from 'vue'
import { Clock, CalendarCheck, TrendingUp, History } from 'lucide-vue-next'
import api from '@/api'
import StatCard from './StatCard.vue'
import ChartInterface from './ChartInterface.vue'
import { VIOLET, chartOptions } from '@/utils/charts'
import {
  WEEK_DAYS, clocksToSessions, workingTimesToSessions, localDateKey, formatTime,
  formatDuration, hoursBetween, weekdayIndex, startOfWeek, toDate,
} from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const clocks = ref([])
const workingTimes = ref([])

const HEATMAP_HOURS = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]

async function loadData() {
  const [clocksRes, workingTimesRes] = await Promise.all([
    api.get(`/clocks/${props.userId}`).catch(() => ({ data: { data: [] } })),
    api.get(`/workingtime/${props.userId}`).catch(() => ({ data: { data: [] } })),
  ])
  clocks.value = clocksRes.data.data
  workingTimes.value = workingTimesRes.data.data
}

watch(() => props.userId, loadData, { immediate: true })

const sessions = computed(() => workingTimesToSessions(workingTimes.value))
const clockSessions = computed(() => clocksToSessions(clocks.value))

const stats = computed(() => {
  const totalMs = sessions.value.reduce((sum, s) => sum + (s.end - s.start), 0)
  const days = new Set(sessions.value.map(s => localDateKey(s.start))).size
  const last = sessions.value.at(-1)
  return {
    total: formatDuration(totalMs),
    days,
    average: formatDuration(days ? totalMs / days : 0),
    last: last ? formatTime(last.end) : '--:--',
    lastDate: last ? localDateKey(last.end) : 'Aucune session',
  }
})

const weekHours = computed(() => {
  const hours = [0, 0, 0, 0, 0, 0, 0]
  const monday = startOfWeek()
  sessions.value
    .filter(s => s.start >= monday)
    .forEach(s => { hours[weekdayIndex(s.start)] += hoursBetween(s.start, s.end) })
  const today = weekdayIndex(new Date())
  return hours.map((h, day) => (day <= today ? Number(h.toFixed(1)) : null))
})

const weekTotal = computed(() => weekHours.value.reduce((a, b) => a + b, 0).toFixed(1))

const weekChart = computed(() => ({
  labels: WEEK_DAYS,
  datasets: [{
    label: 'Heures',
    data: weekHours.value,
    borderColor: VIOLET,
    backgroundColor: VIOLET,
    borderWidth: 3,
    tension: 0.35,
    pointRadius: 4,
    pointHoverRadius: 6,
  }],
}))

const heatmap = computed(() => {
  const counts = HEATMAP_HOURS.map(() => [0, 0, 0, 0, 0, 0, 0])
  clocks.value.filter(c => c.status).forEach(c => {
    const date = toDate(c.time)
    const row = HEATMAP_HOURS.indexOf(date.getHours())
    if (row !== -1) counts[row][weekdayIndex(date)]++
  })
  return counts
})

const peakHour = computed(() => {
  const totals = heatmap.value.map(row => row.reduce((a, b) => a + b, 0))
  const max = Math.max(...totals)
  return max ? `${HEATMAP_HOURS[totals.indexOf(max)]}h` : '--'
})

function heatColor(count) {
  if (count >= 3) return 'bg-violet-500'
  if (count === 2) return 'bg-violet-300'
  if (count === 1) return 'bg-violet-200'
  return 'bg-violet-50'
}

const recentSessions = computed(() => {
  const list = clockSessions.value.slice(-6).reverse()
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
    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
      <StatCard label="Heures totales" :value="stats.total" hint="Toutes les sessions" :icon="Clock" />
      <StatCard label="Jours travaillés" :value="stats.days" hint="Jours avec au moins une session" :icon="CalendarCheck" />
      <StatCard label="Moyenne par jour" :value="stats.average" hint="Temps moyen journalier" :icon="TrendingUp" />
      <StatCard label="Dernière session" :value="stats.last" :hint="stats.lastDate" :icon="History" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="font-medium">Heures de la semaine</p>
        <p class="mt-4 text-3xl font-semibold">{{ weekTotal }} h</p>
        <p class="text-sm text-gray-400">travaillées depuis lundi</p>
        <div class="mt-6 h-64">
          <ChartInterface type="line" :chart-data="weekChart" :chart-options="chartOptions({ suffix: 'h' })" />
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6">
        <p class="font-medium">Heures d'arrivée</p>
        <p class="mt-4 text-3xl font-semibold">{{ peakHour }}</p>
        <p class="text-sm text-gray-400">heure d'arrivée la plus fréquente</p>
        <div class="mt-6 grid grid-cols-[2.5rem_repeat(7,1fr)] gap-1 text-xs text-gray-400">
          <template v-for="(row, index) in heatmap" :key="index">
            <span class="flex items-center">{{ HEATMAP_HOURS[index] }}h</span>
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
        <router-link to="/workingTimes" class="text-sm font-medium text-violet-600 hover:underline">Voir tout</router-link>
      </div>
      <table class="w-full text-sm">
        <thead>
          <tr class="bg-gray-50 text-left text-gray-500">
            <th class="rounded-l-lg px-4 py-3 font-medium">Date</th>
            <th class="px-4 py-3 font-medium">Arrivée</th>
            <th class="px-4 py-3 font-medium">Départ</th>
            <th class="rounded-r-lg px-4 py-3 font-medium">Durée</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="session in recentSessions" :key="session.id" class="border-b border-gray-100 last:border-0">
            <td class="px-4 py-3 font-medium">{{ session.date }}</td>
            <td class="px-4 py-3">{{ session.start }}</td>
            <td class="px-4 py-3">{{ session.end }}</td>
            <td class="px-4 py-3">
              <div class="flex items-center gap-3">
                <div class="h-2 w-32 rounded-full bg-violet-100">
                  <div class="h-2 rounded-full bg-violet-500" :style="{ width: `${session.percent}%` }"></div>
                </div>
                <span>{{ session.duration }}</span>
              </div>
            </td>
          </tr>
          <tr v-if="recentSessions.length === 0">
            <td colspan="4" class="px-4 py-8 text-center text-gray-400">Aucune session enregistrée.</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
