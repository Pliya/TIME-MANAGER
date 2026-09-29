<script setup>
import { ref, computed, watch, onMounted, onUnmounted, onActivated } from 'vue'
import api from '@/api'
import { clocksToSessions, localDateKey, formatTime, formatDuration, pad, toDate } from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const DAILY_GOAL_HOURS = 7
const DAILY_GOAL_MS = DAILY_GOAL_HOURS * 3600000

const clocks = ref([])
const clockIn = ref(false)
const startDateTime = ref(null)
const now = ref(new Date())
const error = ref('')
const loaded = ref(false)
const busy = ref(false)
let timer = null

async function refresh() {
  try {
    const { data } = await api.get(`/clocks/${props.userId}`)
    clocks.value = data.data
    const lastClock = [...clocks.value].sort((a, b) => toDate(a.time) - toDate(b.time)).at(-1)
    clockIn.value = lastClock?.status === true
    startDateTime.value = clockIn.value ? lastClock.time : null
    error.value = ''
  } catch {
    error.value = 'Impossible de charger les pointages.'
  } finally {
    loaded.value = true
  }
}

async function clock() {
  busy.value = true
  try {
    await api.post(`/clocks/${props.userId}`)
    await refresh()
  } catch {
    error.value = "Le pointage n'a pas pu être enregistré."
  } finally {
    busy.value = false
  }
}

onMounted(() => { timer = setInterval(() => { now.value = new Date() }, 1000) })
onUnmounted(() => clearInterval(timer))
onActivated(refresh)
watch(() => props.userId, () => {
  loaded.value = false
  clocks.value = []
  clockIn.value = false
  startDateTime.value = null
  refresh()
})

const startedAt = computed(() => (startDateTime.value ? toDate(startDateTime.value) : null))

const elapsed = computed(() => {
  if (!startedAt.value) return '00:00:00'
  const seconds = Math.max(0, Math.floor((now.value - startedAt.value) / 1000))
  return `${pad(Math.floor(seconds / 3600))}:${pad(Math.floor((seconds % 3600) / 60))}:${pad(seconds % 60)}`
})

const todayMs = computed(() => {
  const midnight = new Date(now.value)
  midnight.setHours(0, 0, 0, 0)
  const finished = clocksToSessions(clocks.value)
    .filter(s => s.end > midnight)
    .reduce((sum, s) => sum + (s.end - Math.max(s.start, midnight)), 0)
  const running = startedAt.value ? now.value - Math.max(startedAt.value, midnight) : 0
  return finished + running
})

const goalPercent = computed(() => Math.min(100, Math.round((todayMs.value / DAILY_GOAL_MS) * 100)))

const goalMessage = computed(() => {
  const remaining = DAILY_GOAL_MS - todayMs.value
  if (remaining <= 0) return 'Objectif atteint, bravo !'
  if (clockIn.value) return `Tu peux partir à ${formatTime(new Date(now.value.getTime() + remaining))}`
  return `Encore ${formatDuration(remaining)} à faire aujourd'hui`
})

const lastSessions = computed(() =>
  clocksToSessions(clocks.value).slice(-8).reverse().map(s => ({
    id: s.id,
    date: localDateKey(s.start),
    start: formatTime(s.start),
    end: formatTime(s.end),
    duration: formatDuration(s.end - s.start),
  })),
)
</script>

<template>
  <div class="space-y-6">
    <p v-if="error" class="rounded-xl bg-red-50 px-3 py-3 sm:px-4 text-sm text-red-600">{{ error }}</p>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="space-y-6">
        <div class="flex flex-col items-center rounded-2xl bg-white p-6 sm:p-8">
          <span
            class="rounded-full px-3 py-1 text-sm font-medium"
            :class="clockIn ? 'bg-neutral-900 text-white' : 'bg-neutral-100 text-neutral-500'"
          >
            {{ clockIn ? 'En cours' : 'Arrêté' }}
          </span>
          <p class="mt-6 text-5xl font-bold tracking-tight tabular-nums sm:mt-8 sm:text-7xl">{{ elapsed }}</p>
          <p class="mt-2 text-sm text-neutral-400">
            {{ startedAt ? `Depuis ${formatTime(startedAt)}` : 'Aucune session en cours' }}
          </p>
          <button
            v-if="!loaded"
            disabled
            class="mt-8 w-full rounded-full bg-neutral-100 py-3 font-semibold text-neutral-400"
          >
            Chargement...
          </button>
          <button
            v-else
            :disabled="busy"
            class="mt-8 w-full rounded-full py-3 font-semibold disabled:opacity-50"
            :class="clockIn ? 'border-2 border-neutral-900 bg-white text-neutral-900 hover:bg-neutral-100' : 'bg-neutral-900 text-white hover:bg-neutral-700'"
            @click="clock"
          >
            {{ clockIn ? 'Pointer la sortie' : "Pointer l'arrivée" }}
          </button>
        </div>

        <div v-if="loaded" class="rounded-2xl bg-white p-6">
          <div class="flex items-center justify-between">
            <p class="font-medium">Objectif du jour</p>
            <span class="text-sm font-medium text-neutral-400">{{ goalPercent }}%</span>
          </div>
          <p class="mt-4 text-3xl font-semibold">
            {{ formatDuration(todayMs) }}
            <span class="text-base font-normal text-neutral-400">/ {{ DAILY_GOAL_HOURS }}h</span>
          </p>
          <div class="mt-4 h-2 rounded-full bg-neutral-100">
            <div class="h-2 rounded-full bg-neutral-900" :style="{ width: `${goalPercent}%` }"></div>
          </div>
          <p class="mt-3 text-sm text-neutral-500">{{ goalMessage }}</p>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="mb-4 font-medium">Dernières sessions</p>
        <div class="overflow-x-auto">
          <table class="w-full min-w-max text-sm">
            <thead>
              <tr class="bg-neutral-50 text-left text-neutral-500">
                <th class="rounded-l-lg px-3 py-3 sm:px-4 font-medium">Date</th>
                <th class="px-3 py-3 sm:px-4 font-medium">Arrivée</th>
                <th class="px-3 py-3 sm:px-4 font-medium">Départ</th>
                <th class="rounded-r-lg px-3 py-3 sm:px-4 font-medium">Durée</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="session in lastSessions" :key="session.id" class="border-b border-neutral-100 last:border-0">
                <td class="px-3 py-3 sm:px-4 font-medium">{{ session.date }}</td>
                <td class="px-3 py-3 sm:px-4">{{ session.start }}</td>
                <td class="px-3 py-3 sm:px-4">{{ session.end }}</td>
                <td class="px-3 py-3 sm:px-4">{{ session.duration }}</td>
              </tr>
              <tr v-if="lastSessions.length === 0">
                <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune session enregistrée.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
