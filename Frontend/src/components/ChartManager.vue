<script setup>
import { ref, onMounted, watch } from 'vue'
import axios from 'axios'
import { Clock, ChartColumn, CalendarDays, ChartPie } from 'lucide-vue-next'
import { API_URL } from '@/api'
import ChartInterface from './ChartInterface.vue'
import { hoursToText } from '@/utils/kpi'

const props = defineProps({
  userId: {
    required: true
  }
})

const line_data = ref({ labels: [], datasets: [] })
const clock_bar_data = ref({ labels: [], datasets: [] })

const wt_bar_data = ref({ labels: [], datasets: [] })
const wt_pie_data = ref({ labels: [], datasets: [] })

function format_clock_time(hour_decimal) {
  const minutes = Math.round(hour_decimal * 60)
  return `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`
}

const base_options = {
  responsive: true,
  maintainAspectRatio: false,
  layout: { padding: { top: 10, right: 15, bottom: 10, left: 10 } },
  plugins: {
    legend: {
      position: 'top',
      align: 'end',
      labels: { usePointStyle: true, boxWidth: 6 }
    }
  }
}

const line_options = {
  ...base_options,
  plugins: {
    ...base_options.plugins,
    tooltip: { callbacks: { label: context => `${context.dataset.label} : ${format_clock_time(context.raw)}` } }
  },
  scales: {
    y: {
      min: 0,
      max: 24,
      ticks: { stepSize: 4, callback: v => v + 'h' },
      grid: { color: '#f1f5f9' }
    },
    x: { grid: { display: false } }
  }
}

const clock_bar_options = {
  ...base_options,
  scales: {
    y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: '#f1f5f9' } },
    x: { grid: { display: false } }
  }
}

const wt_bar_options = {
  ...base_options,
  plugins: {
    ...base_options.plugins,
    tooltip: { callbacks: { label: context => hoursToText(context.raw) } }
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: { callback: v => v + 'h' },
      grid: { color: '#f1f5f9' }
    },
    x: { grid: { display: false } }
  }
}

const wt_pie_options = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: window.innerWidth < 640 ? 'bottom' : 'right',
      labels: { usePointStyle: true, boxWidth: 8, font: { size: 12 } }
    },
    tooltip: { callbacks: { label: context => hoursToText(context.raw) } }
  }
}

async function load_clocks_data() {
  try {
    const { data } = await axios.get(`${API_URL}/clocks/${props.userId}`)
    const clocks_list = data.data || []

    const days_map = {}
    const hours_in = Array(24).fill(0)
    const hours_out = Array(24).fill(0)

    clocks_list.forEach(c => {
      const d = new Date(c.time.replace(' ', 'T'))
      const key = d.toISOString().split('T')[0]
      const hour_decimal = d.getHours() + d.getMinutes() / 60

      if (!days_map[key]) {
        const label = d.toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric' })
        days_map[key] = { label, in: null, out: null }
      }
      if (c.status && !days_map[key].in) days_map[key].in = hour_decimal
      else if (!c.status) days_map[key].out = hour_decimal

      const h = d.getHours()
      c.status ? hours_in[h]++ : hours_out[h]++
    })

    const days_list = Object.values(days_map).slice(-7)
    line_data.value = {
      labels: days_list.map(d => d.label),
      datasets: [
        { label: 'Clock In', data: days_list.map(d => d.in), borderColor: '#10b981', backgroundColor: '#10b981', tension: 0.2, pointRadius: 5 },
        { label: 'Clock Out', data: days_list.map(d => d.out), borderColor: '#ef4444', backgroundColor: '#ef4444', tension: 0.2, pointRadius: 5 }
      ]
    }

    const active_hours = Array.from({ length: 24 }, (_, i) => i).filter(h => hours_in[h] || hours_out[h])
    clock_bar_data.value = {
      labels: active_hours.length ? active_hours.map(h => `${String(h).padStart(2, '0')}h`) : ['-'],
      datasets: [
        { label: 'Clock In', data: active_hours.map(h => hours_in[h]), backgroundColor: '#10b981', borderRadius: 4 },
        { label: 'Clock Out', data: active_hours.map(h => hours_out[h]), backgroundColor: '#ef4444', borderRadius: 4 }
      ]
    }
  } catch (err) {
    console.error('Erreur chargement clocks:', err)
  }
}

