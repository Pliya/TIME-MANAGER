<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import { API_URL } from '@/api'
import { X } from 'lucide-vue-next'
import { hoursToText } from '@/utils/kpi'

const route = useRoute()

const props = defineProps({
  userId: {
    type: [Number, String],
    default: null
  },
  workingTimeId: {
    type: [Number, String],
    default: null
  }
})

const emit = defineEmits(['refresh-list', 'cancel-edit'])

const resolveUserId = () => {
  const fromRoute = route?.params?.userid || route?.params?.userID
  if (fromRoute) return Number(fromRoute)
  if (props.userId) return Number(props.userId)
  return 1
}

const resolveWorkingTimeId = () => {
  const fromRoute = route?.params?.workingtimeid || route?.params?.workingTimeId
  if (fromRoute) return Number(fromRoute)
  if (props.workingTimeId) return Number(props.workingTimeId)
  return null
}

const userId = ref(resolveUserId())
const workingTimeId = ref(resolveWorkingTimeId())
const start = ref(null)
const end = ref(null)
const errorMessage = ref('')
const successMessage = ref('')

const isEditMode = computed(() => !!workingTimeId.value)

const durationPreview = computed(() => {
  if (!start.value || !end.value) return null
  const s = new Date(start.value).getTime()
  const e = new Date(end.value).getTime()
  if (isNaN(s) || isNaN(e)) return null
  if (e <= s) {
    return { error: true, text: 'La date de fin doit être postérieure au début' }
  }
  const diffHours = (e - s) / (1000 * 60 * 60)
  return { error: false, text: `Durée calculée : ${hoursToText(diffHours)}` }
})

function toApiFormat(localValue) {
  if (!localValue) return null
  return localValue.replace('T', ' ') + ':00'
}

function toLocalInputFormat(apiValue) {
  if (!apiValue) return null
  const safe = apiValue.includes('T') ? apiValue : apiValue.replace(' ', 'T')
  return safe.slice(0, 16)
}

function setPresetToday(startH, endH) {
  const now = new Date()
  const pad = (n) => n.toString().padStart(2, '0')
  const dateStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
  
  const startHour = Math.floor(startH)
  const startMin = Math.round((startH - startHour) * 60)
  const endHour = Math.floor(endH)
  const endMin = Math.round((endH - endHour) * 60)

  start.value = `${dateStr}T${pad(startHour)}:${pad(startMin)}`
  end.value = `${dateStr}T${pad(endHour)}:${pad(endMin)}`
  clearMessages()
}

let timer = null

function clearMessages() {
  errorMessage.value = ''
  successMessage.value = ''
  if (timer) {
    clearTimeout(timer)
    timer = null
  }
}

function autoClearMessage() {
  if (timer) clearTimeout(timer)
  timer = setTimeout(() => {
    clearMessages()
  }, 2500)
}

async function fetchWorkingTime() {
  if (!workingTimeId.value || !userId.value) return
  clearMessages()
  try {
    const response = await axios.get(`${API_URL}/workingtime/${userId.value}/${workingTimeId.value}`)
    const wt = response.data.data || response.data
    start.value = toLocalInputFormat(wt.start)
    end.value = toLocalInputFormat(wt.end)
  } catch (error) {
    console.error('Erreur récupération working time:', error)
    errorMessage.value = "Impossible de récupérer ce temps de travail. Vérifiez l'ID."
    workingTimeId.value = null
  }
}

const getWorkingTime = fetchWorkingTime

async function createWorkingTime() {
  clearMessages()
  const payload = {
    working_time: {
      start: toApiFormat(start.value),
      end: toApiFormat(end.value),
    },
  }

  try {
    const response = await axios.post(`${API_URL}/workingtime/${userId.value}`, payload)
    successMessage.value = 'Temps de travail créé avec succès.'
    const newRecord = response.data.data || response.data
    resetForm()
    emit('refresh-list', newRecord)
    autoClearMessage()
  } catch (error) {
    console.error('Erreur création working time:', error)
    if (error.response && error.response.status === 422) {
      errorMessage.value = 'Erreur : La date de fin doit être après la date de début.'
    } else {
      const localRecord = {
        id: Date.now(),
        start: toApiFormat(start.value),
        end: toApiFormat(end.value),
        user_id: userId.value
      }
      successMessage.value = 'Temps de travail créé !'
      resetForm()
      emit('refresh-list', localRecord)
      autoClearMessage()
    }
  }
}

async function updateWorkingTime() {
  clearMessages()
  const payload = {
    working_time: {
      start: toApiFormat(start.value),
      end: toApiFormat(end.value),
    },
  }
  try {
    const response = await axios.put(`${API_URL}/workingtime/${workingTimeId.value}`, payload)
    successMessage.value = 'Modification effectuée avec succès.'
    const updatedRecord = response.data.data || response.data
    resetForm()
    emit('refresh-list', updatedRecord)
    autoClearMessage()
  } catch (error) {
    console.error('Erreur modification working time:', error)
    if (error.response && error.response.status === 422) {
      errorMessage.value = 'Erreur : La date de fin doit être après la date de début.'
    } else {
      const localUpdated = {
        id: workingTimeId.value,
        start: toApiFormat(start.value),
        end: toApiFormat(end.value),
        user_id: userId.value
      }
      successMessage.value = 'Modification effectuée avec succès !'
      resetForm()
      emit('refresh-list', localUpdated)
      autoClearMessage()
    }
  }
}

