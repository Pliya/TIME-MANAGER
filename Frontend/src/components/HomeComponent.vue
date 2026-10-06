<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { Lock } from 'lucide-vue-next'
import { api } from '@/api'
import ChartInterface from './ChartInterface.vue'
import StatCard from './StatCard.vue'
import { computeKpi, hoursToText, startOfWeek, isNight, sortByTime } from '@/utils/kpi'

const props = defineProps({ userId: { required: true } })

const DAYS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

const clocks = ref([])
const workingTimes = ref([])

async function loadData() {
  const [clocksRes, timesRes] = await Promise.all([
    api.get(`/clocks/${props.userId}`).catch(() => ({ data: { data: [] } })),
    api.get(`/workingtime/${props.userId}`).catch(() => ({ data: { data: [] } })),
  ])
  clocks.value = sortByTime(clocksRes.data.data || [], 'time')
  workingTimes.value = sortByTime(timesRes.data.data || [], 'start')
}

function toDate(time) {
  return new Date(time.replace(' ', 'T'))
}

function hourText(time) {
  return time.slice(11, 16)
}

const sessions = computed(() => {
  const result = []
  let start = null
  clocks.value.forEach(c => {
    if (c.status) start = c.time
    else if (start) {
      result.push({ id: c.id, start, end: c.time })
      start = null
    }
  })
  return result
})

const lastClock = computed(() => clocks.value[clocks.value.length - 1])
const isClockedIn = computed(() => Boolean(lastClock.value?.status))

const weekEntries = computed(() => {
  const monday = startOfWeek()
  const times = workingTimes.value.filter(wt => toDate(wt.start) >= monday)
  return times.length ? times : sessions.value.filter(s => toDate(s.start) >= monday)
})

const kpi = computed(() => computeKpi(weekEntries.value))

const lastWorkingTime = computed(() => {
  const last = workingTimes.value[workingTimes.value.length - 1]
  return last ? { time: hourText(last.end), date: last.end.slice(0, 10) } : { time: '--:--', date: 'Aucun' }
})

const chartData = computed(() => {
  const hours = [0, 0, 0, 0, 0, 0, 0]
  weekEntries.value.forEach(entry => {
    const start = toDate(entry.start)
    const day = (start.getDay() + 6) % 7
    hours[day] += (toDate(entry.end) - start) / 3600000
  })
  return {
    labels: DAYS,
    datasets: [{ label: 'Heures travaillées', data: hours.map(h => Number(h.toFixed(1))), backgroundColor: '#262b5e', borderRadius: 6 }],
  }
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: { callbacks: { label: context => hoursToText(context.raw) } },
  },
  scales: {
    y: { beginAtZero: true, max: 24, ticks: { stepSize: 4, callback: v => v + 'h' }, grid: { color: '#f1f5f9' } },
    x: { grid: { display: false } },
  },
}

const recentSessions = computed(() =>
  sessions.value.slice(-6).reverse().map(s => ({
    id: s.id,
    date: s.start.slice(0, 10),
    clockIn: hourText(s.start),
    clockOut: hourText(s.end),
    duration: hoursToText((toDate(s.end) - toDate(s.start)) / 3600000),
    night: isNight(s.start),
  }))
)

onMounted(loadData)
watch(() => props.userId, loadData)
</script>

<template>
  <div class="space-y-6">
    <div class="stat-grid">
      <StatCard label="Heures cette semaine" :value="kpi.totalHours" hint="Depuis lundi" icon="timetable" />
      <StatCard label="Jours travaillés" :value="kpi.daysWorked" hint="Cette semaine" icon="schedule" />
      <StatCard label="Moyenne par jour" :value="kpi.avgHours" hint="Cette semaine" icon="trend" />
      <StatCard label="Dernier temps de travail" :value="lastWorkingTime.time" :hint="lastWorkingTime.date" icon="list" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="flex flex-col rounded-2xl bg-white p-6 text-center">
        <p class="card-title text-left font-medium">Pointage</p>
        <div class="flex flex-1 flex-col items-center justify-center">
        <span v-if="isClockedIn" class="rounded-full bg-neutral-900 px-2.5 py-1 text-xs font-medium text-white">En cours</span>
        <span v-else class="rounded-full bg-neutral-100 px-2.5 py-1 text-xs font-medium">Pas pointé</span>

        <p class="mt-6 text-4xl font-bold">{{ isClockedIn ? hourText(lastClock.time) : '--:--' }}</p>
        <p class="mt-2 text-sm text-neutral-400">{{ isClockedIn ? 'Arrivée pointée' : "Tu n'as pas encore pointé" }}</p>

        <router-link
          :to="`/clock/${props.userId}`"
          class="mt-6 w-full rounded-full border-2 border-neutral-900 py-3 font-semibold hover:bg-neutral-50"
        >
          {{ isClockedIn ? 'Pointer la sortie' : "Pointer l'arrivée" }}
        </router-link>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="card-title font-medium">Heures de la semaine</p>
        <p class="mt-4 text-3xl font-semibold">{{ kpi.totalHours }}</p>
        <p class="text-sm text-neutral-400">travaillées depuis lundi</p>
        <div class="mt-6 h-64">
          <ChartInterface type="bar" :chart-data="chartData" :chart-options="chartOptions" />
        </div>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-6">
      <div class="card-title mb-4 flex items-center justify-between">
        <p class="font-medium">Dernières sessions</p>
        <router-link :to="`/workingTimes/${props.userId}`" class="text-sm font-medium hover:underline">Voir tous les temps</router-link>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium sm:px-4">Date</th>
              <th class="px-3 py-3 font-medium sm:px-4">Arrivée</th>
              <th class="px-3 py-3 font-medium sm:px-4">Sortie</th>
              <th class="rounded-r-lg px-3 py-3 font-medium sm:px-4">Durée</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in recentSessions" :key="item.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium sm:px-4">{{ item.date }}</td>
              <td class="px-3 py-3 sm:px-4">{{ item.clockIn }}</td>
              <td class="px-3 py-3 sm:px-4">
                {{ item.clockOut }}
                <span v-if="item.night" class="ml-2 rounded-full bg-neutral-900 px-2.5 py-1 text-xs font-medium text-white">Nuit</span>
              </td>
              <td class="px-3 py-3 sm:px-4">{{ item.duration }}</td>
            </tr>
            <tr v-if="recentSessions.length === 0">
              <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune session récente.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-4 flex items-center gap-2 text-xs text-neutral-500">
        <Lock class="h-4 w-4" />
        Ces chiffres sont pour toi. Aucune comparaison avec tes collègues.
      </p>
    </div>

  </div>
</template>
