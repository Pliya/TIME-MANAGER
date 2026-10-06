<script setup>
import { ref, computed } from 'vue'
import { Plane, Hourglass, Thermometer } from 'lucide-vue-next'
import StatCard from '@/components/StatCard.vue'
import Chip from '@/components/Chip.vue'
import { store, newId } from '@/store'
import { loggedUserId, username } from '@/session'
import { hoursToText, dateKey } from '@/utils/kpi'
import { LEAVE_DAYS_PER_YEAR, workingDays, recoveryBalance, leaveTaken, periodText, lengthText, statusColor } from '@/utils/absences'

const myAbsences = computed(() => store.absences.filter(a => a.userId === loggedUserId.value))

const leaveLeft = computed(() => LEAVE_DAYS_PER_YEAR - leaveTaken(loggedUserId.value))
const recovery = computed(() => recoveryBalance(loggedUserId.value))
const sickThisYear = computed(() => myAbsences.value.filter(a => a.type === 'Arrêt maladie' && a.start.startsWith(String(new Date().getFullYear()))).length)
const pending = computed(() => myAbsences.value.filter(a => a.status === 'En attente').length)

const formType = ref('')
const form = ref({ start: dateKey(), end: dateKey(), hours: 1 })
const error = ref('')

function open(type) {
  formType.value = type
  form.value = { start: dateKey(), end: dateKey(), hours: 1 }
  error.value = ''
}

function send() {
  error.value = ''
  const absence = { id: newId(), userId: loggedUserId.value, userName: username.value, type: formType.value, start: form.value.start, end: form.value.end }

  if (formType.value === 'Récupération') {
    if (form.value.hours > recovery.value) {
      error.value = `Tu n'as que ${hoursToText(recovery.value)} à récupérer.`
      return
    }
    absence.end = absence.start
    absence.hours = Number(form.value.hours)
  } else {
    if (form.value.end < form.value.start) {
      error.value = 'La date de fin doit être après la date de début.'
      return
    }
    absence.days = workingDays(form.value.start, form.value.end)
    if (formType.value === 'Congé' && absence.days > leaveLeft.value) {
      error.value = `Il te reste ${leaveLeft.value} jours de congés.`
      return
    }
  }

  absence.status = formType.value === 'Arrêt maladie' ? 'Déclaré' : 'En attente'
  store.absences.unshift(absence)
  formType.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <div class="stat-grid">
      <StatCard label="Congés restants" :value="`${leaveLeft} j`" :hint="`Sur ${LEAVE_DAYS_PER_YEAR} jours`" icon="planning" />
      <StatCard label="Récupération" :value="hoursToText(recovery)" hint="Heures à récupérer" icon="timetable" />
      <StatCard label="Arrêts maladie" :value="sickThisYear" hint="Cette année" icon="data" />
      <StatCard label="Demandes" :value="pending" hint="En attente" icon="list-interface-symbol" />
    </div>

    <div class="flex flex-col gap-3 xl:flex-row">
      <button class="inline-flex items-center justify-center gap-2 rounded-full bg-neutral-900 px-5 py-3 text-sm font-semibold text-white" @click="open('Congé')">
        <Plane class="h-4 w-4" /> Demander un congé
      </button>
      <button class="inline-flex items-center justify-center gap-2 rounded-full border-2 border-neutral-900 bg-white px-5 py-3 text-sm font-semibold" @click="open('Arrêt maladie')">
        <Thermometer class="h-4 w-4" /> Déclarer un arrêt maladie
      </button>
      <button class="inline-flex items-center justify-center gap-2 rounded-full border-2 border-neutral-900 bg-white px-5 py-3 text-sm font-semibold" @click="open('Récupération')">
        <Hourglass class="h-4 w-4" /> Poser une récupération
      </button>
    </div>

    <form v-if="formType" class="rounded-2xl bg-white p-5" @submit.prevent="send">
      <p class="card-title mb-4 font-medium">{{ formType }}</p>
      <div class="grid grid-cols-1 gap-3 xl:grid-cols-3">
        <label class="text-sm text-neutral-500">
          {{ formType === 'Récupération' ? 'Jour' : 'Du' }}
          <input v-model="form.start" type="date" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm text-neutral-900" />
        </label>
        <label v-if="formType === 'Récupération'" class="text-sm text-neutral-500">
          Nombre d'heures
          <input v-model.number="form.hours" type="number" min="0.5" step="0.5" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm text-neutral-900" />
        </label>
        <label v-else class="text-sm text-neutral-500">
          Au
          <input v-model="form.end" type="date" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm text-neutral-900" />
        </label>
        <div class="flex items-end gap-2">
          <button type="submit" class="flex-1 rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white">Envoyer</button>
          <button type="button" class="rounded-full border-2 border-neutral-900 px-5 py-2 text-sm font-semibold" @click="formType = ''">Annuler</button>
        </div>
      </div>
      <p v-if="error" class="mt-3 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600">{{ error }}</p>
    </form>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-4 font-medium">Mes demandes</p>
      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium">Période</th>
              <th class="px-3 py-3 font-medium">Type</th>
              <th class="px-3 py-3 font-medium">Durée</th>
              <th class="rounded-r-lg px-3 py-3 font-medium">Statut</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="a in myAbsences" :key="a.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium">{{ periodText(a) }}</td>
              <td class="px-3 py-3">{{ a.type }}</td>
              <td class="px-3 py-3">{{ lengthText(a) }}</td>
              <td class="px-3 py-3"><Chip :color="statusColor(a.status)">{{ a.status }}</Chip></td>
            </tr>
            <tr v-if="myAbsences.length === 0">
              <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune demande pour l'instant.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
