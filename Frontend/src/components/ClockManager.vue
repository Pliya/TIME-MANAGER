<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import api from '@/api'
import { clocksToSessions, localDateKey, formatTime, formatDuration, pad, toDate } from '@/utils/date'

const props = defineProps({ userId: { type: Number, required: true } })

const clocks = ref([])
const now = ref(new Date())
const error = ref('')
let timer = null

async function loadClocks() {
  try {
    const { data } = await api.get(`/clocks/${props.userId}`)
    clocks.value = data.data
    error.value = ''
  } catch {
    error.value = 'Impossible de charger les pointages.'
  }
}

async function toggleClock() {
  try {
    await api.post(`/clocks/${props.userId}`)
    await loadClocks()
  } catch {
    error.value = "Le pointage n'a pas pu être enregistré."
  }
}

onMounted(() => { timer = setInterval(() => { now.value = new Date() }, 1000) })
onUnmounted(() => clearInterval(timer))
watch(() => props.userId, loadClocks, { immediate: true })

const lastClock = computed(() => {
  const sorted = [...clocks.value].sort((a, b) => toDate(a.time) - toDate(b.time))
  return sorted.at(-1)
})

const isClockedIn = computed(() => lastClock.value?.status === true)
const startedAt = computed(() => (isClockedIn.value ? toDate(lastClock.value.time) : null))

const elapsed = computed(() => {
  if (!startedAt.value) return '00:00:00'
  const seconds = Math.max(0, Math.floor((now.value - startedAt.value) / 1000))
  return `${pad(Math.floor(seconds / 3600))}:${pad(Math.floor((seconds % 3600) / 60))}:${pad(seconds % 60)}`
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
    <p v-if="error" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="flex flex-col items-center rounded-2xl bg-white p-8">
        <span
          class="rounded-full px-3 py-1 text-sm font-medium"
          :class="isClockedIn ? 'bg-green-50 text-green-600' : 'bg-gray-100 text-gray-500'"
        >
          {{ isClockedIn ? 'En cours' : 'Arrêté' }}
        </span>
        <p class="mt-8 text-5xl font-semibold tabular-nums">{{ elapsed }}</p>
        <p class="mt-2 text-sm text-gray-400">
          {{ startedAt ? `Depuis ${formatTime(startedAt)}` : 'Aucune session en cours' }}
        </p>
        <button
          class="mt-8 w-full rounded-xl py-3 font-semibold text-white"
          :class="isClockedIn ? 'bg-red-500 hover:bg-red-600' : 'bg-violet-600 hover:bg-violet-700'"
          @click="toggleClock"
        >
          {{ isClockedIn ? 'Pointer la sortie' : "Pointer l'arrivée" }}
        </button>
      </div>

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="mb-4 font-medium">Dernières sessions</p>
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-gray-50 text-left text-gray-500">
              <th class="rounded-l-lg px-4 py-3 font-medium">Date</th>
              <th class="px-4 py-3 font-medium">Arrivée</th>
              <th class="px-4 py-3 font-medium">Départ</th>
              <th class="rounded-r-lg px-4 py-3 font-medium">Durée</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="session in lastSessions" :key="session.id" class="border-b border-gray-100 last:border-0">
              <td class="px-4 py-3 font-medium">{{ session.date }}</td>
              <td class="px-4 py-3">{{ session.start }}</td>
              <td class="px-4 py-3">{{ session.end }}</td>
              <td class="px-4 py-3">{{ session.duration }}</td>
            </tr>
            <tr v-if="lastSessions.length === 0">
              <td colspan="4" class="px-4 py-8 text-center text-gray-400">Aucune session enregistrée.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
