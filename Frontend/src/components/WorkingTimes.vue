<script setup>
import { ref, computed, watch } from 'vue'
import { Clock, CalendarCheck, TrendingUp, CalendarDays, Pencil, Trash2 } from 'lucide-vue-next'
import api from '@/api'
import StatCard from './StatCard.vue'
import WorkingTime from './WorkingTime.vue'
import { workingTimesToSessions, localDateKey, formatDay, formatTime, formatDuration } from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const MONTHS = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']

const workingTimes = ref([])
const selectedId = ref(null)
const error = ref('')
const month = ref('')
const year = ref('')

async function loadWorkingTimes() {
  selectedId.value = null
  try {
    const { data } = await api.get(`/workingtime/${props.userId}`)
    workingTimes.value = data.data
    error.value = ''
  } catch {
    error.value = 'Impossible de charger les temps de travail.'
  }
}

async function remove(id) {
  if (!confirm(`Supprimer la session #${id} ?`)) return
  try {
    await api.delete(`/workingtime/${id}`)
    await loadWorkingTimes()
  } catch {
    error.value = `Impossible de supprimer la session #${id}.`
  }
}

watch(() => props.userId, loadWorkingTimes, { immediate: true })

const sessions = computed(() => workingTimesToSessions(workingTimes.value))

const years = computed(() => [...new Set(sessions.value.map(s => s.start.getFullYear()))].sort((a, b) => b - a))

const filteredSessions = computed(() =>
  sessions.value
    .filter(s => !month.value || s.start.getMonth() + 1 === Number(month.value))
    .filter(s => !year.value || s.start.getFullYear() === Number(year.value))
    .reverse(),
)

const stats = computed(() => {
  const totalMs = sessions.value.reduce((sum, s) => sum + (s.end - s.start), 0)
  const days = new Set(sessions.value.map(s => localDateKey(s.start))).size
  return {
    total: formatDuration(totalMs),
    days,
    average: formatDuration(days ? totalMs / days : 0),
    count: sessions.value.length,
  }
})
</script>

<template>
  <div class="space-y-6">
    <p v-if="error" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
      <StatCard label="Heures totales" :value="stats.total" :icon="Clock" />
      <StatCard label="Jours travaillés" :value="stats.days" :icon="CalendarCheck" />
      <StatCard label="Moyenne par jour" :value="stats.average" :icon="TrendingUp" />
      <StatCard label="Sessions" :value="stats.count" :icon="CalendarDays" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <WorkingTime
        :user-id="userId"
        :working-time-id="selectedId"
        @saved="loadWorkingTimes"
        @cancel="selectedId = null"
      />

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
          <p class="font-medium">Sessions <span class="text-gray-400">({{ filteredSessions.length }})</span></p>
          <div class="flex gap-2">
            <select v-model="month" class="rounded-lg border border-gray-200 px-3 py-1.5 text-sm text-gray-600">
              <option value="">Tous les mois</option>
              <option v-for="(name, index) in MONTHS" :key="name" :value="index + 1">{{ name }}</option>
            </select>
            <select v-model="year" class="rounded-lg border border-gray-200 px-3 py-1.5 text-sm text-gray-600">
              <option value="">Toutes les années</option>
              <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
            </select>
          </div>
        </div>

        <table class="w-full text-sm">
          <thead>
            <tr class="bg-gray-50 text-left text-gray-500">
              <th class="rounded-l-lg px-4 py-3 font-medium">Date</th>
              <th class="px-4 py-3 font-medium">Horaires</th>
              <th class="px-4 py-3 font-medium">Durée</th>
              <th class="rounded-r-lg px-4 py-3"></th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="session in filteredSessions"
              :key="session.id"
              class="border-b border-gray-100 last:border-0"
              :class="{ 'bg-violet-50': selectedId === session.id }"
            >
              <td class="px-4 py-3 font-medium">{{ formatDay(session.start) }}</td>
              <td class="px-4 py-3 text-gray-500">{{ formatTime(session.start) }} - {{ formatTime(session.end) }}</td>
              <td class="px-4 py-3">
                <span class="rounded-full bg-violet-50 px-2.5 py-1 text-xs font-medium text-violet-700">
                  {{ formatDuration(session.end - session.start) }}
                </span>
              </td>
              <td class="px-4 py-3">
                <div class="flex justify-end gap-1">
                  <button class="rounded-lg p-2 text-gray-400 hover:bg-gray-100 hover:text-violet-600" @click="selectedId = session.id">
                    <Pencil class="h-4 w-4" />
                  </button>
                  <button class="rounded-lg p-2 text-gray-400 hover:bg-red-50 hover:text-red-600" @click="remove(session.id)">
                    <Trash2 class="h-4 w-4" />
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="filteredSessions.length === 0">
              <td colspan="4" class="px-4 py-8 text-center text-gray-400">Aucune session trouvée.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
