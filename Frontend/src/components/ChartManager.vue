<script setup>
import { ref, computed, watch } from 'vue'
import api from '@/api'
import ChartInterface from './ChartInterface.vue'
import { VIOLET, VIOLET_LIGHT, PALETTE, chartOptions, pieOptions } from '@/utils/charts'
import { WEEK_DAYS, clocksToSessions, workingTimesToSessions, hoursBetween, weekdayIndex, formatDay } from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const clocks = ref([])
const workingTimes = ref([])

async function loadData() {
  const [clocksRes, workingTimesRes] = await Promise.all([
    api.get(`/clocks/${props.userId}`).catch(() => ({ data: { data: [] } })),
    api.get(`/workingtime/${props.userId}`).catch(() => ({ data: { data: [] } })),
  ])
  clocks.value = clocksRes.data.data
  workingTimes.value = workingTimesRes.data.data
}

watch(() => props.userId, loadData, { immediate: true })

function decimalHour(date) {
  return Number((date.getHours() + date.getMinutes() / 60).toFixed(2))
}

const arrivalChart = computed(() => {
  const sessions = clocksToSessions(clocks.value).slice(-7)
  return {
    labels: sessions.map(s => formatDay(s.start)),
    datasets: [
      { label: 'Arrivée', data: sessions.map(s => decimalHour(s.start)), borderColor: VIOLET, backgroundColor: VIOLET, tension: 0.35 },
      { label: 'Départ', data: sessions.map(s => decimalHour(s.end)), borderColor: VIOLET_LIGHT, backgroundColor: VIOLET_LIGHT, tension: 0.35 },
    ],
  }
})

const clocksPerHourChart = computed(() => {
  const hours = Array.from({ length: 24 }, (_, h) => h)
  const count = status => hours.map(h => clocks.value.filter(c => c.status === status && new Date(c.time).getHours() === h).length)
  const arrivals = count(true)
  const departures = count(false)
  const activeHours = hours.filter(h => arrivals[h] || departures[h])
  return {
    labels: activeHours.map(h => `${h}h`),
    datasets: [
      { label: 'Arrivées', data: activeHours.map(h => arrivals[h]), backgroundColor: VIOLET, borderRadius: 6 },
      { label: 'Départs', data: activeHours.map(h => departures[h]), backgroundColor: VIOLET_LIGHT, borderRadius: 6 },
    ],
  }
})

const hoursPerWeekday = computed(() => {
  const hours = [0, 0, 0, 0, 0, 0, 0]
  workingTimesToSessions(workingTimes.value).forEach(s => {
    hours[weekdayIndex(s.start)] += hoursBetween(s.start, s.end)
  })
  return hours.map(h => Number(h.toFixed(1)))
})

const weekdayChart = computed(() => ({
  labels: WEEK_DAYS,
  datasets: [{ label: 'Heures', data: hoursPerWeekday.value, backgroundColor: VIOLET, borderRadius: 6 }],
}))

const distributionChart = computed(() => ({
  labels: WEEK_DAYS,
  datasets: [{ data: hoursPerWeekday.value, backgroundColor: PALETTE, borderColor: '#ffffff', borderWidth: 2 }],
}))

const charts = computed(() => [
  { title: "Heures d'arrivée et de départ", subtitle: '7 dernières sessions', type: 'line', data: arrivalChart.value, options: chartOptions({ legend: true, suffix: 'h' }) },
  { title: 'Pointages par heure', subtitle: "Nombre d'arrivées et de départs", type: 'bar', data: clocksPerHourChart.value, options: chartOptions({ legend: true }) },
  { title: 'Heures par jour de la semaine', subtitle: 'Cumul des temps de travail', type: 'bar', data: weekdayChart.value, options: chartOptions({ suffix: 'h' }) },
  { title: 'Répartition du temps de travail', subtitle: 'Part de chaque jour', type: 'doughnut', data: distributionChart.value, options: pieOptions },
])
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <div v-for="chart in charts" :key="chart.title" class="rounded-2xl bg-white p-6">
      <p class="font-medium">{{ chart.title }}</p>
      <p class="text-sm text-gray-400">{{ chart.subtitle }}</p>
      <div class="mt-6 h-72">
        <ChartInterface :type="chart.type" :chart-data="chart.data" :chart-options="chart.options" />
      </div>
    </div>
  </div>
</template>
