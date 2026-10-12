<script setup>
import { computed } from 'vue'
import StatCard from '@/components/StatCard.vue'
import Chip from '@/components/Chip.vue'
import { store } from '@/store'
import { hours_to_text, date_key, month_key } from '@/utils/kpi'
import { period_text, length_text, status_color } from '@/utils/absences'

const today = date_key()
const month = month_key()
const month_name = new Date().toLocaleDateString('fr-FR', { month: 'long' })
const days_in_month = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate()

// On ignore les entrées incomplètes (ex. donnée corrompue) pour ne pas planter la page
const absences = computed(() => store.absences.filter(a => a && a.start && a.end && a.userName))

const requests = computed(() => [...absences.value].sort((a, b) => (b.status === 'En attente') - (a.status === 'En attente')))

const is_today = a => a.start <= today && a.end >= today && a.status !== 'Refusé'

const pending = computed(() => absences.value.filter(a => a.status === 'En attente').length)
const on_leave = computed(() => absences.value.filter(a => a.type === 'Congé' && a.status === 'Validé' && is_today(a)).length)
const sick = computed(() => absences.value.filter(a => a.type === 'Arrêt maladie' && is_today(a)).length)

const recovery_left = computed(() =>
{
  const earned = Object.values(store.overtimeDecisions).filter(d => d.choice === 'recover').reduce((s, d) => s + d.hours, 0)
  const taken = absences.value.filter(a => a.type === 'Récupération' && a.status !== 'Refusé').reduce((s, a) => s + (a.hours || 0), 0)
  return earned - taken
})

function decide(absence, status)
{
  absence.status = status
}

const calendar = computed(() =>
  absences.value
    .filter(a => a.status !== 'Refusé' && a.start.slice(0, 7) <= month && a.end.slice(0, 7) >= month)
    .map(a =>
    {
      const first = a.start.startsWith(month) ? Number(a.start.slice(8, 10)) : 1
      const last = a.end.startsWith(month) ? Number(a.end.slice(8, 10)) : days_in_month
      return {
        id: a.id,
        name: a.userName,
        type: a.type,
        left: (first - 1) / days_in_month * 100,
        width: (last - first + 1) / days_in_month * 100,
      }
    })
)
</script>

<template>
  <div class="space-y-6">
    <div class="stat-grid">
      <StatCard label="Demandes" :value="pending" hint="En attente" icon="list-interface-symbol" />
      <StatCard label="En congé" :value="on_leave" hint="Aujourd'hui" icon="planning" />
      <StatCard label="Arrêts maladie" :value="sick" hint="En cours" icon="data" />
      <StatCard label="Récupérations" :value="hours_to_text(recovery_left)" hint="À poser" icon="timetable" />
    </div>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-4 font-medium">Demandes à traiter</p>
      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium">Agent</th>
              <th class="px-3 py-3 font-medium">Type</th>
              <th class="px-3 py-3 font-medium">Période</th>
              <th class="px-3 py-3 font-medium">Durée</th>
              <th class="rounded-r-lg px-3 py-3 font-medium">Décision</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="a in requests" :key="a.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium">{{ a.userName }}</td>
              <td class="px-3 py-3">{{ a.type }}</td>
              <td class="px-3 py-3">{{ period_text(a) }}</td>
              <td class="px-3 py-3">{{ length_text(a) }}</td>
              <td class="px-3 py-3">
                <span v-if="a.status === 'En attente'" class="flex gap-1">
                  <button @click="decide(a, 'Validé')"><Chip color="dark">Valider</Chip></button>
                  <button @click="decide(a, 'Refusé')"><Chip>Refuser</Chip></button>
                </span>
                <button v-else-if="a.status === 'Déclaré'" @click="decide(a, 'Justificatif reçu')"><Chip color="outline">Justificatif reçu ?</Chip></button>
                <Chip v-else :color="status_color(a.status)">{{ a.status }}</Chip>
              </td>
            </tr>
            <tr v-if="requests.length === 0">
              <td colspan="5" class="px-4 py-8 text-center text-neutral-400">Aucune demande d'absence.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-4 font-medium">Calendrier des absences · {{ month_name }}</p>
      <div class="space-y-3 text-sm">
        <div v-for="bar in calendar" :key="bar.id" class="flex items-center gap-3">
          <span class="w-28 shrink-0 truncate" :title="bar.type">{{ bar.name }}</span>
          <div class="relative h-6 flex-1 rounded-lg bg-neutral-100">
            <div class="absolute top-0 h-6 rounded-lg bg-neutral-900" :style="{ left: `${bar.left}%`, width: `${bar.width}%` }"></div>
          </div>
        </div>
        <p v-if="calendar.length === 0" class="text-neutral-400">Aucune absence ce mois-ci.</p>
      </div>
    </div>
  </div>
</template>
