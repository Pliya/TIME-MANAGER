<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import ChartInterface from './ChartInterface.vue'

const props = defineProps({ userId: { required: true } })
const router = useRouter()

const clocks_list = ref([])
const working_times_list = ref([])

const bar_chart_data = ref({
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  datasets: [{
    label: 'Hours Worked',
    data: [0, 0, 0, 0, 0, 0, 0],
    backgroundColor: '#2563eb',
    borderRadius: 6
  }]
})

const bar_chart_options = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    y: {
      beginAtZero: true,
      max: 12,
      ticks: { stepSize: 3, callback: v => v + 'h' },
      grid: { color: '#f1f5f9' }
    },
    x: { grid: { display: false } }
  }
}

const pad_zero = (n) => String(n).padStart(2, '0')

/* --- Chargement des Données depuis l'API --- */
async function load_dashboard_data() {
  try {
    const [clocks_res, wt_res] = await Promise.all([
      axios.get(`http://localhost:4000/api/clocks/${props.userId}`).catch(() => ({ data: { data: [] } })),
      axios.get(`http://localhost:4000/api/workingtime/${props.userId}`).catch(() => ({ data: { data: [] } }))
    ])

    clocks_list.value = clocks_res.data?.data || clocks_res.data || []
    working_times_list.value = wt_res.data?.data || wt_res.data || []

    update_weekly_chart()
  } catch (err) {
    console.error('Erreur chargement dashboard:', err)
  }
}

/* --- Mise à jour du Graphique à Barres Hebdomadaire (Données Réelles) --- */
function update_weekly_chart() {
  const week_labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  const week_hours = [0, 0, 0, 0, 0, 0, 0]

  const now = new Date()
  const current_day = now.getDay()
  const distance_to_monday = current_day === 0 ? 6 : current_day - 1
  const monday = new Date(now)
  monday.setDate(now.getDate() - distance_to_monday)
  monday.setHours(0, 0, 0, 0)

  // Calcule les heures depuis working_times
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

  // Si pas de working_times déclarés dans la semaine, utilise clocks
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
      backgroundColor: '#2563eb',
      borderRadius: 6
    }]
  }
}

/* --- Calcul Dynamique des KPIs Réels --- */
const kpi_data = computed(() => {
  let total_ms = 0
  const unique_days = new Set()
  let last_time_str = '--:--'
  let last_date_str = 'N/A'

  // Calcul basé sur working_times_list
  if (working_times_list.value.length > 0) {
    working_times_list.value.forEach(wt => {
      if (!wt.start || !wt.end) return
      const s = new Date(wt.start.replace(' ', 'T')).getTime()
      const e = new Date(wt.end.replace(' ', 'T')).getTime()
      if (!isNaN(s) && !isNaN(e) && e > s) {
        total_ms += (e - s)
        unique_days.add(wt.start.slice(0, 10))
      }
    })

    const last = working_times_list.value[working_times_list.value.length - 1]
    if (last && last.end) {
      const d = new Date(last.end.replace(' ', 'T'))
      if (!isNaN(d)) {
        last_time_str = `${pad_zero(d.getHours())}:${pad_zero(d.getMinutes())}`
        last_date_str = d.toISOString().split('T')[0]
      }
    }
  } else if (clocks_list.value.length > 0) {
    // Fallback sur clocks_list si working_times est vide
    const reversed = [...clocks_list.value].reverse()
    for (let i = 0; i < reversed.length; i++) {
      const c = reversed[i]
      if (!c.status) {
        const out_d = new Date(c.time.replace(' ', 'T'))
        const prev_in = reversed.find((item, idx) => idx > i && item.status)
        if (prev_in) {
          const in_d = new Date(prev_in.time.replace(' ', 'T'))
          if (!isNaN(in_d) && !isNaN(out_d) && out_d > in_d) {
            total_ms += (out_d - in_d)
            unique_days.add(in_d.toISOString().split('T')[0])
          }
        }
      }
    }
    const last_clock = clocks_list.value[clocks_list.value.length - 1]
    if (last_clock && last_clock.time) {
      const d = new Date(last_clock.time.replace(' ', 'T'))
      if (!isNaN(d)) {
        last_time_str = `${pad_zero(d.getHours())}:${pad_zero(d.getMinutes())}`
        last_date_str = d.toISOString().split('T')[0]
      }
    }
  }

  const total_hours_dec = total_ms / (1000 * 60 * 60)
  const days_count = unique_days.size
  const avg_hours_dec = days_count > 0 ? (total_hours_dec / days_count) : 0

  const total_h = Math.floor(total_hours_dec)
  const total_m = Math.round((total_hours_dec - total_h) * 60)

  const avg_h = Math.floor(avg_hours_dec)
  const avg_m = Math.round((avg_hours_dec - avg_h) * 60)

  return {
    total_hours: `${total_h}h ${pad_zero(total_m)}m`,
    days_worked: days_count,
    avg_daily_hours: `${avg_h}h ${pad_zero(avg_m)}m`,
    last_time: last_time_str,
    last_date: last_date_str
  }
})

