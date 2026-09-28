<script setup>
import { ref, computed, watch } from 'vue'
import api from '@/api'
import ChartInterface from './ChartInterface.vue'
import { DARK, LIGHT, PALETTE, chartOptions, hoursOfDayOptions, pieOptions } from '@/utils/charts'
import {
  WEEK_DAYS, clocksToSessions, workingTimesToSessions, hoursBetween, weekdayIndex,
  formatDay, decimalHour, formatDecimalHours, localDateKey, toDate,
} from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const clocks = ref([])
const workingTimes = ref([])

const HOURS = Array.from({ length: 24 }, (_, hour) => hour)

async function loadData() {
  const [clocksRes, workingTimesRes] = await Promise.all([
    api.get(`/clocks/${props.userId}`).catch(() => ({ data: { data: [] } })),
    api.get(`/workingtime/${props.userId}`).catch(() => ({ data: { data: [] } })),
  ])
  clocks.value = clocksRes.data.data
  workingTimes.value = workingTimesRes.data.data
}

watch(() => props.userId, loadData, { immediate: true })

const arrivalChart = computed(() => {
  const sessions = clocksToSessions(clocks.value).slice(-7)
  return {
    labels: sessions.map(s => formatDay(s.start)),
    datasets: [
      { label: 'Arrivée', data: sessions.map(s => decimalHour(s.start)), borderColor: DARK, backgroundColor: DARK, tension: 0.35 },
      { label: 'Départ', data: sessions.map(s => decimalHour(s.end)), borderColor: LIGHT, backgroundColor: LIGHT, tension: 0.35 },
    ],
  }
})

const clocksPerHourChart = computed(() => {
  const count = status => HOURS.map(hour => clocks.value.filter(c => c.status === status && toDate(c.time).getHours() === hour).length)
  return {
    labels: HOURS.map(hour => `${hour}h`),
    datasets: [
      { label: 'Arrivées', data: count(true), backgroundColor: DARK, borderRadius: 4 },
      { label: 'Départs', data: count(false), backgroundColor: LIGHT, borderRadius: 4 },
    ],
  }
})

const averagePerWeekday = computed(() => {
  const totals = [0, 0, 0, 0, 0, 0, 0]
  const days = WEEK_DAYS.map(() => new Set())
  workingTimesToSessions(workingTimes.value).forEach(s => {
    const day = weekdayIndex(s.start)
    totals[day] += hoursBetween(s.start, s.end)
    days[day].add(localDateKey(s.start))
  })
  return totals.map((total, day) => (days[day].size ? Number((total / days[day].size).toFixed(2)) : 0))
})

const weekdayChart = computed(() => ({
  labels: WEEK_DAYS,
  datasets: [{ label: 'Moyenne', data: averagePerWeekday.value, backgroundColor: DARK, borderRadius: 6 }],
}))

const distributionChart = computed(() => ({
  labels: WEEK_DAYS,
  datasets: [{ data: averagePerWeekday.value, backgroundColor: PALETTE, borderColor: '#ffffff', borderWidth: 2 }],
}))

const charts = computed(() => [
  { title: "Heures d'arrivée et de départ", subtitle: '7 dernières sessions, sur 24h', type: 'line', data: arrivalChart.value, options: hoursOfDayOptions },
  { title: 'Pointages par heure', subtitle: "Nombre d'arrivées et de départs de 0h à 23h", type: 'bar', data: clocksPerHourChart.value, options: chartOptions({ legend: true }) },
  { title: 'Moyenne par jour de la semaine', subtitle: 'Heures travaillées en moyenne, sur 24h', type: 'bar', data: weekdayChart.value, options: chartOptions({ suffix: 'h', max: 24, stepSize: 4, formatValue: formatDecimalHours }) },
  { title: 'Répartition du temps de travail', subtitle: 'Part de chaque jour de la semaine', type: 'doughnut', data: distributionChart.value, options: pieOptions },
])
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <div v-for="chart in charts" :key="chart.title" class="rounded-2xl bg-white p-6">
      <p class="font-medium">{{ chart.title }}</p>
      <p class="text-sm text-neutral-400">{{ chart.subtitle }}</p>
      <div class="mt-6 h-72">
        <ChartInterface :type="chart.type" :chart-data="chart.data" :chart-options="chart.options" />
      </div>
    </div>
  </div>
</template>
