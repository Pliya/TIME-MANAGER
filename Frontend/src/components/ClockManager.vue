<script setup>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import axios from 'axios'
import ChartManager from './ChartManager.vue'

const props = defineProps({ userId: { required: true } })

const clocks = ref([])
const clockIn = ref(false)
const startDateTime = ref(null)
const elapsed = ref('0h 00min')

let timer = null
const pad = (n) => String(n).padStart(2, '0')

function updateElapsed() {
  if (!clockIn.value || !startDateTime.value) {
    elapsed.value = '0h 00min'
    return
  }
  const start = new Date(startDateTime.value.replace(' ', 'T'))
  const diff = new Date() - start
  if (isNaN(diff) || diff < 0) {
    elapsed.value = '0h 00min'
    return
  }
  const hrs = Math.floor(diff / 3600000)
  const mins = Math.floor((diff % 3600000) / 60000)
  elapsed.value = `${hrs}h ${pad(mins)}min`
}

async function refresh() {
  try {
    const { data } = await axios.get(`http://localhost:4000/api/clocks/${props.userId}`)
    clocks.value = data.data || []
    const last = clocks.value[clocks.value.length - 1]
    clockIn.value = last?.status || false
    startDateTime.value = last?.status ? last.time : null

    updateElapsed()
  } catch (err) {
    console.error('Erreur chargement clocks:', err)
  }
}

async function toggleClock() {
  try {
    const now = new Date()
    const time = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`
    await axios.post(`http://localhost:4000/api/clocks/${props.userId}`, {
      clock: { status: !clockIn.value, time }
    })
    await refresh()
  } catch (err) {
    console.error('Erreur pointage:', err)
  }
}

onMounted(() => { refresh(); timer = setInterval(updateElapsed, 60000) })
onUnmounted(() => clearInterval(timer))
watch(() => props.userId, refresh)

const formattedStartTime = computed(() => {
  if (!startDateTime.value) return '--:--'
  const d = new Date(startDateTime.value.replace(' ', 'T'))
  return isNaN(d) ? '--:--' : `${pad(d.getHours())}:${pad(d.getMinutes())}`
})

const formattedStartDate = computed(() => {
  if (!startDateTime.value) return '-'
  const d = new Date(startDateTime.value.replace(' ', 'T'))
  return isNaN(d) ? '-' : d.toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })
})

const recentClocks = computed(() => {
  return [...clocks.value].reverse().slice(0, 5).map(c => {
    const d = new Date(c.time.replace(' ', 'T'))
    const isToday = d.toDateString() === new Date().toDateString()
    return {
      id: c.id,
      status: c.status,
      timeLabel: `${pad(d.getHours())}:${pad(d.getMinutes())}`,
      dateLabel: isToday ? "Aujourd'hui" : d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' }),
      textLabel: c.status ? 'Arrivée' : 'Départ'
    }
  })
})
</script>

<template>
  <div class="clock-page">
    <p class="subtitle">Déclarez vos heures de travail en un clic.</p>

    <!-- Cartes Statut & Historique -->
    <div class="clock-manager-layout">
      <!-- STATUT ACTUEL -->
      <div class="status-card">
        <div class="status-header">
          <div class="status-ring" :class="{ active: clockIn }">
            <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 24 24" fill="none" :stroke="clockIn ? '#10b981' : '#94a3b8'" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          </div>
          <div>
            <div class="status-title" :class="clockIn ? 'text-green' : 'text-gray'">
              <span class="status-dot" :class="clockIn ? 'bg-green' : 'bg-gray'"></span>
              {{ clockIn ? 'Actuellement en service' : 'Hors service' }}
            </div>
            <p class="status-desc">{{ clockIn ? 'Vous avez pointé votre arrivée.' : "Vous n'êtes pas en cours d'activité." }}</p>
          </div>
        </div>

        <div class="status-details">
          <div class="detail-box">
            <div class="detail-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            </div>
            <div>
              <div class="detail-label">Heure de début</div>
              <div class="detail-val">{{ formattedStartTime }}</div>
              <div class="detail-sub">{{ formattedStartDate }}</div>
            </div>
          </div>

          <div class="detail-box">
            <div class="detail-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            </div>
            <div>
              <div class="detail-label">Durée actuelle</div>
              <div class="detail-val">{{ clockIn ? elapsed : '--' }}</div>
              <div class="detail-sub">{{ clockIn ? '(en cours)' : '-' }}</div>
            </div>
          </div>

          <button class="clock-btn" :class="clockIn ? 'btn-red' : 'btn-green'" @click="toggleClock">
            <span v-if="clockIn" style="display: flex; align-items: center; gap: 8px;">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/></svg> Clock Out
            </span>
            <span v-else style="display: flex; align-items: center; gap: 8px;">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg> Clock In
            </span>
          </button>
        </div>
      </div>

      <!-- DERNIERS POINTAGES -->
      <div class="history-card">
        <div class="card-title">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Derniers pointages
        </div>
        <ul class="history-list">
          <li v-for="c in recentClocks" :key="c.id">
            <span class="history-dot" :class="c.status ? 'bg-green' : 'bg-red'"></span>
            <span class="history-time">{{ c.timeLabel }}</span>
            <span class="history-label" :class="c.status ? 'text-green' : 'text-red'">{{ c.textLabel }}</span>
            <span class="history-date">{{ c.dateLabel }}</span>
          </li>
          <li v-if="recentClocks.length === 0" class="empty">Aucun pointage récent.</li>
        </ul>
        <a href="#" class="view-all">Voir tout l'historique →</a>
      </div>
    </div>

    <!-- STATISTIQUES CHARTS -->
    <div class="chart-section">
      <h3>Mes statistiques</h3>
      <p class="chart-subtitle">Suivez votre activité et vos heures de travail.</p>
      <ChartManager :userId="props.userId" />
    </div>
  </div>
