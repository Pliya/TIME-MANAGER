<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { X } from 'lucide-vue-next'
import api from '@/api'
import { pad, toDate, toApiDateTime } from '@/utils/date'

const props = defineProps({
  userId: { type: Number, required: true },
  workingTimeId: { type: Number, default: null },
})

const emit = defineEmits(['saved', 'cancel'])

const route = useRoute()
const start = ref('')
const end = ref('')
const error = ref('')
const success = ref('')

const workingTimeId = computed(() => props.workingTimeId || Number(route.params.workingtimeid) || null)

const duration = computed(() => {
  if (!start.value || !end.value) return null
  const hours = (new Date(end.value) - new Date(start.value)) / 3600000
  return hours > 0 ? `${hours.toFixed(1)} h` : null
})

function toInput(apiValue) {
  const d = toDate(apiValue)
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function payload() {
  return {
    working_time: {
      start: toApiDateTime(new Date(start.value)),
      end: toApiDateTime(new Date(end.value)),
    },
  }
}

function errorMessage(err) {
  if (!err.response) return "Impossible de contacter l'API."
  const errors = err.response.data?.errors
  if (err.response.status === 422 && errors) {
    return Object.entries(errors).map(([field, messages]) => `${field} : ${[].concat(messages).join(', ')}`).join(' ; ')
  }
  return `Erreur ${err.response.status}.`
}

function setToday(startHour, endHour) {
  const now = new Date()
  const day = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
  start.value = `${day}T${pad(startHour)}:00`
  end.value = `${day}T${pad(endHour)}:00`
}

function reset() {
  start.value = ''
  end.value = ''
}

async function getWorkingTime() {
  error.value = ''
  if (!workingTimeId.value) return reset()
  try {
    const { data } = await api.get(`/workingtime/${props.userId}/${workingTimeId.value}`)
    start.value = toInput(data.data.start)
    end.value = toInput(data.data.end)
  } catch (err) {
    error.value = errorMessage(err)
  }
}

async function createWorkingTime() {
  try {
    await api.post(`/workingtime/${props.userId}`, payload())
    success.value = 'Temps de travail créé.'
    reset()
    emit('saved')
  } catch (err) {
    error.value = errorMessage(err)
  }
}

async function updateWorkingTime() {
  try {
    await api.put(`/workingtime/${workingTimeId.value}`, payload())
    success.value = 'Temps de travail modifié.'
    reset()
    emit('saved')
  } catch (err) {
    error.value = errorMessage(err)
  }
}

async function deleteWorkingTime() {
  if (!confirm('Supprimer ce temps de travail ?')) return
  try {
    await api.delete(`/workingtime/${workingTimeId.value}`)
    success.value = 'Temps de travail supprimé.'
    reset()
    emit('saved')
  } catch (err) {
    error.value = errorMessage(err)
  }
}

function submit() {
  error.value = ''
  success.value = ''
  return workingTimeId.value ? updateWorkingTime() : createWorkingTime()
}

function cancel() {
  reset()
  emit('cancel')
}

watch(workingTimeId, getWorkingTime, { immediate: true })
</script>

<template>
  <div class="w-full max-w-xl rounded-2xl bg-white p-6">
    <div class="mb-6 flex items-center justify-between">
      <p class="font-medium">{{ workingTimeId ? `Modifier la session #${workingTimeId}` : 'Nouvelle session' }}</p>
      <button v-if="workingTimeId" class="text-neutral-400 hover:text-neutral-600" @click="cancel">
        <X class="h-5 w-5" />
      </button>
    </div>

    <p v-if="error" class="mb-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>
    <p v-if="success" class="mb-4 rounded-xl bg-green-50 px-4 py-3 text-sm text-green-600">{{ success }}</p>

    <form class="space-y-4" @submit.prevent="submit">
      <label class="block">
        <span class="text-sm text-neutral-500">Début</span>
        <input v-model="start" type="datetime-local" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
      </label>

      <label class="block">
        <span class="text-sm text-neutral-500">Fin</span>
        <input v-model="end" type="datetime-local" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
      </label>

      <p v-if="duration" class="text-sm text-neutral-500">Durée : <span class="font-medium text-neutral-900">{{ duration }}</span></p>

      <div class="flex flex-wrap gap-2">
        <button type="button" class="rounded-lg bg-neutral-100 px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-200" @click="setToday(9, 17)">Aujourd'hui 9h - 17h</button>
        <button type="button" class="rounded-lg bg-neutral-100 px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-200" @click="setToday(8, 16)">Aujourd'hui 8h - 16h</button>
      </div>

      <button type="submit" class="w-full rounded-xl bg-neutral-900 py-2.5 font-semibold text-white hover:bg-neutral-700">
        {{ workingTimeId ? 'Enregistrer' : 'Créer' }}
      </button>

      <div v-if="workingTimeId" class="flex gap-2">
        <button type="button" class="flex-1 rounded-xl border border-neutral-200 py-2.5 text-sm font-medium hover:bg-neutral-50" @click="cancel">Annuler</button>
        <button type="button" class="flex-1 rounded-xl bg-red-50 py-2.5 text-sm font-medium text-red-600 hover:bg-red-100" @click="deleteWorkingTime">Supprimer</button>
      </div>
    </form>
  </div>
</template>
