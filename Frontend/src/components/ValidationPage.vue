<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { CheckCheck, Users, Plus, Pencil } from 'lucide-vue-next'
import { api } from '@/api'
import Chip from '@/components/Chip.vue'
import { store } from '@/store'
import { username } from '@/session'
import { loadTeamMembers, teamAverage } from '@/team'
import { hoursToText, summarize, inMonth, monthKey, toDate, dateKey, addDays } from '@/utils/kpi'
import { SHIFTS, shiftOf } from '@/utils/planning'

const router = useRouter()
const month = monthKey()
const monthName = new Date().toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })

const members = ref([])
const message = ref('')
const addFor = ref('')

async function load() {
  try {
    members.value = await loadTeamMembers()
  } catch {
    message.value = 'Impossible de charger les équipes.'
  }
}

const sheetKey = m => `${month}-${m.id}`

const pendingCorrections = computed(() => {
  const ids = members.value.map(m => m.id)
  return store.corrections.filter(c => c.status === 'En attente' && ids.includes(c.userId))
})

function proposedEnd(c, time) {
  if (!time) return c.end
  const day = c.start.slice(0, 10)
  const nextDay = time <= c.start.slice(11, 16) ? dateKey(addDays(toDate(`${day} 12:00:00`), 1)) : day
  return `${nextDay} ${time}:00`
}

function correctionInfo(c) {
  const end = proposedEnd(c, c.time)
  const hours = (toDate(end) - toDate(c.start)) / 3600000
  const shift = SHIFTS[shiftOf(c.userId, toDate(c.start))]
  const average = teamAverage(members.value, c.start.slice(0, 10))
  const planned = shift?.start ? `${shift.start} – ${shift.end}` : 'rien de prévu'
  return {
    end,
    duration: hoursToText(hours),
    planning: `Planning prévu : ${planned} · Moyenne de l'équipe ce jour : ${hoursToText(average)}`,
    gap: shift?.hours ? Math.abs(hours - shift.hours) > 1 : false,
  }
}

async function accept(c, time = c.time) {
  const end = proposedEnd(c, time)
  try {
    await api.put(`/workingtime/${c.workingTimeId}`, { working_time: { start: c.start, end } })
    Object.assign(c, { status: 'Acceptée', newEnd: end, decidedBy: username.value, decidedAt: dateKey() })
  } catch {
    message.value = `Impossible de modifier le temps de travail de ${c.userName}.`
  }
}

function changeTime(c) {
  const time = prompt('Heure de sortie retenue (HH:MM)', c.time || c.end.slice(11, 16))
  if (/^\d{2}:\d{2}$/.test(time || '')) accept(c, time)
}

function refuse(c) {
  const answer = prompt('Motif du refus (visible par l\'agent)')
  if (store.rules.refusalNeedsReason && !answer) {
    message.value = 'Un refus doit être motivé.'
    return
  }
  Object.assign(c, { status: 'Refusée', answer: answer || 'Sans motif', decidedBy: username.value, decidedAt: dateKey() })
}

function acceptAll() {
  pendingCorrections.value.forEach(c => accept(c))
}

const overtimeRows = computed(() =>
  members.value
    .map(m => ({ member: m, hours: summarize(inMonth(m.times, month)).overtime }))
    .filter(row => row.hours > 0)
)

function decision(m) {
  return store.overtimeDecisions[sheetKey(m)]?.choice || ''
}

function decide(m, hours, choice) {
  store.overtimeDecisions[sheetKey(m)] = { choice, hours }
}

const sheets = computed(() => members.value.map(m => {
  const s = summarize(inMonth(m.times, month))
  const dutyDays = Object.entries(store.planning[m.id] || {}).filter(([day, shift]) => shift === 'A' && day.startsWith(month)).length
  const pending = pendingCorrections.value.some(c => c.userId === m.id)
  const validated = Boolean(store.validatedSheets[sheetKey(m)])
  return {
    member: m,
    normal: hoursToText(s.normal),
    night: hoursToText(s.night),
    sup: hoursToText(s.overtime),
    duty: `${dutyDays * SHIFTS.A.hours}h`,
    status: validated ? 'Validé' : pending ? 'Demande en attente' : 'Prêt',
  }
}))