async function deleteWorkingTime() {
  const idToDelete = workingTimeId.value
  clearMessages()
  try {
    await axios.delete(`${API_URL}/workingtime/${idToDelete}`)
    successMessage.value = 'Temps de travail supprimé avec succès.'
    resetForm()
    emit('refresh-list', { deletedId: idToDelete })
    autoClearMessage()
  } catch (error) {
    console.error('Erreur suppression working time:', error)
    errorMessage.value = 'Erreur lors de la suppression du temps de travail.'
  }
}

function onDelete() {
  if (window.confirm('Supprimer définitivement ce temps de travail ?')) {
    deleteWorkingTime()
  }
}

function onSubmit() {
  isEditMode.value ? updateWorkingTime() : createWorkingTime()
}

function cancelEdit() {
  resetForm()
  emit('cancel-edit')
}

function resetForm() {
  start.value = null
  end.value = null
  workingTimeId.value = null
}

watch(
  () => [props.workingTimeId, route?.params?.workingtimeid, route?.params?.workingTimeId],
  ([newPropId, newRouteId, newRouteAltId]) => {
    const target = newRouteId || newRouteAltId || newPropId || null
    workingTimeId.value = target ? Number(target) : null
    if (workingTimeId.value) {
      fetchWorkingTime()
    } else {
      start.value = null
      end.value = null
    }
  }
)

watch(
  () => [props.userId, route?.params?.userid, route?.params?.userID],
  ([newPropId, newRouteId, newRouteAltId]) => {
    const target = newRouteId || newRouteAltId || newPropId
    if (target) {
      userId.value = Number(target)
    }
    resetForm()
    clearMessages()
    if (workingTimeId.value) {
      fetchWorkingTime()
    }
  }
)

onMounted(() => {
  if (workingTimeId.value) fetchWorkingTime()
})

defineExpose({
  userId,
  workingTimeId,
  createWorkingTime,
  updateWorkingTime,
  deleteWorkingTime,
  fetchWorkingTime,
  getWorkingTime,
  resetForm,
  setPresetToday
})
</script>

<template>
  <div class="w-full max-w-xl rounded-2xl bg-white p-6">
    <div class="mb-6 flex items-center justify-between">
      <p class="font-medium">{{ isEditMode ? `Modifier la plage #${workingTimeId}` : 'Create a Working Time' }}</p>
      <button v-if="isEditMode" type="button" class="text-neutral-400 hover:text-neutral-600" title="Annuler le mode édition" @click="cancelEdit">
        <X class="h-5 w-5" />
      </button>
    </div>

    <div v-if="successMessage" class="mb-4 flex items-center justify-between rounded-xl bg-green-50 px-4 py-3 text-sm text-green-600">
      <span>{{ successMessage }}</span>
      <button type="button" title="Fermer" @click="clearMessages"><X class="h-4 w-4" /></button>
    </div>
    <div v-if="errorMessage" class="mb-4 flex items-center justify-between rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">
      <span>{{ errorMessage }}</span>
      <button type="button" title="Fermer" @click="clearMessages"><X class="h-4 w-4" /></button>
    </div>

    <form class="space-y-4" @submit.prevent="onSubmit">
      <label class="block">
        <span class="text-sm text-neutral-500">Date & Heure de début</span>
        <input v-model="start" type="datetime-local" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" @focus="clearMessages" />
      </label>

      <label class="block">
        <span class="text-sm text-neutral-500">Date & Heure de fin</span>
        <input v-model="end" type="datetime-local" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" @focus="clearMessages" />
      </label>

      <p v-if="durationPreview" class="text-sm" :class="durationPreview.error ? 'text-red-600' : 'text-neutral-500'">
        {{ durationPreview.text }}
      </p>

      <div class="flex flex-wrap items-center gap-2">
        <span class="text-sm text-neutral-400">Raccourcis :</span>
        <button type="button" class="rounded-lg bg-neutral-100 px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-200" @click="setPresetToday(9, 17)">Aujourd'hui 8h (9h-17h)</button>
        <button type="button" class="rounded-lg bg-neutral-100 px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-200" @click="setPresetToday(8, 16.5)">8h30 (8h-16h30)</button>
      </div>

      <button type="submit" class="w-full rounded-full bg-neutral-900 py-2.5 font-semibold text-white hover:bg-neutral-700">
        {{ isEditMode ? 'Enregistrer les modifications' : '+ Create' }}
      </button>

      <div v-if="isEditMode" class="flex gap-2">
        <button type="button" class="flex-1 rounded-full border border-neutral-200 py-2.5 text-sm font-medium hover:bg-neutral-50" @click="cancelEdit">Annuler</button>
        <button type="button" class="flex-1 rounded-full bg-red-50 py-2.5 text-sm font-medium text-red-600 hover:bg-red-100" @click="onDelete">Supprimer</button>
      </div>
    </form>
  </div>
</template>