/* --- Liste des Sessions Récentes --- */
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
  router.push('/workingTimes')
}

onMounted(load_dashboard_data)
watch(() => props.userId, load_dashboard_data)
</script>

<template>
  <div class="dashboard-container">
    <!-- Top 4 KPIs dynamiques -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-icon icon-blue">
          <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Total Working Hours</span>
          <div class="kpi-value-row">
            <span class="kpi-value">{{ kpi_data.total_hours }}</span>
            <span class="kpi-sub">Total cumulé</span>
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon icon-sky">
          <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Days Worked</span>
          <div class="kpi-value-row">
            <span class="kpi-value">{{ kpi_data.days_worked }}</span>
            <span class="kpi-sub">Jours actifs</span>
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon icon-indigo">
          <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Average Daily Hours</span>
          <div class="kpi-value-row">
            <span class="kpi-value">{{ kpi_data.avg_daily_hours }}</span>
            <span class="kpi-sub">Moyenne / jour</span>
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon icon-green">
          <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Last Working Time</span>
          <div class="kpi-value-row">
            <span class="kpi-value">{{ kpi_data.last_time }}</span>
            <span class="kpi-sub">{{ kpi_data.last_date }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Section Centrale Pleine Hauteur : Bar Chart & Table -->
    <div class="middle-grid">
      <!-- Working Hours (This Week) -->
      <div class="dash-card">
        <h3 class="card-title">Working Hours (This Week)</h3>
        <div class="dash-chart-container">
          <ChartInterface type="bar" :chart-data="bar_chart_data" :chart-options="bar_chart_options" />
        </div>
      </div>

      <!-- Recent Working Times -->
      <div class="dash-card">
        <div class="card-header-flex">
          <h3 class="card-title">Recent Working Times</h3>
        </div>
        <table class="recent-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Clock In</th>
              <th>Clock Out</th>
              <th>Duration</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in recent_working_times" :key="item.id">
              <td>{{ item.date }}</td>
              <td>{{ item.clock_in }}</td>
              <td>{{ item.clock_out }}</td>
              <td>{{ item.duration }}</td>
            </tr>
            <tr v-if="recent_working_times.length === 0">
              <td colspan="4" class="empty">Aucune donnée récente.</td>
            </tr>
          </tbody>
        </table>
        <div class="view-all-link" @click="go_to_working_times">
          View all working times →
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dashboard-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
  min-height: calc(100vh - 120px);
  box-sizing: border-box;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

.kpi-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 24px 20px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 4px 16px rgba(30,42,74,0.04);
  display: flex;
  align-items: center;
  gap: 16px;
}

.kpi-icon {
  width: 48px; height: 48px;
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}

.icon-blue { background: #eff6ff; color: #2563eb; }
.icon-sky { background: #f0f9ff; color: #0284c7; }
.icon-indigo { background: #eef2ff; color: #4f46e5; }
.icon-green { background: #ecfdf5; color: #10b981; }

.kpi-info { display: flex; flex-direction: column; gap: 4px; }
.kpi-label { font-size: 13px; color: #64748b; font-weight: 500; }
.kpi-value-row { display: flex; align-items: baseline; gap: 8px; }
.kpi-value { font-size: 22px; font-weight: 700; color: #0f172a; }
.kpi-sub { font-size: 11.5px; color: #94a3b8; }

.middle-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  flex: 1;
}

.dash-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 28px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 4px 16px rgba(30,42,74,0.04);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
  box-sizing: border-box;
}

.card-title { font-size: 16px; font-weight: 700; color: #1e293b; margin-bottom: 20px; }

.dash-chart-container {
  height: 340px;
  position: relative;
  width: 100%;
}

.recent-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

.recent-table th {
  text-align: left;
  color: #64748b;
  font-weight: 600;
  padding-bottom: 14px;
  border-bottom: 1px solid #f1f5f9;
}

.recent-table td {
  padding: 14px 0;
  color: #334155;
  border-bottom: 1px solid #f8fafc;
}

.view-all-link {
  margin-top: 20px;
  align-self: flex-end;
  font-size: 13.5px;
  font-weight: 600;
  color: #2563eb;
  cursor: pointer;
  transition: color 0.15s;
}

.view-all-link:hover { color: #1d4ed8; text-decoration: underline; }
.empty { text-align: center; color: #94a3b8; padding: 30px 0; }

@media (max-width: 1100px) {
  .kpi-grid { grid-template-columns: repeat(2, 1fr); }
  .middle-grid { grid-template-columns: 1fr; }
}
</style>
