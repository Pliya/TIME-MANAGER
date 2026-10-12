<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { dateLocale } from '@/i18n'
import { useRoute } from 'vue-router'
import { Lock, ChevronDown } from 'lucide-vue-next'
import { api } from '@/api'
import StatCard from './StatCard.vue'
import Chip from './Chip.vue'
import { compute_kpi, hours_to_text, is_night, sort_by_time } from '@/utils/kpi'
import { store, new_id } from '@/store'
import { username } from '@/session'

const route = useRoute()
const props = defineProps({ userId: { type: [Number, String], default: null } })

const user_id = ref(Number(route.params.userID || props.userId))
const working_times = ref([])
const error_message = ref('')

const requests = computed(() => store.corrections.filter(c => c.userId === user_id.value))
const pending_count = computed(() => requests.value.filter(c => c.status === 'En attente').length)
const form = ref({ sessionId: '', type: 'Pointage oublié', time: '', reason: '' })
const form_error = ref('')

const stats = computed(() => compute_kpi(working_times.value))

const sessions = computed(() => [...working_times.value].reverse())

async function get_working_times()
{
  error_message.value = ''
  try {
    const res = await api.get(`/workingtime/${user_id.value}`)
    working_times.value = sort_by_time(res.data.data || [], 'start')
  } catch {
    error_message.value = 'Impossible de charger tes temps de travail.'
  }
}

function to_date(time)
{
  return new Date(time.replace(' ', 'T'))
}

function day_text(time)
{
  return to_date(time).toLocaleDateString(dateLocale(), { weekday: 'short', day: 'numeric', month: 'short' })
}

function hours(wt)
{
  return `${wt.start.slice(11, 16)} → ${wt.end.slice(11, 16)}`
}

function duration(wt)
{
  return hours_to_text((to_date(wt.end) - to_date(wt.start)) / 3600000)
}

function request_for(wt)
{
  return requests.value.find(r => r.workingTimeId === wt.id)
}

function correct(wt)
{
  form.value.sessionId = wt.id
}

function send_request()
{
  form_error.value = ''
  const wt = working_times.value.find(w => w.id === Number(form.value.sessionId))
  if (!wt || !form.value.reason) return

  const sheet = `${wt.start.slice(0, 7)}-${user_id.value}`
  if (store.rules.correctionsUntilValidation && store.validatedSheets[sheet]) {
    form_error.value = 'Ce mois est déjà validé par ton manager : la correction est fermée.'
    return
  }

  store.corrections.unshift({
    id: new_id(),
    userId: user_id.value,
    userName: username.value,
    workingTimeId: wt.id,
    start: wt.start,
    end: wt.end,
    day: day_text(wt.start),
    type: form.value.type,
    time: form.value.time,
    reason: form.value.reason,
    status: 'En attente',
  })
  form.value = { sessionId: '', type: 'Pointage oublié', time: '', reason: '' }
}

watch(() => route.params.userID, id =>
{
  if (id) {
    user_id.value = Number(id)
    get_working_times()
  }
})

onMounted(get_working_times)

defineExpose({ user_id, working_times, get_working_times })
</script>

