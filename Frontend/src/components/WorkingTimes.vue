<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import { API_URL } from '@/api'
import WorkingTime from './WorkingTime.vue'
import StatCard from './StatCard.vue'
import { computeKpi, hoursToText } from '@/utils/kpi'
import { Clock, CalendarCheck, TrendingUp, CalendarDays, Pencil, Trash2, X } from 'lucide-vue-next'

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

const stats = computed(() => computeKpi(workingTimes.value))

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
  return hoursToText(hours)
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

<template>
  <div class="space-y-6">
    <p v-if="errorMessage" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ errorMessage }}</p>

    <div class="grid grid-cols-2 gap-4 lg:gap-6 xl:grid-cols-4">
      <StatCard label="Total Hours" :value="stats.totalHours" hint="Total cumulé" :icon="Clock" />
      <StatCard label="Days Worked" :value="stats.daysWorked" hint="Jours travaillés" :icon="CalendarCheck" />
      <StatCard label="Regular Hours" :value="stats.avgHours" hint="Moyenne / jour" :icon="TrendingUp" />
      <StatCard label="Plages Enregistrées" :value="stats.totalEntries" hint="Sessions déclarées" :icon="CalendarDays" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <WorkingTime
        :user-id="userId"
        :working-time-id="selectedId"
        @refresh-list="onWorkingTimeUpdated"
        @cancel-edit="selectedId = null"
      />

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
          <p class="font-medium">Working Times List <span class="text-neutral-400">({{ filteredWorkingTimes.length }})</span></p>
          <div class="flex flex-wrap items-center gap-2">
            <select v-model="filterMonth" class="rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
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
            <select v-model="filterYear" class="rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option value="">Toutes les années</option>
              <option v-for="y in availableYears" :key="y" :value="y">{{ y }}</option>
            </select>
            <button v-if="filterMonth || filterYear" class="rounded-lg p-1.5 text-neutral-400 hover:bg-neutral-100" title="Effacer le filtre" @click="resetFilters">
              <X class="h-4 w-4" />
            </button>
          </div>
        </div>

        <div class="max-h-[28rem] overflow-auto">
          <table class="w-full min-w-max text-sm">
            <thead class="sticky top-0 z-10">
              <tr class="bg-neutral-50 text-left text-neutral-500">
                <th class="rounded-l-lg px-3 py-3 font-medium sm:px-4">Date</th>
                <th class="px-3 py-3 font-medium sm:px-4">Durée</th>
                <th class="rounded-r-lg px-3 py-3 sm:px-4"></th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="wt in filteredWorkingTimes"
                :key="wt.id"
                class="border-b border-neutral-100 last:border-0"
                :class="{ 'bg-neutral-100': selectedId === wt.id }"
              >
                <td class="px-3 py-3 sm:px-4">
                  <p class="font-medium">{{ formatDate(wt.start) }}</p>
                  <p class="text-neutral-500">{{ formatHours(wt.start, wt.end) }}</p>
                </td>
                <td class="px-3 py-3 sm:px-4">
                  <span class="rounded-full bg-neutral-100 px-2.5 py-1 text-xs font-medium">{{ getDuration(wt.start, wt.end) }}</span>
                </td>
                <td class="px-3 py-3 sm:px-4">
                  <div class="flex justify-end gap-1">
                    <button type="button" class="flex items-center gap-1 rounded-lg px-2 py-1.5 text-neutral-500 hover:bg-neutral-100 hover:text-neutral-900" title="Modifier cette fiche" @click="handleEdit(wt.id)">
                      <Pencil class="h-4 w-4" />
                      <span>Modifier</span>
                    </button>
                    <button type="button" class="rounded-lg p-2 text-neutral-400 hover:bg-red-50 hover:text-red-600" title="Supprimer" @click="deleteWorkingTime(wt.id)">
                      <Trash2 class="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredWorkingTimes.length === 0">
                <td colspan="3" class="px-4 py-8 text-center text-neutral-400">
                  <p class="font-medium">Aucun enregistrement trouvé.</p>
                  <p class="text-sm">
                    {{ workingTimes.length === 0 ? 'Utilisez le formulaire pour ajouter votre premier temps de travail.' : 'Aucun résultat pour ce filtre.' }}
                  </p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
