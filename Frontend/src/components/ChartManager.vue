<script setup>
import { ref, onMounted, watch } from 'vue'
import axios from 'axios'
import ChartInterface from './ChartInterface.vue'

const props = defineProps({
  userId: {
    required: true
  }
})

const line_data = ref({ labels: [], datasets: [] })
const bar_data = ref({ labels: [], datasets: [] })

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
  scales: {
    y: {
      min: 6,
      max: 22,
      ticks: { stepSize: 4, callback: v => v + 'h' },
      grid: { color: '#f1f5f9' }
    },
    x: { grid: { display: false } }
  }
}

const bar_options = {
  ...base_options,
  scales: {
    y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: '#f1f5f9' } },
    x: { grid: { display: false } }
  }
}

async function load_charts_data() {
  try {
    const { data } = await axios.get(`http://localhost:4000/api/clocks/${props.userId}`)
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

    // 1. Line Chart (Horaires de pointage sur 7 jours)
    const days_list = Object.values(days_map).slice(-7)
    line_data.value = {
      labels: days_list.map(d => d.label),
      datasets: [
        { label: 'Clock In', data: days_list.map(d => d.in), borderColor: '#10b981', backgroundColor: '#10b981', tension: 0.2, pointRadius: 5 },
        { label: 'Clock Out', data: days_list.map(d => d.out), borderColor: '#ef4444', backgroundColor: '#ef4444', tension: 0.2, pointRadius: 5 }
      ]
    }

    // 2. Bar Chart (Fréquence des pointages par heure)
    const active_hours = Array.from({ length: 24 }, (_, i) => i).filter(h => hours_in[h] || hours_out[h])
    bar_data.value = {
      labels: active_hours.length ? active_hours.map(h => `${String(h).padStart(2, '0')}h`) : ['-'],
      datasets: [
        { label: 'Clock In', data: active_hours.map(h => hours_in[h]), backgroundColor: '#10b981', borderRadius: 4 },
        { label: 'Clock Out', data: active_hours.map(h => hours_out[h]), backgroundColor: '#ef4444', borderRadius: 4 }
      ]
    }
  } catch (err) {
    console.error('Erreur chargement charts:', err)
  }
}

onMounted(load_charts_data)
watch(() => props.userId, load_charts_data)
</script>

<template>
  <div class="charts-wrapper">
    <!-- Graphique 1 : Horaires de pointage -->
    <div class="chart-card">
      <div class="chart-header">
        <div class="chart-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <div>
          <h3>Horaires de pointage</h3>
          <p>Heures d'arrivée et de départ sur 7 jours</p>
        </div>
      </div>
      <div class="chart-container">
        <ChartInterface type="line" :chart-data="line_data" :chart-options="line_options" />
      </div>
    </div>

    <!-- Graphique 2 : Fréquence des pointages -->
    <div class="chart-card">
      <div class="chart-header">
        <div class="chart-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        </div>
        <div>
          <h3>Fréquence des pointages</h3>
          <p>Nombre de Clock In / Clock Out par heure</p>
        </div>
      </div>
      <div class="chart-container">
        <ChartInterface type="bar" :chart-data="bar_data" :chart-options="bar_options" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.charts-wrapper {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.chart-card {
  background: #ffffff;
  border-radius: 14px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(30,42,74,0.04);
  border: 1px solid #f1f5f9;
  overflow: hidden;
}

.chart-header {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.chart-icon {
  color: #2563eb;
  background: #eff6ff;
  padding: 10px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.chart-header h3 {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 2px;
}

.chart-header p {
  font-size: 12.5px;
  color: #94a3b8;
}

.chart-container {
  position: relative;
  width: 100%;
  height: 280px;
}

@media (max-width: 900px) {
  .charts-wrapper {
    grid-template-columns: 1fr;
  }
}
</style>