<template>
  <div class="space-y-6">
    <p v-if="error_message" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error_message }}</p>

    <div class="stat-grid">
      <StatCard label="Heures totales" :value="stats.totalHours" hint="Depuis le début" icon="timetable" />
      <StatCard label="Jours travaillés" :value="stats.daysWorked" hint="Depuis le début" icon="schedule" />
      <StatCard label="Moyenne par jour" :value="stats.avgHours" hint="Depuis le début" icon="trend" />
      <StatCard label="Corrections" :value="pending_count" hint="En attente" icon="list-interface-symbol" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="space-y-6">
        <form class="rounded-2xl bg-white p-5" @submit.prevent="send_request">
          <p class="card-title mb-1 font-medium">{{ $t('Demander une correction') }}</p>
          <p class="mb-4 text-xs text-neutral-500">{{ $t('Ton manager accepte, modifie ou refuse sous 48 h.') }}</p>

          <label class="text-sm text-neutral-500">{{ $t('Session concernée') }}</label>
          <select v-model="form.sessionId" required class="mt-1 w-full rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm">
            <option value="" disabled>{{ $t('Choisir une session') }}</option>
            <option v-for="wt in sessions" :key="wt.id" :value="wt.id">{{ day_text(wt.start) }} · {{ hours(wt) }}</option>
          </select>

          <label class="mt-3 block text-sm text-neutral-500">{{ $t('Type de demande') }}</label>
          <div class="relative mt-1">
            <select v-model="form.type" class="w-full appearance-none rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm">
              <option>{{ $t('Pointage oublié') }}</option>
              <option>{{ $t('Heures non pointées') }}</option>
              <option>{{ $t('Erreur d\'horaire') }}</option>
            </select>
            <ChevronDown class="pointer-events-none absolute top-2.5 right-3 h-4 w-4" />
          </div>

          <label class="mt-3 block text-sm text-neutral-500">{{ $t('Heure de sortie proposée') }}</label>
          <input v-model="form.time" type="time" class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm" />

          <label class="mt-3 block text-sm text-neutral-500">{{ $t('Motif') }}</label>
          <input v-model.trim="form.reason" required placeholder="J'ai oublié de pointer en partant." class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm" />

          <p v-if="form_error" class="mt-3 rounded-xl bg-red-50 px-3 py-2 text-xs text-red-600">{{ form_error }}</p>
          <button type="submit" class="mt-4 w-full rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-neutral-700">
            {{ $t('Envoyer la demande') }}
          </button>
        </form>

        <div class="rounded-2xl bg-white p-5">
          <p class="card-title mb-3 font-medium">{{ $t('Historique') }}</p>
          <div class="space-y-3 text-xs text-neutral-500">
            <p v-for="r in requests" :key="r.id">
              <span class="font-medium text-neutral-900">{{ r.day }}</span> ·
              <template v-if="r.status === 'Acceptée'">{{ $t('Sortie fixée à {time} par {who}, à ta demande.', { time: r.newEnd.slice(11, 16), who: r.decidedBy }) }}</template>
              <template v-else-if="r.status === 'Refusée'">{{ $t('Demande refusée : « {answer} »', { answer: r.answer }) }}</template>
              <template v-else>{{ $t(r.type) }}{{ r.time ? ` (${r.time})` : '' }} : « {{ r.reason }} » {{ $t('En attente du manager.') }}</template>
            </p>
            <p v-if="requests.length === 0">{{ $t('Aucune demande pour l\'instant.') }}</p>
          </div>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-5 xl:col-span-2">
        <div class="card-title mb-4 flex flex-wrap items-center justify-between gap-2">
          <p class="font-medium">{{ $t('Mes sessions') }} <span class="text-neutral-400">({{ sessions.length }})</span></p>
          <span class="flex items-center gap-1 text-xs text-neutral-500"><Lock class="h-4 w-4" /> {{ $t('Lecture seule') }}</span>
        </div>

        <div class="max-h-[32rem] overflow-auto">
          <table class="w-full min-w-max text-sm">
            <thead>
              <tr class="bg-neutral-50 text-left text-neutral-500">
                <th class="rounded-l-lg px-3 py-3 font-medium">{{ $t('Date') }}</th>
                <th class="px-3 py-3 font-medium">{{ $t('Horaires') }}</th>
                <th class="px-3 py-3 font-medium">{{ $t('Durée') }}</th>
                <th class="px-3 py-3 font-medium">{{ $t('Statut') }}</th>
                <th class="rounded-r-lg px-3 py-3"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="wt in sessions" :key="wt.id" class="border-b border-neutral-100 last:border-0">
                <td class="px-3 py-3 font-medium">{{ day_text(wt.start) }}</td>
                <td class="px-3 py-3">{{ hours(wt) }}</td>
                <td class="px-3 py-3">{{ duration(wt) }}</td>
                <td class="px-3 py-3">
                  <Chip v-if="request_for(wt)?.status === 'En attente'">{{ $t('Correction en attente') }}</Chip>
                  <Chip v-else-if="request_for(wt)?.status === 'Acceptée'" color="green">{{ $t('Corrigée par {who}', { who: request_for(wt).decidedBy }) }}</Chip>
                  <Chip v-else-if="is_night(wt.start)" color="dark">{{ $t('Nuit') }}</Chip>
                  <Chip v-else>{{ $t('Pointée') }}</Chip>
                </td>
                <td class="px-3 py-3 text-right">
                  <button class="text-xs font-medium text-neutral-500 hover:text-neutral-900" @click="correct(wt)">{{ $t('Corriger') }}</button>
                </td>
              </tr>
              <tr v-if="sessions.length === 0">
                <td colspan="5" class="px-4 py-8 text-center text-neutral-400">{{ $t('Aucune session enregistrée.') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
