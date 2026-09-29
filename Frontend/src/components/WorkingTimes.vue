<script setup>
import { ref, computed, watch } from 'vue'
import { Clock, CalendarCheck, TrendingUp, CalendarDays, Pencil, Trash2 } from 'lucide-vue-next'
import api from '@/api'
import StatCard from './StatCard.vue'
import WorkingTime from './WorkingTime.vue'
import { workingTimesToSessions, summarize, formatDay, formatTime, formatDuration } from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const MONTHS = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']

const userId = ref(props.userId)
const workingTimes = ref([])
const selectedId = ref(null)
const error = ref('')
const month = ref('')
const year = ref('')

async function getWorkingTimes() {
  selectedId.value = null
  try {
    const { data } = await api.get(`/workingtime/${userId.value}`)
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
    await getWorkingTimes()
  } catch {
    error.value = `Impossible de supprimer la session #${id}.`
  }
}

watch(() => props.userId, newUserId => {
  userId.value = newUserId
  getWorkingTimes()
}, { immediate: true })

const sessions = computed(() => workingTimesToSessions(workingTimes.value))

const years = computed(() => [...new Set(sessions.value.map(s => s.start.getFullYear()))].sort((a, b) => b - a))

const filteredSessions = computed(() =>
  sessions.value
    .filter(s => !month.value || s.start.getMonth() + 1 === Number(month.value))
    .filter(s => !year.value || s.start.getFullYear() === Number(year.value))
    .reverse(),
)

const stats = computed(() => summarize(sessions.value))
</script>

<template>
  <div class="space-y-6">
    <p v-if="error" class="rounded-xl bg-red-50 px-3 py-3 sm:px-4 text-sm text-red-600">{{ error }}</p>

    <div class="grid grid-cols-2 gap-4 lg:gap-6 xl:grid-cols-4">
      <StatCard label="Heures totales" :value="stats.total" hint="Depuis le début" :icon="Clock" />
      <StatCard label="Jours travaillés" :value="stats.days" hint="Depuis le début" :icon="CalendarCheck" />
      <StatCard label="Moyenne par jour" :value="stats.average" hint="Depuis le début" :icon="TrendingUp" />
      <StatCard label="Sessions" :value="stats.count" hint="Depuis le début" :icon="CalendarDays" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <WorkingTime
        :user-id="userId"
        :working-time-id="selectedId"
        @saved="getWorkingTimes"
        @cancel="selectedId = null"
      />

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
          <p class="font-medium">Sessions <span class="text-neutral-400">({{ filteredSessions.length }})</span></p>
          <div class="flex gap-2">
            <select v-model="month" class="rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option value="">Tous les mois</option>
              <option v-for="(name, index) in MONTHS" :key="name" :value="index + 1">{{ name }}</option>
            </select>
            <select v-model="year" class="rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option value="">Toutes les années</option>
              <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
            </select>
          </div>
        </div>

        <div class="max-h-[28rem] overflow-auto">
          <table class="w-full min-w-max text-sm">
            <thead class="sticky top-0 z-10">
              <tr class="bg-neutral-50 text-left text-neutral-500">
                <th class="rounded-l-lg px-3 py-3 sm:px-4 font-medium">Date</th>
                <th class="px-3 py-3 sm:px-4 font-medium">Horaires</th>
                <th class="px-3 py-3 sm:px-4 font-medium">Durée</th>
                <th class="rounded-r-lg px-3 py-3 sm:px-4"></th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="session in filteredSessions"
                :key="session.id"
                class="border-b border-neutral-100 last:border-0"
                :class="{ 'bg-neutral-100': selectedId === session.id }"
              >
                <td class="px-3 py-3 sm:px-4 font-medium">{{ formatDay(session.start) }}</td>
                <td class="px-3 py-3 sm:px-4 text-neutral-500">{{ formatTime(session.start) }} - {{ formatTime(session.end) }}</td>
                <td class="px-3 py-3 sm:px-4">
                  <span class="rounded-full bg-neutral-100 px-2.5 py-1 text-xs font-medium text-neutral-900">
                    {{ formatDuration(session.end - session.start) }}
                  </span>
                </td>
                <td class="px-3 py-3 sm:px-4">
                  <div class="flex justify-end gap-1">
                    <button class="rounded-lg p-2 text-neutral-400 hover:bg-neutral-100 hover:text-neutral-900" @click="selectedId = session.id">
                      <Pencil class="h-4 w-4" />
                    </button>
                    <button class="rounded-lg p-2 text-neutral-400 hover:bg-red-50 hover:text-red-600" @click="remove(session.id)">
                      <Trash2 class="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredSessions.length === 0">
                <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune session trouvée.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
