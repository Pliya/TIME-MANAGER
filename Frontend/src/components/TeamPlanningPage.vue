<script setup>
import { ref, computed, onMounted } from 'vue'
import { RadioTower, Send, ChevronLeft, ChevronRight, TriangleAlert } from 'lucide-vue-next'
import { store } from '@/store'
import { loadTeamMembers } from '@/team'
import { startOfWeek, addDays, dateKey } from '@/utils/kpi'
import { DAY_NAMES, shiftOf, setShift, weekDays, plannedNights, planningWarnings } from '@/utils/planning'

const members = ref([])
const monday = ref(startOfWeek(addDays(new Date(), store.rules.planningNoticeDays)))

onMounted(async () => {
  members.value = await loadTeamMembers().catch(() => [])
})

const days = computed(() => weekDays(monday.value))
const weekTitle = computed(() => monday.value.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' }))

const SHIFT_STYLES = { J: 'bg-neutral-100', N: 'bg-neutral-900 text-white', A: 'border border-neutral-900 bg-white', R: 'bg-white', '': 'bg-white text-neutral-400' }

const warnings = computed(() => members.value.flatMap(m => planningWarnings(m.id, monday.value, m.name)))

const publishedOn = computed(() => store.published[dateKey(monday.value)])
const daysAhead = computed(() => Math.round((monday.value - new Date()) / 86400000))

function publish() {
  store.published[dateKey(monday.value)] = new Date().toISOString()
}

const month = computed(() => dateKey(monday.value).slice(0, 7))
const nights = computed(() => members.value.map(m => ({ name: m.name, count: plannedNights(m.id, month.value) })))
const scale = computed(() => Math.max(store.rules.maxNightsPerMonth + 1, ...nights.value.map(n => n.count)))

const sector = ref('')

function trigger() {
  store.batSignal = { active: true, sector: sector.value || 'Gotham', since: new Date().toTimeString().slice(0, 5), mobilized: [] }
}

function stop() {
  store.batSignal = { active: false, sector: '', since: '', mobilized: [] }
}

function mobilize() {
  store.batSignal.mobilized = members.value.filter(m => shiftOf(m.id, new Date()) === 'A').map(m => m.name)
}
</script>

<template>
  <div class="space-y-6">
    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="rounded-2xl bg-neutral-900 p-5 text-white">
        <p class="flex items-center gap-2 text-sm font-medium"><RadioTower class="h-4 w-4" /> Bat-signal</p>

        <template v-if="store.batSignal.active">
          <p class="mt-3 text-3xl font-semibold">Actif</p>
          <p class="mt-1 text-sm text-neutral-300">Secteur {{ store.batSignal.sector }} · depuis {{ store.batSignal.since }}</p>
          <button class="mt-4 w-full rounded-full bg-white py-2 text-sm font-semibold text-neutral-900" @click="mobilize">
            Mobiliser l'équipe d'astreinte
          </button>
          <p v-if="store.batSignal.mobilized.length" class="mt-3 text-sm text-neutral-300">Mobilisés : {{ store.batSignal.mobilized.join(', ') }}</p>
          <p v-else class="mt-3 text-xs text-neutral-400">Les agents d'astreinte aujourd'hui seront prévenus.</p>
          <button class="mt-2 text-xs text-neutral-400 underline" @click="stop">Éteindre le signal</button>
        </template>

        <template v-else>
          <p class="mt-3 text-3xl font-semibold">Éteint</p>
          <input v-model="sector" placeholder="Secteur (ex. Narrows)" class="mt-3 w-full rounded-xl bg-white px-3 py-2 text-sm text-neutral-900 placeholder:text-neutral-400" />
          <button class="mt-3 w-full rounded-full bg-white py-2 text-sm font-semibold text-neutral-900" @click="trigger">Déclencher</button>
        </template>
      </div>

      <div class="rounded-2xl bg-white p-5 xl:col-span-2">
        <p class="card-title font-medium">Répartition des nuits · {{ new Date(`${month}-15`).toLocaleDateString('fr-FR', { month: 'long' }) }}</p>
        <p class="mb-4 text-sm text-neutral-400">Plafond : {{ store.rules.maxNightsPerMonth }} nuits par agent</p>
        <div class="space-y-3 text-sm">
          <div v-for="agent in nights" :key="agent.name" class="flex items-center gap-3">
            <span class="w-28 shrink-0 truncate">{{ agent.name }}</span>
            <div class="h-2 flex-1 rounded-full bg-neutral-100">
              <div
                class="h-2 rounded-full"
                :class="agent.count > store.rules.maxNightsPerMonth ? 'bg-red-500' : 'bg-neutral-900'"
                :style="{ width: `${agent.count / scale * 100}%` }"
              ></div>
            </div>
            <span class="w-8 text-right" :class="{ 'font-semibold text-red-600': agent.count > store.rules.maxNightsPerMonth }">{{ agent.count }}</span>
          </div>
          <p v-if="nights.length === 0" class="text-neutral-400">Aucun agent dans les équipes.</p>
        </div>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-5">
      <div class="card-title mb-4 flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
        <div class="flex items-center gap-2">
          <button class="rounded-lg p-1 hover:bg-neutral-100" @click="monday = addDays(monday, -7)"><ChevronLeft class="h-4 w-4" /></button>
          <button class="rounded-lg p-1 hover:bg-neutral-100" @click="monday = addDays(monday, 7)"><ChevronRight class="h-4 w-4" /></button>
          <p class="font-medium">Semaine du {{ weekTitle }}</p>
          <span v-if="publishedOn" class="text-xs text-neutral-500">· publié le {{ new Date(publishedOn).toLocaleDateString('fr-FR') }}</span>
        </div>
        <button class="inline-flex items-center justify-center gap-2 rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white" @click="publish">
          <Send class="h-4 w-4" /> {{ publishedOn ? 'Republier' : 'Publier' }}
        </button>
      </div>

      <p v-if="daysAhead < store.rules.planningNoticeDays" class="mb-3 text-xs text-red-600">
        Les règles demandent de publier {{ store.rules.planningNoticeDays }} jours à l'avance
        ({{ daysAhead > 0 ? `ici : ${daysAhead} jours` : 'cette semaine est déjà commencée' }}).
      </p>

      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium">Agent</th>
              <th v-for="(day, i) in days" :key="i" class="px-3 py-3 font-medium last:rounded-r-lg">{{ DAY_NAMES[i] }} {{ day.getDate() }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in members" :key="m.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium">{{ m.name }}</td>
              <td v-for="day in days" :key="dateKey(day)" class="px-2 py-2">
                <select
                  :value="shiftOf(m.id, day)"
                  class="rounded-full px-2 py-1 text-xs font-medium"
                  :class="SHIFT_STYLES[shiftOf(m.id, day)]"
                  @change="setShift(m.id, day, $event.target.value)"
                >
                  <option value="">—</option>
                  <option value="J">Jour</option>
                  <option value="N">Nuit</option>
                  <option value="A">Astr.</option>
                  <option value="R">Repos</option>
                </select>
              </td>
            </tr>
            <tr v-if="members.length === 0">
              <td colspan="8" class="px-4 py-8 text-center text-neutral-400">Aucun agent dans les équipes.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <ul v-if="warnings.length" class="mt-4 space-y-1 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">
        <li v-for="w in warnings" :key="w" class="flex items-center gap-2"><TriangleAlert class="h-4 w-4 shrink-0" /> {{ w }}</li>
      </ul>
    </div>
  </div>
</template>
