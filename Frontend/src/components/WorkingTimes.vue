<template>
  <div class="working-times-container">
    <header class="header">
      <div class="header-title">
        <div class="header-badge">
          <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
            <line x1="16" y1="2" x2="16" y2="6"/>
            <line x1="8" y1="2" x2="8" y2="6"/>
            <line x1="3" y1="10" x2="21" y2="10"/>
          </svg>
        </div>
        <div>
          <h2>Working Times</h2>
          <p class="subtitle">View and manage your working times. You can also create new working times manually.</p>
        </div>
      </div>
      <router-link to="/workingTime" class="add-btn">+ Add Working Time</router-link>
    </header>

    <div v-if="errorMessage" class="alert alert-danger">{{ errorMessage }}</div>

    <section class="stats-grid">
      <div class="kpi-card">
        <div class="kpi-icon-box green">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
          </svg>
        </div>
        <div class="kpi-content">
          <span class="kpi-label">Total Hours</span>
          <span class="kpi-value">{{ stats.totalHours }}</span>
          <span class="kpi-trend text-green">↑ Total cumulé</span>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon-box blue">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
            <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
          </svg>
        </div>
        <div class="kpi-content">
          <span class="kpi-label">Days Worked</span>
          <span class="kpi-value">{{ stats.daysWorked }}</span>
          <span class="kpi-trend text-blue">↑ Jours travaillés</span>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon-box purple">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
          </svg>
        </div>
        <div class="kpi-content">
          <span class="kpi-label">Regular Hours</span>
          <span class="kpi-value">{{ stats.avgHours }}</span>
          <span class="kpi-trend text-purple">↑ Moyenne / jour</span>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon-box orange">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
            <polyline points="22 4 12 14.01 9 11.01"/>
          </svg>
        </div>
        <div class="kpi-content">
          <span class="kpi-label">Plages Enregistrées</span>
          <span class="kpi-value">{{ stats.totalEntries }}</span>
          <span class="kpi-trend text-orange">↑ Sessions déclarées</span>
        </div>
      </div>
    </section>

    <div class="middle-grid">
      <div class="form-col">
        <WorkingTime 
          :user-id="userId" 
          :working-time-id="selectedId" 
          @refresh-list="onWorkingTimeUpdated" 
          @cancel-edit="selectedId = null" 
        />
      </div>

      <div class="tip-col">
        <div class="tip-card">
          <div class="tip-header">
            <div class="tip-icon-box">
              <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M12 2a7 7 0 0 0-7 7c0 2.38 1.19 4.47 3 5.74V17a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-2.26c1.81-1.27 3-3.36 3-5.74a7 7 0 0 0-7-7z"/>
                <line x1="10" y1="22" x2="14" y2="22"/>
              </svg>
            </div>
            <h3>Astuce & Organisation</h3>
          </div>
          <p class="tip-text">
            Sélectionnez une date, une heure de début et de fin, puis cliquez sur <strong>+ Créer</strong>.
          </p>
          <ul class="tip-list">
            <li><strong>Modifier :</strong> Cliquez sur <em>Modifier</em> dans le tableau pour charger une fiche.</li>
            <li><strong>Supprimer :</strong> Cliquez sur la poubelle pour retirer une plage horaire.</li>
            <li><strong>Filtrer :</strong> Utilisez les menus déroulants sous <em>Date</em> pour filtrer par mois et année.</li>
          </ul>
          <div class="target-grid">
            <div class="target-card">
              <span class="target-label">Objectif Standard</span>
              <span class="target-val blue">35.0 h / semaine</span>
            </div>
            <div class="target-card">
              <span class="target-label">Moyenne Quotidienne</span>
              <span class="target-val purple">{{ stats.avgHours }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="table-card">
      <div class="table-header">
        <div class="table-title">
          <div class="table-icon-box">
            <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="8" y1="6" x2="21" y2="6"/>
              <line x1="8" y1="12" x2="21" y2="12"/>
              <line x1="8" y1="18" x2="21" y2="18"/>
              <line x1="3" y1="6" x2="3.01" y2="6"/>
              <line x1="3" y1="12" x2="3.01" y2="12"/>
              <line x1="3" y1="18" x2="3.01" y2="18"/>
            </svg>
          </div>
          <h3>Working Times List</h3>
        </div>
        <span class="count">{{ filteredWorkingTimes.length }} enregistrement(s)</span>
      </div>

      <div class="table-responsive">
        <table class="table">
          <thead>
            <tr>
              <th class="th-date">
                <div class="th-label">Date</div>
                <div class="filters-row">
                  <select v-model="filterMonth" class="filter-select">
                    <option value="">Tous les mois</option>
                    <option value="1">Janvier</option>
                    <option value="2">Février</option>
                    <option value="3">Mars</option>
                    <option value="4">Avril</option>
                    <option value="5">Mai</option>
                    <option value="6">Juin</option>
                    <option value="7">Juillet</option>
                    <option value="8">Août</option>
                    <option value="9">Septembre</option>
                    <option value="10">Octobre</option>
                    <option value="11">Novembre</option>
                    <option value="12">Décembre</option>
                  </select>

                  <select v-model="filterYear" class="filter-select">
                    <option value="">Toutes les années</option>
                    <option v-for="y in availableYears" :key="y" :value="y">{{ y }}</option>
                  </select>

                  <button v-if="filterMonth || filterYear" @click="resetFilters" class="btn-clear-filter" title="Effacer le filtre">✕</button>
                </div>
              </th>

              <th class="th-duration">Durée</th>

              <th class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="wt in filteredWorkingTimes" :key="wt.id" :class="{ selected: selectedId === wt.id }">
              <td class="td-date">
                <div class="date-cell">
                  <span class="date-primary">{{ formatDate(wt.start) }}</span>
                  <span class="hours-secondary">{{ formatHours(wt.start, wt.end) }}</span>
                </div>
              </td>

              <td class="td-duration">
                <span class="badge">{{ getDuration(wt.start, wt.end) }}</span>
              </td>

              <td class="td-actions">
                <button type="button" @click="handleEdit(wt.id)" class="action-btn btn-edit" title="Modifier cette fiche">
                  <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                  <span>Modifier</span>
                </button>
                <button type="button" @click="deleteWorkingTime(wt.id)" class="action-btn btn-delete" title="Supprimer">
                  <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="3 6 5 6 21 6"/>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                  </svg>
                </button>
              </td>
            </tr>

            <tr v-if="filteredWorkingTimes.length === 0">
              <td colspan="3" class="empty-cell">
                <div class="empty-state">
                  <div class="empty-icon-box">
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
                    </svg>
                  </div>
                  <p class="empty-text">Aucun enregistrement trouvé.</p>
                  <span class="empty-sub">
                    {{ workingTimes.length === 0 ? 'Utilisez le formulaire ci-dessus pour ajouter votre premier temps de travail.' : 'Aucun résultat pour ce filtre.' }}
                  </span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import WorkingTime from './WorkingTime.vue'

const API_URL = 'http://localhost:4000/api'
const route = useRoute()

const props = defineProps({
  userId: { type: [Number, String], default: null }
})

const resolveUserId = () => {
  const fromRoute = route?.params?.userID || route?.params?.userid
  if (fromRoute) return Number(fromRoute)
  if (props.userId) return Number(props.userId)
  return 1
}

const userId = ref(resolveUserId())
const workingTimes = ref([])
const selectedId = ref(null)
const errorMessage = ref('')

const filterMonth = ref('')
const filterYear = ref('')

const stats = computed(() => {
  const list = workingTimes.value || []
  if (list.length === 0) {
    return {
      totalHours: '0.0 h',
      daysWorked: 0,
      avgHours: '0.0 h',
      totalEntries: 0
    }
  }

  let totalMs = 0
  const uniqueDays = new Set()

  list.forEach(wt => {
    if (!wt.start || !wt.end) return
    const s = new Date(wt.start.replace(' ', 'T')).getTime()
    const e = new Date(wt.end.replace(' ', 'T')).getTime()
    if (!isNaN(s) && !isNaN(e) && e > s) {
      totalMs += (e - s)
    }
    uniqueDays.add(wt.start.slice(0, 10))
  })

  const totalHours = totalMs / (1000 * 60 * 60)
  const daysCount = uniqueDays.size
  const avg = daysCount > 0 ? (totalHours / daysCount) : 0

  return {
    totalHours: `${totalHours.toFixed(1)} h`,
    daysWorked: daysCount,
    avgHours: `${avg.toFixed(1)} h`,
    totalEntries: list.length
  }
})

const availableYears = computed(() => {
  const years = new Set()
  workingTimes.value.forEach(wt => {
    if (wt.start) {
      const y = new Date(wt.start.replace(' ', 'T')).getFullYear()
      if (!isNaN(y)) years.add(y)
    }
  })
  if (years.size === 0) years.add(new Date().getFullYear())
  return Array.from(years).sort((a, b) => b - a)
})

const filteredWorkingTimes = computed(() => {
  return workingTimes.value.filter(wt => {
    if (!wt.start) return false
    const d = new Date(wt.start.replace(' ', 'T'))
    const matchMonth = !filterMonth.value || (d.getMonth() + 1) === Number(filterMonth.value)
    const matchYear = !filterYear.value || d.getFullYear() === Number(filterYear.value)
    return matchMonth && matchYear
  })
})

function resetFilters() {
  filterMonth.value = ''
  filterYear.value = ''
}

async function getWorkingTimes() {
  errorMessage.value = ''
  try {
    const res = await axios.get(`${API_URL}/workingtime/${userId.value}`)
    workingTimes.value = res.data.data || res.data || []
  } catch (err) {
    console.warn("Serveur Phoenix non joignable :", err.message)
    errorMessage.value = "Impossible de joindre le serveur Phoenix (port 4000). Vérifiez que `mix phx.server` est lancé."
  }
}

async function onWorkingTimeUpdated(newItem) {
  selectedId.value = null
  try {
    const res = await axios.get(`${API_URL}/workingtime/${userId.value}`)
    workingTimes.value = res.data.data || res.data || []
    errorMessage.value = ''
    return
  } catch (err) {
    if (newItem) {
      const idx = workingTimes.value.findIndex(item => item.id === newItem.id)
      if (idx !== -1) {
        workingTimes.value[idx] = newItem
      } else {
        workingTimes.value.unshift(newItem)
      }
    }
  }
}

async function deleteWorkingTime(id) {
  if (!confirm(`Supprimer la fiche #${id} ?`)) return
  try {
    await axios.delete(`${API_URL}/workingtime/${id}`)
    await getWorkingTimes()
  } catch (err) {
    console.warn("Erreur suppression API, retrait local :", err.message)
    workingTimes.value = workingTimes.value.filter(item => item.id !== id)
  }
  if (selectedId.value === id) selectedId.value = null
}

function handleEdit(id) {
  selectedId.value = id
  const mainEl = document.querySelector('.main-content')
  if (mainEl) {
    mainEl.scrollTo({ top: 0, behavior: 'smooth' })
  } else {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

function formatDate(isoStr) {
  if (!isoStr) return '-'
  const d = new Date(isoStr.replace(' ', 'T'))
  return d.toLocaleDateString('fr-FR', { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' })
}

function formatHours(startStr, endStr) {
  if (!startStr || !endStr) return ''
  const s = new Date(startStr.replace(' ', 'T'))
  const e = new Date(endStr.replace(' ', 'T'))
  const pad = (n) => n.toString().padStart(2, '0')
  const startTime = `${pad(s.getHours())}:${pad(s.getMinutes())}`
  const endTime = `${pad(e.getHours())}:${pad(e.getMinutes())}`
  
  if (s.toDateString() !== e.toDateString()) {
    const endDay = e.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' })
    return `${startTime} → ${endDay} ${endTime}`
  }
  return `${startTime} → ${endTime}`
}

function getDuration(startStr, endStr) {
  if (!startStr || !endStr) return '- h'
  const start = new Date(startStr.replace(' ', 'T'))
  const end = new Date(endStr.replace(' ', 'T'))
  const hours = (end - start) / (1000 * 60 * 60)
  return `${hours.toFixed(1)} h`
}

watch(() => [props.userId, route?.params?.userID], ([newPropId, newRouteId]) => {
  const nextId = newRouteId || newPropId
  if (nextId) {
    userId.value = Number(nextId)
    getWorkingTimes()
  }
})

onMounted(() => {
  getWorkingTimes()
})

defineExpose({
  userId,
  workingTimes,
  getWorkingTimes
})
</script>


<style scoped>
.working-times-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
  max-width: 1040px;
  margin: 0 auto;
}

.header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
.header-title { display: flex; align-items: center; gap: 12px; }
.header-badge {
  width: 44px; height: 44px; border-radius: 10px;
  background: #eff6ff; color: #2563eb;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.header h2 { margin: 0; color: #1e293b; font-size: 22px; font-weight: 700; }
.subtitle { margin: 3px 0 0; color: #64748b; font-size: 13.5px; }
.add-btn {
  padding: 10px 18px; background: #2563eb; color: #ffffff; text-decoration: none;
  font-size: 14px; font-weight: 600; border-radius: 8px; transition: background 0.15s;
}
.add-btn:hover { background: #1d4ed8; }

/* KPIs */
.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
.kpi-card {
  display: flex; align-items: center; gap: 14px;
  background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
  padding: 16px 18px; box-shadow: 0 2px 8px rgba(0,0,0,0.02);
}
.kpi-icon-box {
  width: 42px; height: 42px; border-radius: 50%; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  background: var(--bg); color: var(--fg);
}
.kpi-icon-box.green  { --bg: #dcfce7; --fg: #16a34a; }
.kpi-icon-box.blue   { --bg: #dbeafe; --fg: #2563eb; }
.kpi-icon-box.purple { --bg: #ede9fe; --fg: #7c3aed; }
.kpi-icon-box.orange { --bg: #fef3c7; --fg: #d97706; }

.kpi-content { display: flex; flex-direction: column; }
.kpi-label { font-size: 12px; font-weight: 600; color: #64748b; }
.kpi-value { font-size: 20px; font-weight: 700; color: #0f172a; line-height: 1.2; }
.kpi-trend { font-size: 11px; font-weight: 500; margin-top: 2px; }
.text-green  { color: #16a34a; }
.text-blue, .target-val.blue   { color: #2563eb; }
.text-purple, .target-val.purple { color: #7c3aed; }
.text-orange { color: #d97706; }

.middle-grid { display: grid; grid-template-columns: 1.25fr 1fr; gap: 20px; align-items: stretch; }
.form-col, .tip-col { width: 100%; }

.tip-card {
  height: 100%; box-sizing: border-box;
  display: flex; flex-direction: column; justify-content: space-between;
  background: white; border: 1px solid #e2e8f0; border-radius: 12px;
  padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.03);
}
.tip-header { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.tip-icon-box {
  width: 32px; height: 32px; border-radius: 8px; flex-shrink: 0;
  background: #fef3c7; display: flex; align-items: center; justify-content: center;
}
.tip-header h3 { margin: 0; font-size: 16px; color: #1e293b; }
.tip-text { font-size: 13.5px; color: #64748b; margin: 0 0 12px; line-height: 1.4; }
.tip-list { margin: 0 0 16px; padding-left: 18px; font-size: 12.5px; color: #475569; line-height: 1.6; }

.target-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 14px; }
.target-card {
  display: flex; flex-direction: column;
  background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 11px 14px;
}
.target-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: #64748b; }
.target-val { font-size: 14px; font-weight: 700; margin-top: 4px; }

/* Tableau */
.table-card {
  width: 100%; box-sizing: border-box;
  background: white; border: 1px solid #e2e8f0; border-radius: 12px;
  padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.03);
}
.table-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.table-title { display: flex; align-items: center; gap: 10px; }
.table-icon-box {
  width: 32px; height: 32px; border-radius: 8px; flex-shrink: 0;
  background: #eff6ff; display: flex; align-items: center; justify-content: center;
}
.table-header h3 { margin: 0; font-size: 16px; color: #1e293b; }
.count { font-size: 13px; font-weight: 500; color: #64748b; }

.table-responsive { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; text-align: left; font-size: 14px; }
.table th, .table td { padding: 12px 14px; border-bottom: 1px solid #f1f5f9; }
.table th { background: #f8fafc; color: #475569; font-weight: 600; }

.th-date, .td-date { width: 48%; min-width: 260px; }
.th-duration, .td-duration { width: 24%; text-align: left; }
.th-actions, .td-actions { width: 28%; text-align: right; }
.th-label { display: block; margin-bottom: 6px; }

.filters-row { display: flex; align-items: center; gap: 8px; font-weight: normal; }
.filter-select {
  padding: 5px 8px; border: 1px solid #cbd5e1; border-radius: 6px;
  font-size: 12px; background: white; color: #334155; outline: none;
}
.btn-clear-filter {
  background: #fee2e2; border: 1px solid #fecaca; color: #dc2626;
  border-radius: 4px; padding: 4px 7px; font-size: 11px; font-weight: bold; cursor: pointer;
}

.selected { background: #eff6ff; }
.date-cell { display: flex; flex-direction: column; gap: 2px; }
.date-primary { font-weight: 600; color: #1e293b; }
.hours-secondary { font-size: 12px; color: #64748b; }

.badge {
  display: inline-block; background: #f1f5f9; color: #0f172a;
  border: 1px solid #e2e8f0; border-radius: 6px; padding: 4px 10px;
  font-weight: 600; font-size: 13px;
}

.action-btn {
  display: inline-flex; align-items: center; gap: 5px;
  border: 1px solid transparent; border-radius: 6px; padding: 6px 10px;
  font-size: 12px; font-weight: 600; margin-left: 6px; cursor: pointer;
  transition: all 0.15s;
}
.btn-edit { background: #eff6ff; color: #2563eb; border-color: #bfdbfe; }
.btn-edit:hover { background: #dbeafe; color: #1d4ed8; }
.btn-delete { background: #fef2f2; color: #dc2626; border-color: #fecaca; padding: 6px 8px; }
.btn-delete:hover { background: #fee2e2; color: #b91c1c; }

.empty-cell { padding: 40px 16px; text-align: center; }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 6px; }
.empty-icon-box {
  width: 48px; height: 48px; border-radius: 12px; margin-bottom: 4px;
  background: #f1f5f9; display: flex; align-items: center; justify-content: center;
}
.empty-text { font-size: 14px; font-weight: 600; color: #475569; margin: 0; }
.empty-sub { font-size: 12.5px; color: #94a3b8; }

.alert { padding: 10px 14px; border-radius: 8px; font-size: 13px; }
.alert-danger { background: #fee2e2; color: #dc2626; border: 1px solid #fecaca; }

@media (max-width: 960px) {
  .middle-grid { grid-template-columns: 1fr; }
  .stats-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 600px) {
  .stats-grid { grid-template-columns: 1fr; }
}
</style>