<script setup>
import { ref, computed } from 'vue'
import { Plane, Hourglass, Thermometer } from 'lucide-vue-next'
import StatCard from '@/components/StatCard.vue'
import Chip from '@/components/Chip.vue'
import { store, new_id } from '@/store'
import { logged_user_id, username } from '@/session'
import { hours_to_text, date_key } from '@/utils/kpi'
import { LEAVE_DAYS_PER_YEAR, working_days, recovery_balance, leave_taken, period_text, length_text, status_color } from '@/utils/absences'

const my_absences = computed(() => store.absences.filter(a => a.userId === logged_user_id.value))

const leave_left = computed(() => LEAVE_DAYS_PER_YEAR - leave_taken(logged_user_id.value))
const recovery = computed(() => recovery_balance(logged_user_id.value))
const sick_this_year = computed(() => my_absences.value.filter(a => a.type === 'Arrêt maladie' && a.start.startsWith(String(new Date().getFullYear()))).length)
const pending = computed(() => my_absences.value.filter(a => a.status === 'En attente').length)

const form_type = ref('')
const form = ref({ start: date_key(), end: date_key(), hours: 1 })
const error = ref('')

function open(type)
{
  form_type.value = type
  form.value = { start: date_key(), end: date_key(), hours: 1 }
  error.value = ''
}

function send()
{
  error.value = ''
  const absence = { id: new_id(), userId: logged_user_id.value, userName: username.value, type: form_type.value, start: form.value.start, end: form.value.end }

  if (form_type.value === 'Récupération') {
    if (form.value.hours > recovery.value) {
      error.value = `Tu n'as que ${hours_to_text(recovery.value)} à récupérer.`
      return
    }
    absence.end = absence.start
    absence.hours = Number(form.value.hours)
  } else {
    if (form.value.end < form.value.start) {
      error.value = 'La date de fin doit être après la date de début.'
      return
    }
    absence.days = working_days(form.value.start, form.value.end)
    if (form_type.value === 'Congé' && absence.days > leave_left.value) {
      error.value = `Il te reste ${leave_left.value} jours de congés.`
      return
    }
  }

  absence.status = form_type.value === 'Arrêt maladie' ? 'Déclaré' : 'En attente'
  store.absences.unshift(absence)
  form_type.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <div class="stat-grid">
      <StatCard label="Congés restants" :value="`${leave_left} j`" :hint="`Sur ${LEAVE_DAYS_PER_YEAR} jours`" icon="planning" />
      <StatCard label="Récupération" :value="hours_to_text(recovery)" hint="Heures à récupérer" icon="timetable" />
      <StatCard label="Arrêts maladie" :value="sick_this_year" hint="Cette année" icon="data" />
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

    <form v-if="form_type" class="rounded-2xl bg-white p-5" @submit.prevent="send">
      <p class="card-title mb-4 font-medium">{{ form_type }}</p>
      <div class="grid grid-cols-1 gap-3 xl:grid-cols-3">
        <label class="text-sm text-neutral-500">
          {{ form_type === 'Récupération' ? 'Jour' : 'Du' }}
          <input v-model="form.start" type="date" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm text-neutral-900" />
        </label>
        <label v-if="form_type === 'Récupération'" class="text-sm text-neutral-500">
          Nombre d'heures
          <input v-model.number="form.hours" type="number" min="0.5" step="0.5" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm text-neutral-900" />
        </label>
        <label v-else class="text-sm text-neutral-500">
          Au
          <input v-model="form.end" type="date" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm text-neutral-900" />
        </label>
        <div class="flex items-end gap-2">
          <button type="submit" class="flex-1 rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white">Envoyer</button>
          <button type="button" class="rounded-full border-2 border-neutral-900 px-5 py-2 text-sm font-semibold" @click="form_type = ''">Annuler</button>
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
            <tr v-for="a in my_absences" :key="a.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium">{{ period_text(a) }}</td>
              <td class="px-3 py-3">{{ a.type }}</td>
              <td class="px-3 py-3">{{ length_text(a) }}</td>
              <td class="px-3 py-3"><Chip :color="status_color(a.status)">{{ a.status }}</Chip></td>
            </tr>
            <tr v-if="my_absences.length === 0">
              <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune demande pour l'instant.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
