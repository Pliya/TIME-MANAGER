<script setup>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import axios from 'axios'

const props = defineProps({ userId: { required: true } })

const clocks_list = ref([])
const is_clocked_in = ref(false)
const start_date_time = ref(null)
const elapsed_time = ref('00:00:00')

let timer_interval = null
const pad_zero = (n) => String(n).padStart(2, '0')

function update_elapsed_time() {
  if (!is_clocked_in.value || !start_date_time.value) {
    elapsed_time.value = '00:00:00'
    return
  }
  const start_date = new Date(start_date_time.value.replace(' ', 'T'))
  const diff_ms = new Date() - start_date
  if (isNaN(diff_ms) || diff_ms < 0) {
    elapsed_time.value = '00:00:00'
    return
  }
  const total_seconds = Math.floor(diff_ms / 1000)
  const hours = Math.floor(total_seconds / 3600)
  const minutes = Math.floor((total_seconds % 3600) / 60)
  const seconds = total_seconds % 60
  elapsed_time.value = `${pad_zero(hours)}:${pad_zero(minutes)}:${pad_zero(seconds)}`
}

async function refresh_clocks() {
  try {
    const { data } = await axios.get(`http://localhost:4000/api/clocks/${props.userId}`)
    clocks_list.value = data.data || []
    const last_clock = clocks_list.value[clocks_list.value.length - 1]
    is_clocked_in.value = last_clock?.status || false
    start_date_time.value = last_clock?.status ? last_clock.time : null
    update_elapsed_time()
  } catch (err) {
    console.error('Erreur chargement clocks:', err)
  }
}

async function toggle_clock() {
  try {
    const now_date = new Date()
    const formatted_time = `${now_date.getFullYear()}-${pad_zero(now_date.getMonth() + 1)}-${pad_zero(now_date.getDate())} ${pad_zero(now_date.getHours())}:${pad_zero(now_date.getMinutes())}:${pad_zero(now_date.getSeconds())}`
    await axios.post(`http://localhost:4000/api/clocks/${props.userId}`, {
      clock: { status: !is_clocked_in.value, time: formatted_time }
    })
    await refresh_clocks()
  } catch (err) {
    console.error('Erreur pointage:', err)
  }
}

onMounted(() => {
  refresh_clocks()
  timer_interval = setInterval(update_elapsed_time, 1000)
})

onUnmounted(() => clearInterval(timer_interval))
watch(() => props.userId, refresh_clocks)

const formatted_start_time = computed(() => {
  if (!start_date_time.value) return '--:--:--'
  const d = new Date(start_date_time.value.replace(' ', 'T'))
  return isNaN(d) ? '--:--:--' : `${d.getFullYear()}-${pad_zero(d.getMonth() + 1)}-${pad_zero(d.getDate())} ${pad_zero(d.getHours())}:${pad_zero(d.getMinutes())}:${pad_zero(d.getSeconds())}`
})

const start_hour_only = computed(() => {
  if (!start_date_time.value) return '00:00'
  const d = new Date(start_date_time.value.replace(' ', 'T'))
  return isNaN(d) ? '00:00' : `${pad_zero(d.getHours())}:${pad_zero(d.getMinutes())}`
})

const last_working_times = computed(() => {
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
    if (result.length >= 8) break
  }
  return result
})
</script>

