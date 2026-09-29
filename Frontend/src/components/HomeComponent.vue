<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import { Clock, CalendarCheck, TrendingUp, History } from 'lucide-vue-next'
import { API_URL } from '@/api'
import ChartInterface from './ChartInterface.vue'
import StatCard from './StatCard.vue'
import { computeKpi, hoursToText } from '@/utils/kpi'

const props = defineProps({ userId: { required: true } })
const router = useRouter()

const clocks_list = ref([])
const working_times_list = ref([])

const bar_chart_data = ref({
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  datasets: [{
    label: 'Hours Worked',
    data: [0, 0, 0, 0, 0, 0, 0],
    backgroundColor: '#171717',
    borderRadius: 6
  }]
})

const bar_chart_options = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: { callbacks: { label: context => hoursToText(context.raw) } }
  },
  scales: {
    y: {
      beginAtZero: true,
      max: 24,
      ticks: { stepSize: 4, callback: v => v + 'h' },
      grid: { color: '#f1f5f9' }
    },
    x: { grid: { display: false } }
  }
}

const pad_zero = (n) => String(n).padStart(2, '0')

function get_monday() {
  const now = new Date()
  const current_day = now.getDay()
  const distance_to_monday = current_day === 0 ? 6 : current_day - 1
  const monday = new Date(now)
  monday.setDate(now.getDate() - distance_to_monday)
  monday.setHours(0, 0, 0, 0)
  return monday
}

async function load_dashboard_data() {
  try {
    const [clocks_res, wt_res] = await Promise.all([
      axios.get(`${API_URL}/clocks/${props.userId}`).catch(() => ({ data: { data: [] } })),
      axios.get(`${API_URL}/workingtime/${props.userId}`).catch(() => ({ data: { data: [] } }))
    ])

    clocks_list.value = clocks_res.data?.data || clocks_res.data || []
    working_times_list.value = wt_res.data?.data || wt_res.data || []

    update_weekly_chart()
  } catch (err) {
    console.error('Erreur chargement dashboard:', err)
  }
}

function update_weekly_chart() {
  const week_labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  const week_hours = [0, 0, 0, 0, 0, 0, 0]

  const monday = get_monday()

  working_times_list.value.forEach(wt => {
    if (!wt.start || !wt.end) return
    const s = new Date(wt.start.replace(' ', 'T'))
    const e = new Date(wt.end.replace(' ', 'T'))
    if (isNaN(s) || isNaN(e) || e <= s) return

    if (s >= monday) {
      const day_idx = s.getDay() === 0 ? 6 : s.getDay() - 1
      const hours = (e - s) / (1000 * 60 * 60)
      week_hours[day_idx] += hours
    }
  })

  if (week_hours.every(h => h === 0) && clocks_list.value.length > 0) {
    const reversed = [...clocks_list.value].reverse()
    for (let i = 0; i < reversed.length; i++) {
      const c = reversed[i]
      if (!c.status) {
        const out_d = new Date(c.time.replace(' ', 'T'))
        const prev_in = reversed.find((item, idx) => idx > i && item.status)
        if (prev_in) {
          const in_d = new Date(prev_in.time.replace(' ', 'T'))
          if (in_d >= monday) {
            const day_idx = in_d.getDay() === 0 ? 6 : in_d.getDay() - 1
            const hours = (out_d - in_d) / (1000 * 60 * 60)
            week_hours[day_idx] += hours
          }
        }
      }
    }
  }

  bar_chart_data.value = {
    labels: week_labels,
    datasets: [{
      label: 'Hours Worked',
      data: week_hours.map(h => Number(h.toFixed(1))),
      backgroundColor: '#171717',
      borderRadius: 6
    }]
  }
}

const week_working_times = computed(() =>
  working_times_list.value.filter(wt => new Date(wt.start.replace(' ', 'T')) >= get_monday())
)

const kpi_data = computed(() => computeKpi(week_working_times.value))

const last_working_time = computed(() => {
  const last = working_times_list.value[working_times_list.value.length - 1]
  if (!last) return { time: '--:--', date: 'N/A' }
  return { time: last.end.slice(11, 16), date: last.end.slice(0, 10) }
})

