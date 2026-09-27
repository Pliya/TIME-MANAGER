<script setup>
import { ref, onMounted, watch } from 'vue'
import axios from 'axios'
import ChartInterface from './ChartInterface.vue'

const props = defineProps({
  userId: {
    required: true
  }
})

/* --- Data Pointages (Clocking) --- */
const line_data = ref({ labels: [], datasets: [] })
const clock_bar_data = ref({ labels: [], datasets: [] })

/* --- Data Working Times --- */
const wt_bar_data = ref({ labels: [], datasets: [] })
const wt_pie_data = ref({ labels: [], datasets: [] })

/* --- Options Graphiques --- */
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

const clock_bar_options = {
  ...base_options,
  scales: {
    y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: '#f1f5f9' } },
    x: { grid: { display: false } }
  }
}

const wt_bar_options = {
  ...base_options,
  scales: {
    y: {
      beginAtZero: true,
      max: 12,
      ticks: { stepSize: 2, callback: v => v + 'h' },
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
      position: 'right',
      labels: { usePointStyle: true, boxWidth: 8, font: { size: 12 } }
    }
  }
}

/* --- Chargement des Pointages (Clocking) --- */
async function load_clocks_data() {
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

    // 1. Line Chart (Horaires de pointage)
    const days_list = Object.values(days_map).slice(-7)
    line_data.value = {
      labels: days_list.map(d => d.label),
      datasets: [
        { label: 'Clock In', data: days_list.map(d => d.in), borderColor: '#10b981', backgroundColor: '#10b981', tension: 0.2, pointRadius: 5 },
        { label: 'Clock Out', data: days_list.map(d => d.out), borderColor: '#ef4444', backgroundColor: '#ef4444', tension: 0.2, pointRadius: 5 }
      ]
    }

    // 2. Bar Chart (Fréquence des pointages)
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

/* --- Chargement des Temps de Travail (Working Times) --- */
async function load_working_times_data() {
  try {
    const { data } = await axios.get(`http://localhost:4000/api/workingtime/${props.userId}`)
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

    // 3. Bar Chart Working Times (Durée travaillée par jour)
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

    // 4. Pie Chart Working Times (Répartition du temps travaillé par jour)
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

function load_all_charts() {
  load_clocks_data()
  load_working_times_data()
}

onMounted(load_all_charts)
watch(() => props.userId, load_all_charts)
</script>

<template>
  <div class="charts-page-container">

    <!-- SECTION 1 : STATISTIQUES DES POINTAGES -->
    <div class="section-block">
      <div class="section-title">
        <div class="section-badge">⏱️</div>
        <h2>Statistiques des Pointages</h2>
      </div>

      <div class="charts-grid">
        <!-- Graphique 1 : Horaires de pointage -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-icon icon-blue">
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
            <div class="chart-icon icon-indigo">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
            </div>
            <div>
              <h3>Fréquence des pointages</h3>
              <p>Nombre de Clock In / Clock Out par heure</p>
            </div>
          </div>
          <div class="chart-container">
            <ChartInterface type="bar" :chart-data="clock_bar_data" :chart-options="clock_bar_options" />
          </div>
        </div>
      </div>
    </div>

    <!-- SECTION 2 : TEMPS DE TRAVAIL (WORKING TIMES) -->
    <div class="section-block">
      <div class="section-title">
        <div class="section-badge">📅</div>
        <h2>Statistiques des Temps de Travail</h2>
      </div>

      <div class="charts-grid">
        <!-- Graphique 3 : Durée travaillée par jour (Bar Chart) -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-icon icon-sky">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            </div>
            <div>
              <h3>Durée travaillée par jour</h3>
              <p>Heures cumulées par journée de travail</p>
            </div>
          </div>
          <div class="chart-container">
            <ChartInterface type="bar" :chart-data="wt_bar_data" :chart-options="wt_bar_options" />
          </div>
        </div>

        <!-- Graphique 4 : Répartition du temps travaillé par jour (Pie Chart) -->
        <div class="chart-card">
          <div class="chart-header">
            <div class="chart-icon icon-purple">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/></svg>
            </div>
            <div>
              <h3>Répartition du temps travaillé</h3>
              <p>Proportion (%) du temps total par jour</p>
            </div>
          </div>
          <div class="chart-container">
            <ChartInterface type="pie" :chart-data="wt_pie_data" :chart-options="wt_pie_options" />
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.charts-page-container {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.section-block {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 10px;
}

.section-badge {
  font-size: 18px;
}

.section-title h2 {
  font-size: 17px;
  font-weight: 700;
  color: #1e293b;
  margin: 0;
}

.charts-grid {
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
  padding: 10px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-blue { color: #2563eb; background: #eff6ff; }
.icon-indigo { color: #4f46e5; background: #eef2ff; }
.icon-sky { color: #0284c7; background: #f0f9ff; }
.icon-purple { color: #9333ea; background: #faf5ff; }

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
  .charts-grid {
    grid-template-columns: 1fr;
  }
}
</style>