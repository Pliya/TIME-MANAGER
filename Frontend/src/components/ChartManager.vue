<script setup>
import { ref, computed, watch } from 'vue'
import { Clock, ChartColumn, CalendarDays, ChartPie } from 'lucide-vue-next'
import api from '@/api'
import ChartInterface from './ChartInterface.vue'
import { localDateKey, toDate, workingTimesToSessions, hoursBetween, decimalHour, pad } from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const GREEN = '#10b981'
const RED = '#ef4444'
const BLUE = '#2563eb'
const PIE_COLORS = ['#2563eb', '#38bdf8', '#818cf8', '#c084fc', '#f43f5e', '#10b981', '#f59e0b']

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

function options({ legend = 'top', suffix = '', max, stepSize } = {}) {
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { position: legend, align: 'end', labels: { usePointStyle: true, boxWidth: 6 } } },
    scales: {
      x: { grid: { display: false } },
      y: { beginAtZero: true, max, grid: { color: '#f1f5f9' }, ticks: { stepSize, callback: value => `${value}${suffix}` } },
    },
  }
}

const pieOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { position: 'right', labels: { usePointStyle: true, boxWidth: 8 } } },
}

const clockTimesChart = computed(() => {
  const days = {}
  clocks.value.forEach(clock => {
    const date = toDate(clock.time)
    const key = localDateKey(date)
    days[key] ??= { label: date.toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric' }), in: null, out: null }
    if (clock.status && days[key].in === null) days[key].in = decimalHour(date)
    if (!clock.status) days[key].out = decimalHour(date)
  })
  const lastDays = Object.keys(days).sort().slice(-7).map(key => days[key])
  return {
    labels: lastDays.map(day => day.label),
    datasets: [
      { label: 'Clock In', data: lastDays.map(day => day.in), borderColor: GREEN, backgroundColor: GREEN, tension: 0.2, pointRadius: 5 },
      { label: 'Clock Out', data: lastDays.map(day => day.out), borderColor: RED, backgroundColor: RED, tension: 0.2, pointRadius: 5 },
    ],
  }
})

const clocksPerHourChart = computed(() => {
  const hoursIn = Array(24).fill(0)
  const hoursOut = Array(24).fill(0)
  clocks.value.forEach(clock => {
    const hour = toDate(clock.time).getHours()
    clock.status ? hoursIn[hour]++ : hoursOut[hour]++
  })
  const activeHours = hoursIn.map((_, hour) => hour).filter(hour => hoursIn[hour] || hoursOut[hour])
  return {
    labels: activeHours.map(hour => `${pad(hour)}h`),
    datasets: [
      { label: 'Clock In', data: activeHours.map(hour => hoursIn[hour]), backgroundColor: GREEN, borderRadius: 4 },
      { label: 'Clock Out', data: activeHours.map(hour => hoursOut[hour]), backgroundColor: RED, borderRadius: 4 },
    ],
  }
})

const hoursPerDay = computed(() => {
  const days = {}
  workingTimesToSessions(workingTimes.value).forEach(session => {
    const name = session.start.toLocaleDateString('fr-FR', { weekday: 'long' })
    const day = name.charAt(0).toUpperCase() + name.slice(1)
    days[day] = (days[day] || 0) + hoursBetween(session.start, session.end)
  })
  return days
})

const workedHoursChart = computed(() => ({
  labels: Object.keys(hoursPerDay.value),
  datasets: [{
    label: 'Heures travaillées (h)',
    data: Object.values(hoursPerDay.value).map(hours => Number(hours.toFixed(2))),
    backgroundColor: BLUE,
    borderRadius: 6,
  }],
}))

const distributionChart = computed(() => {
  const values = Object.values(hoursPerDay.value)
  const total = values.reduce((a, b) => a + b, 0) || 1
  return {
    labels: Object.keys(hoursPerDay.value).map((day, i) => `${day} (${Math.round((values[i] / total) * 100)}%)`),
    datasets: [{ data: values.map(hours => Number(hours.toFixed(2))), backgroundColor: PIE_COLORS, borderColor: '#ffffff', borderWidth: 1 }],
  }
})

const sections = computed(() => [
  {
    title: 'Statistiques des Pointages',
    icon: Clock,
    charts: [
      { title: 'Horaires de pointage', subtitle: "Heures d'arrivée et de départ sur 7 jours", icon: Clock, color: 'bg-blue-50 text-blue-600', type: 'line', data: clockTimesChart.value, options: options({ suffix: 'h', max: 24, stepSize: 4 }) },
      { title: 'Fréquence des pointages', subtitle: 'Nombre de Clock In / Clock Out par heure', icon: ChartColumn, color: 'bg-indigo-50 text-indigo-600', type: 'bar', data: clocksPerHourChart.value, options: options({ stepSize: 1 }) },
    ],
  },
  {
    title: 'Statistiques des Temps de Travail',
    icon: CalendarDays,
    charts: [
      { title: 'Durée travaillée par jour', subtitle: 'Heures cumulées par journée de travail', icon: CalendarDays, color: 'bg-sky-50 text-sky-600', type: 'bar', data: workedHoursChart.value, options: options({ suffix: 'h' }) },
      { title: 'Répartition du temps travaillé', subtitle: 'Proportion (%) du temps total par jour', icon: ChartPie, color: 'bg-purple-50 text-purple-600', type: 'pie', data: distributionChart.value, options: pieOptions },
    ],
  },
])
</script>

<template>
  <div class="space-y-8">
    <section v-for="section in sections" :key="section.title">
      <div class="mb-4 flex items-center gap-3">
        <component :is="section.icon" class="h-5 w-5 text-neutral-500" />
        <h2 class="text-lg font-bold">{{ section.title }}</h2>
      </div>

      <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
        <div v-for="chart in section.charts" :key="chart.title" class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="flex items-center gap-4">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl" :class="chart.color">
              <component :is="chart.icon" class="h-5 w-5" />
            </div>
            <div>
              <p class="font-semibold">{{ chart.title }}</p>
              <p class="text-sm text-neutral-400">{{ chart.subtitle }}</p>
            </div>
          </div>
          <div class="mt-6 h-72">
            <ChartInterface :type="chart.type" :chart-data="chart.data" :chart-options="chart.options" />
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
