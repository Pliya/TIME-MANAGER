<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { Lock, ChevronDown } from 'lucide-vue-next'
import { api } from '@/api'
import StatCard from './StatCard.vue'
import Chip from './Chip.vue'
import { computeKpi, hoursToText, isNight, sortByTime } from '@/utils/kpi'
import { store, newId } from '@/store'
import { username } from '@/session'

const route = useRoute()
const props = defineProps({ userId: { type: [Number, String], default: null } })

const userId = ref(Number(route.params.userID || props.userId))
const workingTimes = ref([])
const errorMessage = ref('')

const requests = computed(() => store.corrections.filter(c => c.userId === userId.value))
const pendingCount = computed(() => requests.value.filter(c => c.status === 'En attente').length)
const form = ref({ sessionId: '', type: 'Pointage oublié', time: '', reason: '' })
const formError = ref('')

const stats = computed(() => computeKpi(workingTimes.value))

const sessions = computed(() => [...workingTimes.value].reverse())

async function getWorkingTimes() {
  errorMessage.value = ''
  try {
    const res = await api.get(`/workingtime/${userId.value}`)
    workingTimes.value = sortByTime(res.data.data || [], 'start')
  } catch {
    errorMessage.value = 'Impossible de charger tes temps de travail.'
  }
}

function toDate(time) {
  return new Date(time.replace(' ', 'T'))
}

function dayText(time) {
  return toDate(time).toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric', month: 'short' })
}

function hours(wt) {
  return `${wt.start.slice(11, 16)} → ${wt.end.slice(11, 16)}`
}

function duration(wt) {
  return hoursToText((toDate(wt.end) - toDate(wt.start)) / 3600000)
}

function requestFor(wt) {
  return requests.value.find(r => r.workingTimeId === wt.id)
}

function correct(wt) {
  form.value.sessionId = wt.id
}

function sendRequest() {
  formError.value = ''
  const wt = workingTimes.value.find(w => w.id === Number(form.value.sessionId))
  if (!wt || !form.value.reason) return

  const sheet = `${wt.start.slice(0, 7)}-${userId.value}`
  if (store.rules.correctionsUntilValidation && store.validatedSheets[sheet]) {
    formError.value = 'Ce mois est déjà validé par ton manager : la correction est fermée.'
    return
  }

  store.corrections.unshift({
    id: newId(),
    userId: userId.value,
    userName: username.value,
    workingTimeId: wt.id,
    start: wt.start,
    end: wt.end,
    day: dayText(wt.start),
    type: form.value.type,
    time: form.value.time,
    reason: form.value.reason,
    status: 'En attente',
  })
  form.value = { sessionId: '', type: 'Pointage oublié', time: '', reason: '' }
}

watch(() => route.params.userID, id => {
  if (id) {
    userId.value = Number(id)
    getWorkingTimes()
  }
})

onMounted(getWorkingTimes)

defineExpose({ userId, workingTimes, getWorkingTimes })
</script>