const recent_working_times = computed(() => {
  const result = []
  const reversed = [...clocks_list.value].reverse()
  for (let i = 0; i < reversed.length; i++) {
    const c = reversed[i]
    if (!c.status) {
      const clock_out_date = new Date(c.time.replace(' ', 'T'))
      const prev_in = reversed.find((item, idx) => idx > i && item.status)
      if (prev_in) {
        const clock_in_date = new Date(prev_in.time.replace(' ', 'T'))
        const diff_h = Math.floor((clock_out_date - clock_in_date) / 3600000)
        const diff_m = Math.floor(((clock_out_date - clock_in_date) % 3600000) / 60000)
        result.push({
          id: c.id,
          date: clock_in_date.toISOString().split('T')[0],
          clock_in: `${pad_zero(clock_in_date.getHours())}:${pad_zero(clock_in_date.getMinutes())}`,
          clock_out: `${pad_zero(clock_out_date.getHours())}:${pad_zero(clock_out_date.getMinutes())}`,
          duration: `${diff_h}h ${pad_zero(diff_m)}m`
        })
      }
    }
    if (result.length >= 6) break
  }
  return result
})

function go_to_working_times() {
  router.push(`/workingTimes/${props.userId}`)
}

const heatmap_hours = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]
const week_labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

const arrival_heatmap = computed(() => {
  const counts = heatmap_hours.map(() => [0, 0, 0, 0, 0, 0, 0])
  clocks_list.value.forEach(c => {
    if (!c.status) return
    const d = new Date(c.time.replace(' ', 'T'))
    const day_idx = d.getDay() === 0 ? 6 : d.getDay() - 1
    counts[Math.floor(d.getHours() / 2)][day_idx]++
  })
  return counts
})

function heat_color(count) {
  if (count >= 3) return 'bg-neutral-900'
  if (count === 2) return 'bg-neutral-500'
  if (count === 1) return 'bg-neutral-300'
  return 'bg-neutral-100'
}

onMounted(load_dashboard_data)
watch(() => props.userId, load_dashboard_data)
</script>

<template>
  <div class="space-y-6">
    <div class="grid grid-cols-2 gap-4 lg:gap-6 xl:grid-cols-4">
      <StatCard label="Total Working Hours" :value="kpi_data.totalHours" hint="Cette semaine" :icon="Clock" />
      <StatCard label="Days Worked" :value="kpi_data.daysWorked" hint="Cette semaine" :icon="CalendarCheck" />
      <StatCard label="Average Daily Hours" :value="kpi_data.avgHours" hint="Cette semaine" :icon="TrendingUp" />
      <StatCard label="Last Working Time" :value="last_working_time.time" :hint="last_working_time.date" :icon="History" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="font-medium">Working Hours (This Week)</p>
        <p class="mt-4 text-3xl font-semibold">{{ kpi_data.totalHours }}</p>
        <p class="text-sm text-neutral-400">travaillées depuis lundi</p>
        <div class="mt-6 h-64">
          <ChartInterface type="bar" :chart-data="bar_chart_data" :chart-options="bar_chart_options" />
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6">
        <p class="font-medium">Heures d'arrivée</p>
        <p class="text-sm text-neutral-400">Nombre de Clock In par créneau de 2h</p>
        <div class="mt-6 grid grid-cols-[2.5rem_repeat(7,1fr)] gap-1 text-xs text-neutral-400">
          <template v-for="(row, index) in arrival_heatmap" :key="index">
            <span class="flex items-center">{{ heatmap_hours[index] }}h</span>
            <div v-for="(count, day) in row" :key="day" class="h-5 rounded" :class="heat_color(count)"></div>
          </template>
          <span></span>
          <span v-for="day in week_labels" :key="day" class="text-center">{{ day }}</span>
        </div>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-6">
      <div class="mb-4 flex items-center justify-between">
        <p class="font-medium">Recent Working Times</p>
        <button class="text-sm font-medium text-neutral-900 hover:underline" @click="go_to_working_times">View all working times</button>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium sm:px-4">Date</th>
              <th class="px-3 py-3 font-medium sm:px-4">Clock In</th>
              <th class="px-3 py-3 font-medium sm:px-4">Clock Out</th>
              <th class="rounded-r-lg px-3 py-3 font-medium sm:px-4">Duration</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in recent_working_times" :key="item.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium sm:px-4">{{ item.date }}</td>
              <td class="px-3 py-3 sm:px-4">{{ item.clock_in }}</td>
              <td class="px-3 py-3 sm:px-4">{{ item.clock_out }}</td>
              <td class="px-3 py-3 sm:px-4">{{ item.duration }}</td>
            </tr>
            <tr v-if="recent_working_times.length === 0">
              <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune donnée récente.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