<template>
  <div class="clock-manager-grid">
    <!-- GAUCHE : Cadran Circulaire -->
    <div class="dial-card">
      <div class="circle-container">
        <svg class="circle-svg" viewBox="0 0 200 200">
          <circle class="circle-bg" cx="100" cy="100" r="85" />
          <circle
            class="circle-progress"
            :class="{ active: is_clocked_in }"
            cx="100" cy="100" r="85"
          />
        </svg>
        <div class="circle-content">
          <div class="status-indicator">
            <span class="status-dot-inner" :class="{ active: is_clocked_in }"></span>
            <span>Working</span>
          </div>
          <div class="since-text">Since {{ is_clocked_in ? start_hour_only : '--:--' }}</div>
          <div class="timer-display">{{ is_clocked_in ? elapsed_time : '00:00:00' }}</div>
        </div>
      </div>

      <button
        class="action-btn"
        :class="is_clocked_in ? 'btn-clock-out' : 'btn-clock-in'"
        @click="toggle_clock"
      >
        {{ is_clocked_in ? 'Clock Out' : 'Clock In' }}
      </button>
    </div>

    <!-- DROITE : Session Actuelle & Table des Derniers Pointages -->
    <div class="details-col">
      <!-- Current Session -->
      <div class="session-card">
        <h3 class="card-subtitle">Current Session</h3>
        <div class="session-rows">
          <div class="session-row">
            <span class="label">Start Date & Time</span>
            <span class="val">{{ is_clocked_in ? formatted_start_time : '-' }}</span>
          </div>
          <div class="session-row">
            <span class="label">Status</span>
            <span class="val status-text" :class="{ 'in-progress': is_clocked_in }">
              <span class="dot" :class="{ green: is_clocked_in }"></span>
              {{ is_clocked_in ? 'In Progress' : 'Stopped' }}
            </span>
          </div>
          <div class="session-row">
            <span class="label">Duration</span>
            <span class="val">{{ is_clocked_in ? elapsed_time : '0h 00m' }}</span>
          </div>
        </div>
      </div>

      <!-- Last Working Times -->
      <div class="last-times-card">
        <h3 class="card-subtitle">Last Working Times</h3>
        <table class="times-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Clock In</th>
              <th>Clock Out</th>
              <th>Duration</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in last_working_times" :key="item.id">
              <td>{{ item.date }}</td>
              <td>{{ item.clock_in }}</td>
              <td>{{ item.clock_out }}</td>
              <td>{{ item.duration }}</td>
            </tr>
            <tr v-if="last_working_times.length === 0">
              <td colspan="4" class="empty">Aucune session enregistrée.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<style scoped>
.clock-manager-grid {
  display: grid;
  grid-template-columns: 380px 1fr;
  gap: 24px;
  min-height: calc(100vh - 120px);
  box-sizing: border-box;
}

/* --- Card Cadran --- */
.dial-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 48px 32px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 4px 16px rgba(30,42,74,0.04);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  box-sizing: border-box;
}

.circle-container {
  position: relative;
  width: 270px;
  height: 270px;
  margin-bottom: 36px;
}

.circle-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.circle-bg {
  fill: none;
  stroke: #f1f5f9;
  stroke-width: 10;
}

.circle-progress {
  fill: none;
  stroke: #cbd5e1;
  stroke-width: 10;
  stroke-dasharray: 534;
  stroke-dashoffset: 130;
  stroke-linecap: round;
  transition: stroke 0.3s;
}

.circle-progress.active {
  stroke: #10b981;
}

.circle-content {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  color: #64748b;
  margin-bottom: 6px;
}

.status-dot-inner {
  width: 9px; height: 9px;
  border-radius: 50%;
  background: #94a3b8;
}

.status-dot-inner.active {
  background: #10b981;
}

.since-text {
  font-size: 13px;
  color: #94a3b8;
  margin-bottom: 10px;
}

.timer-display {
  font-size: 32px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -0.02em;
}

.action-btn {
  width: 100%;
  max-width: 240px;
  padding: 14px 28px;
  border-radius: 12px;
  border: none;
  font-size: 16px;
  font-weight: 700;
  color: #fff;
  cursor: pointer;
  transition: transform 0.1s, opacity 0.2s;
}

.btn-clock-in {
  background: #2563eb;
  box-shadow: 0 4px 14px rgba(37,99,235,0.3);
}

.btn-clock-out {
  background: #ef4444;
  box-shadow: 0 4px 14px rgba(239,68,68,0.3);
}

.action-btn:hover { opacity: 0.92; transform: translateY(-1px); }

/* --- Colonne Droite --- */
.details-col {
  display: flex;
  flex-direction: column;
  gap: 24px;
  height: 100%;
}

.session-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 28px 32px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 4px 16px rgba(30,42,74,0.04);
}

.last-times-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 28px 32px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 4px 16px rgba(30,42,74,0.04);
  flex: 1;
  display: flex;
  flex-direction: column;
}

.card-subtitle {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 20px;
}

.session-rows {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.session-row {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
}

.session-row .label { color: #64748b; }
.session-row .val { font-weight: 600; color: #0f172a; }

.status-text {
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-text .dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: #94a3b8;
}

.status-text .dot.green { background: #10b981; }
.status-text.in-progress { color: #10b981; }

.times-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

.times-table th {
  text-align: left;
  color: #64748b;
  font-weight: 600;
  padding-bottom: 14px;
  border-bottom: 1px solid #f1f5f9;
}

.times-table td {
  padding: 16px 0;
  color: #334155;
  border-bottom: 1px solid #f8fafc;
}

.times-table tr:last-child td { border-bottom: none; }
.empty { text-align: center; color: #94a3b8; padding: 30px 0; }

@media (max-width: 960px) {
  .clock-manager-grid {
    grid-template-columns: 1fr;
    min-height: auto;
  }
}
</style>