<template>
  <div class="space-y-6">
    <p v-if="errorMessage" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ errorMessage }}</p>

    <div class="stat-grid">
      <StatCard label="Heures totales" :value="stats.totalHours" hint="Depuis le début" icon="timetable" />
      <StatCard label="Jours travaillés" :value="stats.daysWorked" hint="Depuis le début" icon="schedule" />
      <StatCard label="Moyenne par jour" :value="stats.avgHours" hint="Depuis le début" icon="trend" />
      <StatCard label="Corrections" :value="pendingCount" hint="En attente" icon="list-interface-symbol" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="space-y-6">
        <form class="rounded-2xl bg-white p-5" @submit.prevent="sendRequest">
          <p class="card-title mb-1 font-medium">Demander une correction</p>
          <p class="mb-4 text-xs text-neutral-500">Ton manager accepte, modifie ou refuse sous 48 h.</p>

          <label class="text-sm text-neutral-500">Session concernée</label>
          <select v-model="form.sessionId" required class="mt-1 w-full rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm">
            <option value="" disabled>Choisir une session</option>
            <option v-for="wt in sessions" :key="wt.id" :value="wt.id">{{ dayText(wt.start) }} · {{ hours(wt) }}</option>
          </select>

          <label class="mt-3 block text-sm text-neutral-500">Type de demande</label>
          <div class="relative mt-1">
            <select v-model="form.type" class="w-full appearance-none rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm">
              <option>Pointage oublié</option>
              <option>Heures non pointées</option>
              <option>Erreur d'horaire</option>
            </select>
            <ChevronDown class="pointer-events-none absolute top-2.5 right-3 h-4 w-4" />
          </div>

          <label class="mt-3 block text-sm text-neutral-500">Heure de sortie proposée</label>
          <input v-model="form.time" type="time" class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm" />

          <label class="mt-3 block text-sm text-neutral-500">Motif</label>
          <input v-model.trim="form.reason" required placeholder="J'ai oublié de pointer en partant." class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm" />

          <p v-if="formError" class="mt-3 rounded-xl bg-red-50 px-3 py-2 text-xs text-red-600">{{ formError }}</p>
          <button type="submit" class="mt-4 w-full rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-neutral-700">
            Envoyer la demande
          </button>
        </form>

        <div class="rounded-2xl bg-white p-5">
          <p class="card-title mb-3 font-medium">Historique</p>
          <div class="space-y-3 text-xs text-neutral-500">
            <p v-for="r in requests" :key="r.id">
              <span class="font-medium text-neutral-900">{{ r.day }}</span> ·
              <template v-if="r.status === 'Acceptée'">Sortie fixée à {{ r.newEnd.slice(11, 16) }} par {{ r.decidedBy }}, à ta demande.</template>
              <template v-else-if="r.status === 'Refusée'">Demande refusée : « {{ r.answer }} »</template>
              <template v-else>{{ r.type }}{{ r.time ? ` (${r.time})` : '' }} : « {{ r.reason }} » En attente du manager.</template>
            </p>
            <p v-if="requests.length === 0">Aucune demande pour l'instant.</p>
          </div>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-5 xl:col-span-2">
        <div class="card-title mb-4 flex flex-wrap items-center justify-between gap-2">
          <p class="font-medium">Mes sessions <span class="text-neutral-400">({{ sessions.length }})</span></p>
          <span class="flex items-center gap-1 text-xs text-neutral-500"><Lock class="h-4 w-4" /> Lecture seule</span>
        </div>

        <div class="max-h-[32rem] overflow-auto">
          <table class="w-full min-w-max text-sm">
            <thead>
              <tr class="bg-neutral-50 text-left text-neutral-500">
                <th class="rounded-l-lg px-3 py-3 font-medium">Date</th>
                <th class="px-3 py-3 font-medium">Horaires</th>
                <th class="px-3 py-3 font-medium">Durée</th>
                <th class="px-3 py-3 font-medium">Statut</th>
                <th class="rounded-r-lg px-3 py-3"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="wt in sessions" :key="wt.id" class="border-b border-neutral-100 last:border-0">
                <td class="px-3 py-3 font-medium">{{ dayText(wt.start) }}</td>
                <td class="px-3 py-3">{{ hours(wt) }}</td>
                <td class="px-3 py-3">{{ duration(wt) }}</td>
                <td class="px-3 py-3">
                  <Chip v-if="requestFor(wt)?.status === 'En attente'">Correction en attente</Chip>
                  <Chip v-else-if="requestFor(wt)?.status === 'Acceptée'" color="green">Corrigée par {{ requestFor(wt).decidedBy }}</Chip>
                  <Chip v-else-if="isNight(wt.start)" color="dark">Nuit</Chip>
                  <Chip v-else>Pointée</Chip>
                </td>
                <td class="px-3 py-3 text-right">
                  <button class="text-xs font-medium text-neutral-500 hover:text-neutral-900" @click="correct(wt)">Corriger</button>
                </td>
              </tr>
              <tr v-if="sessions.length === 0">
                <td colspan="5" class="px-4 py-8 text-center text-neutral-400">Aucune session enregistrée.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