const readySheets = computed(() => sheets.value.filter(s => s.status === 'Prêt'))
const toFix = computed(() => sheets.value.filter(s => s.status === 'Demande en attente').length)

function validate(sheet) {
  store.validatedSheets[sheetKey(sheet.member)] = dateKey()
}

function validateAll() {
  readySheets.value.forEach(validate)
}

const allPresent = computed(() => members.value.length > 0 && members.value.every(m => m.present))

async function teamClock() {
  const targets = members.value.filter(m => m.present === allPresent.value)
  await Promise.all(targets.map(m => api.post(`/clocks/${m.id}`)))
  message.value = `${allPresent.value ? 'Sortie' : 'Arrivée'} pointée pour ${targets.length} agent(s).`
  load()
}

function addTime() {
  if (addFor.value) router.push(`/workingTime/${addFor.value}`)
}

onMounted(load)
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-4 rounded-2xl bg-white p-5 xl:flex-row xl:items-center xl:justify-between">
      <div>
        <p class="font-medium first-letter:uppercase">{{ monthName }} · {{ members.length }} agent{{ members.length > 1 ? 's' : '' }}</p>
        <p class="text-sm text-neutral-500">
          {{ readySheets.length }} feuilles prêtes, {{ toFix }} à corriger, {{ pendingCorrections.length }} demandes en attente
        </p>
      </div>
      <div class="flex flex-col gap-2 xl:flex-row">
        <button
          class="inline-flex items-center justify-center gap-2 rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white disabled:opacity-40"
          :disabled="readySheets.length === 0"
          @click="validateAll"
        >
          <CheckCheck class="h-4 w-4" /> Tout valider ({{ readySheets.length }})
        </button>
        <button class="inline-flex items-center justify-center gap-2 rounded-full border-2 border-neutral-900 bg-white px-5 py-2.5 text-sm font-semibold" @click="teamClock">
          <Users class="h-4 w-4" /> {{ allPresent ? "Sortie d'équipe" : "Pointage d'équipe" }}
        </button>
        <div class="flex gap-2">
          <select v-model="addFor" class="rounded-full border-2 border-neutral-900 bg-white px-3 text-sm">
            <option value="" disabled>Agent</option>
            <option v-for="m in members" :key="m.id" :value="m.id">{{ m.name }}</option>
          </select>
          <button class="inline-flex items-center justify-center gap-2 rounded-full border-2 border-neutral-900 bg-white px-5 py-2.5 text-sm font-semibold" @click="addTime">
            <Plus class="h-4 w-4" /> Ajouter un temps
          </button>
        </div>
      </div>
    </div>

    <p v-if="message" class="rounded-xl bg-white px-4 py-3 text-sm text-neutral-600">{{ message }}</p>

    <div class="rounded-2xl bg-white p-5">
      <div class="card-title mb-4 flex flex-wrap items-center justify-between gap-2">
        <p class="font-medium">Demandes de correction <span class="text-neutral-400">({{ pendingCorrections.length }})</span></p>
        <button v-if="pendingCorrections.length" class="rounded-lg bg-neutral-100 px-3 py-1.5 text-xs font-medium" @click="acceptAll">
          Accepter les {{ pendingCorrections.length }}
        </button>
      </div>
      <p v-if="pendingCorrections.length === 0" class="text-sm text-neutral-400">Aucune demande en attente.</p>
      <div class="space-y-4">
        <div v-for="c in pendingCorrections" :key="c.id" class="flex flex-col gap-3 rounded-xl bg-neutral-50 p-4 xl:flex-row xl:items-start xl:justify-between">
          <div class="text-sm">
            <p class="font-medium">{{ c.userName }} · {{ c.day }} · {{ c.type }}</p>
            <p class="mt-1 text-neutral-600">
              Arrivée {{ c.start.slice(11, 16) }}, sortie proposée <b>{{ correctionInfo(c).end.slice(11, 16) }}</b> ({{ correctionInfo(c).duration }})
            </p>
            <p class="text-neutral-500">Motif : « {{ c.reason }} »</p>
            <p class="mt-2 text-xs" :class="correctionInfo(c).gap ? 'text-red-600' : 'text-neutral-500'">{{ correctionInfo(c).planning }}</p>
          </div>
          <div class="flex flex-wrap gap-2">
            <button class="rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white" @click="accept(c)">Accepter</button>
            <button class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2.5 text-sm font-semibold" @click="changeTime(c)">Modifier l'heure</button>
            <button class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2.5 text-sm font-semibold" @click="refuse(c)">Refuser</button>
          </div>
        </div>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-1 font-medium">Heures supplémentaires à décider</p>
      <p class="mb-4 text-xs text-neutral-500">Elles sont payées ou récupérées. Elles ne peuvent pas être effacées, et l'agent voit la décision.</p>
      <p v-if="overtimeRows.length === 0" class="text-sm text-neutral-400">Aucune heure sup ce mois-ci.</p>
      <div v-else class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium">Agent</th>
              <th class="px-3 py-3 font-medium">Heures sup</th>
              <th class="px-3 py-3 font-medium">Décision</th>
              <th class="rounded-r-lg px-3 py-3"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in overtimeRows" :key="row.member.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium">{{ row.member.name }}</td>
              <td class="px-3 py-3">{{ hoursToText(row.hours) }}</td>
              <td class="px-3 py-3">
                <label class="mr-4 inline-flex items-center gap-2">
                  <input type="radio" class="accent-neutral-900" :checked="decision(row.member) === 'paid'" @change="decide(row.member, row.hours, 'paid')" />
                  Payées (× {{ store.rules.overtimeRate }})
                </label>
                <label class="inline-flex items-center gap-2">
                  <input type="radio" class="accent-neutral-900" :checked="decision(row.member) === 'recover'" @change="decide(row.member, row.hours, 'recover')" />
                  À récupérer
                </label>
              </td>
              <td class="px-3 py-3"><Chip v-if="!decision(row.member)" color="red">À décider</Chip></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-4 font-medium">Feuilles du mois</p>
      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium">Agent</th>
              <th class="px-3 py-3 font-medium">Normales</th>
              <th class="px-3 py-3 font-medium">Nuit</th>
              <th class="px-3 py-3 font-medium">Heures sup</th>
              <th class="px-3 py-3 font-medium">Astreinte</th>
              <th class="px-3 py-3 font-medium">Statut</th>
              <th class="rounded-r-lg px-3 py-3"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="s in sheets" :key="s.member.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium">{{ s.member.name }}</td>
              <td class="px-3 py-3">{{ s.normal }}</td>
              <td class="px-3 py-3">{{ s.night }}</td>
              <td class="px-3 py-3">{{ s.sup }}</td>
              <td class="px-3 py-3">{{ s.duty }}</td>
              <td class="px-3 py-3">
                <Chip :color="s.status === 'Validé' ? 'dark' : s.status === 'Prêt' ? 'green' : 'red'">{{ s.status }}</Chip>
              </td>
              <td class="px-3 py-3">
                <span class="inline-flex items-center gap-2">
                  <button v-if="s.status === 'Prêt'" @click="validate(s)"><Chip>Valider</Chip></button>
                  <router-link v-else-if="s.status !== 'Validé'" :to="`/workingTimes/${s.member.id}`"><Chip>Corriger</Chip></router-link>
                  <router-link :to="`/workingTimes/${s.member.id}`" title="Voir ses temps"><Pencil class="h-4 w-4" /></router-link>
                </span>
              </td>
            </tr>
            <tr v-if="sheets.length === 0">
              <td colspan="7" class="px-4 py-8 text-center text-neutral-400">Aucun agent dans les équipes.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