</template>

<style scoped>
.clock-page { display: flex; flex-direction: column; gap: 24px; }
.subtitle { color: #8a97b5; font-size: 15px; margin-top: -8px; margin-bottom: 4px; }
.clock-manager-layout { display: grid; grid-template-columns: 2fr 1fr; gap: 20px; }
.status-card, .history-card {
  background: #ffffff; border-radius: 14px; padding: 28px 32px;
  box-shadow: 0 2px 8px rgba(30,42,74,0.04); border: 1px solid #f1f5f9;
}
.status-header { display: flex; gap: 24px; align-items: center; margin-bottom: 40px; }
.status-ring {
  width: 80px; height: 80px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  background: #f1f5f9; border: 6px solid #e2e8f0; transition: 0.3s;
}
.status-ring.active {
  background: #ecfdf5; border-color: #d1fae5; box-shadow: 0 0 20px rgba(16,185,129,0.15);
}
.status-title {
  display: flex; align-items: center; gap: 8px; font-size: 19px; font-weight: 700; margin-bottom: 6px;
}
.status-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
.bg-green { background: #10b981; } .text-green { color: #10b981; }
.bg-red { background: #ef4444; }   .text-red { color: #ef4444; }
.bg-gray { background: #94a3b8; }  .text-gray { color: #64748b; }
.status-desc { font-size: 14px; color: #64748b; margin-left: 18px; }

.status-details { display: flex; gap: 16px; align-items: center; }
.detail-box {
  background: #f8fafc; border-radius: 12px; padding: 18px 20px;
  display: flex; gap: 16px; align-items: flex-start; flex: 1; border: 1px solid #f1f5f9;
}
.detail-icon { color: #94a3b8; margin-top: 2px; }
.detail-label { font-size: 13px; color: #64748b; font-weight: 500; margin-bottom: 4px; }
.detail-val { font-size: 20px; font-weight: 700; color: #0f172a; margin-bottom: 2px; }
.detail-sub { font-size: 12px; color: #94a3b8; text-transform: capitalize; }

.clock-btn {
  padding: 0 28px; height: 75px; border-radius: 12px;
  border: none; color: #fff; font-size: 16px; font-weight: 700;
  cursor: pointer; display: flex; align-items: center; gap: 8px; justify-content: center;
  transition: opacity 0.2s, transform 0.1s; white-space: nowrap; box-shadow: 0 4px 12px rgba(239,68,68,0.2);
}
.clock-btn:hover { opacity: 0.9; transform: translateY(-1px); }
.clock-btn:active { transform: translateY(1px); }
.btn-red { background: #ef4444; box-shadow: 0 4px 12px rgba(239,68,68,0.25); }
.btn-green { background: #10b981; box-shadow: 0 4px 12px rgba(16,185,129,0.25); color: #fff; }

.card-title {
  display: flex; align-items: center; gap: 10px; font-size: 16px; font-weight: 700; color: #1e293b; margin-bottom: 24px;
}
.history-list { list-style: none; padding: 0; margin: 0 0 24px 0; display: flex; flex-direction: column; gap: 18px; }
.history-list li { display: flex; align-items: center; gap: 14px; font-size: 14px; }
.history-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.history-time { font-weight: 700; color: #334155; width: 45px; }
.history-label { font-weight: 600; flex: 1; }
.history-date { color: #94a3b8; font-size: 13px; text-transform: capitalize; }
.view-all { color: #2563eb; font-size: 13.5px; font-weight: 600; text-decoration: none; }
.empty { color: #94a3b8; }

.chart-section { margin-top: 12px; }
.chart-section h3 { font-size: 18px; font-weight: 700; color: #1e2a4a; margin-bottom: 4px; }
.chart-subtitle { color: #8a97b5; font-size: 14px; margin-bottom: 20px; }
</style>