async function load_working_times_data() {
  try {
    const { data } = await axios.get(`${API_URL}/workingtime/${props.userId}`)
    const wt_list = data.data || data || []

    const days_durations = {}

    wt_list.forEach(wt => {
      if (!wt.start || !wt.end) return
      const s = new Date(wt.start.replace(' ', 'T')).getTime()
      const e = new Date(wt.end.replace(' ', 'T')).getTime()
      if (isNaN(s) || isNaN(e) || e <= s) return

      const hours_worked = (e - s) / (1000 * 60 * 60)
      const day_name = new Date(wt.start.replace(' ', 'T')).toLocaleDateString('fr-FR', { weekday: 'long' })
      const capitalized_day = day_name.charAt(0).toUpperCase() + day_name.slice(1)

      days_durations[capitalized_day] = (days_durations[capitalized_day] || 0) + hours_worked
    })

    const days_keys = Object.keys(days_durations)
    const default_days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi']
    const labels_to_use = days_keys.length ? days_keys : default_days
    const default_values = [8.5, 7.75, 9.0, 8.16, 7.83]
    const values_to_use = days_keys.length ? days_keys.map(k => Number(days_durations[k].toFixed(2))) : default_values

    wt_bar_data.value = {
      labels: labels_to_use,
      datasets: [
        {
          label: 'Heures travaillées (h)',
          data: values_to_use,
          backgroundColor: '#2563eb',
          borderRadius: 6
        }
      ]
    }

    const total_sum = values_to_use.reduce((a, b) => a + b, 0) || 1
    const percentages = values_to_use.map(v => Math.round((v / total_sum) * 100))

    wt_pie_data.value = {
      labels: labels_to_use.map((day, i) => `${day} (${percentages[i]}%)`),
      datasets: [
        {
          data: values_to_use,
          backgroundColor: ['#2563eb', '#38bdf8', '#818cf8', '#c084fc', '#f43f5e', '#10b981', '#f59e0b'],
          borderWidth: 1,
          borderColor: '#ffffff'
        }
      ]
    }
  } catch (err) {
    console.error('Erreur chargement working times charts:', err)
  }
}

const chart_types = ref({ line: 'line', clock_bar: 'bar', wt_bar: 'bar', wt_pie: 'pie' })

const type_labels = { line: 'Ligne', bar: 'Barres', radar: 'Radar', pie: 'Camembert', doughnut: 'Anneau', polarArea: 'Polaire' }

const radar_options = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { position: 'top', labels: { usePointStyle: true, boxWidth: 6 } } }
}

function options_for(key, default_options) {
  const type = chart_types.value[key]
  if (['pie', 'doughnut', 'polarArea'].includes(type)) return wt_pie_options
  if (type === 'radar') return radar_options
  return default_options
}

function load_all_charts() {
  load_clocks_data()
  load_working_times_data()
}

onMounted(load_all_charts)
watch(() => props.userId, load_all_charts)
</script>

<template>
  <div class="space-y-8">
    <section>
      <div class="mb-4 flex items-center gap-3">
        <Clock class="h-5 w-5 text-neutral-500" />
        <h2 class="text-lg font-bold">Statistiques des Pointages</h2>
      </div>
      <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="flex flex-wrap items-center gap-4">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600"><Clock class="h-5 w-5" /></div>
            <div>
              <p class="font-semibold">Horaires de pointage</p>
              <p class="text-sm text-neutral-400">Heures d'arrivée et de départ sur 7 jours</p>
            </div>
            <select v-model="chart_types.line" class="ml-auto rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option v-for="type in ['line', 'bar', 'radar']" :key="type" :value="type">{{ type_labels[type] }}</option>
            </select>
          </div>
          <div class="mt-6 h-72">
            <ChartInterface :key="chart_types.line" :type="chart_types.line" :chart-data="line_data" :chart-options="options_for('line', line_options)" />
          </div>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="flex flex-wrap items-center gap-4">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600"><ChartColumn class="h-5 w-5" /></div>
            <div>
              <p class="font-semibold">Fréquence des pointages</p>
              <p class="text-sm text-neutral-400">Nombre de Clock In / Clock Out par heure</p>
            </div>
            <select v-model="chart_types.clock_bar" class="ml-auto rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option v-for="type in ['bar', 'line', 'radar']" :key="type" :value="type">{{ type_labels[type] }}</option>
            </select>
          </div>
          <div class="mt-6 h-72">
            <ChartInterface :key="chart_types.clock_bar" :type="chart_types.clock_bar" :chart-data="clock_bar_data" :chart-options="options_for('clock_bar', clock_bar_options)" />
          </div>
        </div>
      </div>
    </section>

    <section>
      <div class="mb-4 flex items-center gap-3">
        <CalendarDays class="h-5 w-5 text-neutral-500" />
        <h2 class="text-lg font-bold">Statistiques des Temps de Travail</h2>
      </div>
      <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="flex flex-wrap items-center gap-4">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-sky-50 text-sky-600"><CalendarDays class="h-5 w-5" /></div>
            <div>
              <p class="font-semibold">Durée travaillée par jour</p>
              <p class="text-sm text-neutral-400">Heures cumulées par journée de travail</p>
            </div>
            <select v-model="chart_types.wt_bar" class="ml-auto rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option v-for="type in ['bar', 'line', 'radar']" :key="type" :value="type">{{ type_labels[type] }}</option>
            </select>
          </div>
          <div class="mt-6 h-72">
            <ChartInterface :key="chart_types.wt_bar" :type="chart_types.wt_bar" :chart-data="wt_bar_data" :chart-options="options_for('wt_bar', wt_bar_options)" />
          </div>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="flex flex-wrap items-center gap-4">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50 text-purple-600"><ChartPie class="h-5 w-5" /></div>
            <div>
              <p class="font-semibold">Répartition du temps travaillé</p>
              <p class="text-sm text-neutral-400">Proportion (%) du temps total par jour</p>
            </div>
            <select v-model="chart_types.wt_pie" class="ml-auto rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option v-for="type in ['pie', 'doughnut', 'polarArea']" :key="type" :value="type">{{ type_labels[type] }}</option>
            </select>
          </div>
          <div class="mt-6 h-72">
            <ChartInterface :key="chart_types.wt_pie" :type="chart_types.wt_pie" :chart-data="wt_pie_data" :chart-options="options_for('wt_pie', wt_pie_options)" />
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
