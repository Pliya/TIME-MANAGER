<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import ChartInterface from './ChartInterface.vue'

const props = defineProps({ userId: { required: true } })
const router = useRouter()

const clocks_list = ref([])

const bar_chart_data = ref({
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  datasets: [{
    label: 'Working Hours',
    data: [7.5, 8.2, 7.8, 8.5, 6.4, 0, 0],
    backgroundColor: '#2563eb',
    borderRadius: 4
  }]
})

const bar_chart_options = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    y: { beginAtZero: true, max: 12, ticks: { stepSize: 3 } },
    x: { grid: { display: false } }
  }
}

async function load_dashboard_data() {
  try {
    const { data } = await axios.get(`http://localhost:4000/api/clocks/${props.userId}`)
    clocks_list.value = data.data || []
  } catch (err) {
    console.error('Erreur chargement dashboard:', err)
  }
}

const recent_working_times = computed(() => {
  const result = []
  const reversed = [...clocks_list.value].reverse()
  const pad = (n) => String(n).padStart(2, '0')
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
          clock_in: `${pad(clock_in_date.getHours())}:${pad(clock_in_date.getMinutes())}`,
          clock_out: `${pad(clock_out_date.getHours())}:${pad(clock_out_date.getMinutes())}`,
          duration: `${diff_h}h ${pad(diff_m)}m`
        })
      }
    }
    if (result.length >= 5) break
  }
  return result
})

function go_to_working_times() {
  router.push('/workingTimes')
}

onMounted(load_dashboard_data)
</script>

<template>
  <div class="dashboard-container">
    <!-- Top 4 KPIs -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-icon icon-blue">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Total Working Hours</span>
          <div class="kpi-value-row">
            <span class="kpi-value">38h 20m</span>
            <span class="kpi-sub">This week</span>
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon icon-sky">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Days Worked</span>
          <div class="kpi-value-row">
            <span class="kpi-value">5</span>
            <span class="kpi-sub">This week</span>
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon icon-indigo">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Average Daily Hours</span>
          <div class="kpi-value-row">
            <span class="kpi-value">7h 40m</span>
            <span class="kpi-sub">This week</span>
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon icon-green">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <div class="kpi-info">
          <span class="kpi-label">Last Working Time</span>
          <div class="kpi-value-row">
            <span class="kpi-value">18:05</span>
            <span class="kpi-sub">2026-09-25</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Middle Section: Bar Chart & Recent Table -->
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
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

.kpi-card {
  background: #ffffff;
  border-radius: 14px;
  padding: 20px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 2px 8px rgba(30,42,74,0.04);
  display: flex;
  align-items: center;
  gap: 16px;
}

.kpi-icon {
  width: 44px; height: 44px;
  border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}

.icon-blue { background: #eff6ff; color: #2563eb; }
.icon-sky { background: #f0f9ff; color: #0284c7; }
.icon-indigo { background: #eef2ff; color: #4f46e5; }
.icon-green { background: #ecfdf5; color: #10b981; }

.kpi-info { display: flex; flex-direction: column; gap: 4px; }
.kpi-label { font-size: 12px; color: #64748b; font-weight: 500; }
.kpi-value-row { display: flex; align-items: baseline; gap: 8px; }
.kpi-value { font-size: 20px; font-weight: 700; color: #0f172a; }
.kpi-sub { font-size: 11px; color: #94a3b8; }

.middle-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.dash-card {
  background: #ffffff;
  border-radius: 14px;
  padding: 24px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 2px 8px rgba(30,42,74,0.04);
  display: flex;
  flex-direction: column;
}

.card-title { font-size: 15px; font-weight: 700; color: #1e293b; margin-bottom: 16px; }

.dash-chart-container {
  height: 250px;
}

.recent-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13.5px;
}

.recent-table th {
  text-align: left;
  color: #64748b;
  font-weight: 600;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.recent-table td {
  padding: 10px 0;
  color: #334155;
  border-bottom: 1px solid #f8fafc;
}

.view-all-link {
  margin-top: 16px;
  align-self: flex-end;
  font-size: 13px;
  font-weight: 600;
  color: #2563eb;
  cursor: pointer;
  transition: color 0.15s;
}

.view-all-link:hover { color: #1d4ed8; text-decoration: underline; }
.empty { text-align: center; color: #94a3b8; padding: 20px 0; }
</style>
