<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { Lock } from 'lucide-vue-next'
import { api } from '@/api'
import ChartInterface from './ChartInterface.vue'
import StatCard from './StatCard.vue'
import { compute_kpi, hours_to_text, start_of_week, is_night, sort_by_time } from '@/utils/kpi'

const props = defineProps({ userId: { required: true } })

const DAYS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

const clocks = ref([])
const working_times = ref([])

async function load_data()
{
  const [clocks_res, times_res] = await Promise.all([
    api.get(`/clocks/${props.userId}`).catch(() => ({ data: { data: [] } })),
    api.get(`/workingtime/${props.userId}`).catch(() => ({ data: { data: [] } })),
  ])
  clocks.value = sort_by_time(clocks_res.data.data || [], 'time')
  working_times.value = sort_by_time(times_res.data.data || [], 'start')
}

function to_date(time)
{
  return new Date(time.replace(' ', 'T'))
}

function hour_text(time)
{
  return time.slice(11, 16)
}

const sessions = computed(() =>
{
  const result = []
  let start = null
  clocks.value.forEach(c =>
  {
    if (c.status) start = c.time
    else if (start) {
      result.push({ id: c.id, start, end: c.time })
      start = null
    }
  })
  return result
})

const last_clock = computed(() => clocks.value[clocks.value.length - 1])
const is_clocked_in = computed(() => Boolean(last_clock.value?.status))

const week_entries = computed(() =>
{
  const monday = start_of_week()
  const times = working_times.value.filter(wt => to_date(wt.start) >= monday)
  return times.length ? times : sessions.value.filter(s => to_date(s.start) >= monday)
})

const kpi = computed(() => compute_kpi(week_entries.value))

const last_working_time = computed(() =>
{
  const last = working_times.value[working_times.value.length - 1]
  return last ? { time: hour_text(last.end), date: last.end.slice(0, 10) } : { time: '--:--', date: 'Aucun' }
})

const chart_data = computed(() =>
{
  const hours = [0, 0, 0, 0, 0, 0, 0]
  week_entries.value.forEach(entry =>
  {
    const start = to_date(entry.start)
    const day = (start.getDay() + 6) % 7
    hours[day] += (to_date(entry.end) - start) / 3600000
  })
  return {
    labels: DAYS,
    datasets: [{ label: 'Heures travaillées', data: hours.map(h => Number(h.toFixed(1))), backgroundColor: '#262b5e', borderRadius: 6 }],
  }
})

const chart_options = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: { callbacks: { label: context => hours_to_text(context.raw) } },
  },
  scales: {
    y: { beginAtZero: true, max: 24, ticks: { stepSize: 4, callback: v => v + 'h' }, grid: { color: '#f1f5f9' } },
    x: { grid: { display: false } },
  },
}

const recent_sessions = computed(() =>
  sessions.value.slice(-6).reverse().map(s => ({
    id: s.id,
    date: s.start.slice(0, 10),
    clockIn: hour_text(s.start),
    clockOut: hour_text(s.end),
    duration: hours_to_text((to_date(s.end) - to_date(s.start)) / 3600000),
    night: is_night(s.start),
  }))
)

onMounted(load_data)
watch(() => props.userId, load_data)
</script>

<template>
  <div class="space-y-6">
    <div class="stat-grid">
      <StatCard label="Heures cette semaine" :value="kpi.totalHours" hint="Depuis lundi" icon="timetable" />
      <StatCard label="Jours travaillés" :value="kpi.daysWorked" hint="Cette semaine" icon="schedule" />
      <StatCard label="Moyenne par jour" :value="kpi.avgHours" hint="Cette semaine" icon="trend" />
      <StatCard label="Dernier temps de travail" :value="last_working_time.time" :hint="last_working_time.date" icon="list" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="flex flex-col rounded-2xl bg-white p-6 text-center">
        <p class="card-title text-left font-medium">Pointage</p>
        <div class="flex flex-1 flex-col items-center justify-center">
        <span v-if="is_clocked_in" class="rounded-full bg-neutral-900 px-2.5 py-1 text-xs font-medium text-white">En cours</span>
        <span v-else class="rounded-full bg-neutral-100 px-2.5 py-1 text-xs font-medium">Pas pointé</span>

        <p class="mt-6 text-4xl font-bold">{{ is_clocked_in ? hour_text(last_clock.time) : '--:--' }}</p>
        <p class="mt-2 text-sm text-neutral-400">{{ is_clocked_in ? 'Arrivée pointée' : "Tu n'as pas encore pointé" }}</p>

        <router-link
          :to="`/clock/${props.userId}`"
          class="mt-6 w-full rounded-full border-2 border-neutral-900 py-3 font-semibold hover:bg-neutral-50"
        >
          {{ is_clocked_in ? 'Pointer la sortie' : "Pointer l'arrivée" }}
        </router-link>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="card-title font-medium">Heures de la semaine</p>
        <p class="mt-4 text-3xl font-semibold">{{ kpi.totalHours }}</p>
        <p class="text-sm text-neutral-400">travaillées depuis lundi</p>
        <div class="mt-6 h-64">
          <ChartInterface type="bar" :chart-data="chart_data" :chart-options="chart_options" />
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
            <tr v-for="item in recent_sessions" :key="item.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium sm:px-4">{{ item.date }}</td>
              <td class="px-3 py-3 sm:px-4">{{ item.clockIn }}</td>
              <td class="px-3 py-3 sm:px-4">
                {{ item.clockOut }}
                <span v-if="item.night" class="ml-2 rounded-full bg-neutral-900 px-2.5 py-1 text-xs font-medium text-white">Nuit</span>
              </td>
              <td class="px-3 py-3 sm:px-4">{{ item.duration }}</td>
            </tr>
            <tr v-if="recent_sessions.length === 0">
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
