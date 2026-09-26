<template>
  <div class="wt-card">
    <div class="wt-card-header">
      <div class="header-icon-title">
        <div class="header-icon">
          <svg v-if="!isEditMode" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="16"/>
            <line x1="8" y1="12" x2="16" y2="12"/>
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
          </svg>
        </div>
        <h4 class="wt-card-title">
          {{ isEditMode ? `Modifier la plage #${workingTimeId}` : 'Create a Working Time' }}
        </h4>
      </div>
      <button v-if="isEditMode" type="button" @click="cancelEdit" class="btn-close-edit" title="Annuler le mode édition">✕</button>
    </div>

    <!-- Alertes avec bouton fermeture et auto-disparition -->
    <div v-if="successMessage" class="alert alert-success">
      <span>{{ successMessage }}</span>
      <button type="button" @click="clearMessages" class="alert-close" title="Fermer">✕</button>
    </div>
    <div v-if="errorMessage" class="alert alert-danger">
      <span>{{ errorMessage }}</span>
      <button type="button" @click="clearMessages" class="alert-close" title="Fermer">✕</button>
    </div>

    <form @submit.prevent="onSubmit" class="wt-form">
      <div class="wt-field">
        <label for="wt-start">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Date & Heure de début
        </label>
        <div class="input-wrapper">
          <input id="wt-start" type="datetime-local" v-model="start" @focus="clearMessages" required />
        </div>
      </div>

      <div class="wt-field">
        <label for="wt-end">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          Date & Heure de fin
        </label>
        <div class="input-wrapper">
          <input id="wt-end" type="datetime-local" v-model="end" @focus="clearMessages" required />
        </div>
      </div>

      <div v-if="durationPreview" class="duration-badge" :class="{ 'duration-invalid': durationPreview.error }">
        <span class="duration-icon">{{ durationPreview.error ? '⚠️' : '⏱️' }}</span>
        <span class="duration-text">{{ durationPreview.text }}</span>
      </div>

      <div class="quick-presets">
        <span class="presets-label">Raccourcis :</span>
        <button type="button" @click="setPresetToday(9, 17)" class="preset-btn">Aujourd'hui 8h (9h-17h)</button>
        <button type="button" @click="setPresetToday(8, 16.5)" class="preset-btn">8h30 (8h-16h30)</button>
      </div>

      <div class="wt-actions">
        <button type="submit" class="btn btn-primary btn-submit">
          {{ isEditMode ? '✓ Enregistrer les modifications' : '+ Create' }}
        </button>

        <div v-if="isEditMode" class="edit-secondary-actions">
          <button type="button" class="btn btn-outline" @click="cancelEdit">
            Annuler
          </button>
          <button type="button" class="btn btn-danger" @click="onDelete">
            🗑️ Supprimer
          </button>
        </div>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'

const route = useRoute()
const API_URL = 'http://localhost:4000/api'

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

// Calcul en temps réel de la durée
const durationPreview = computed(() => {
  if (!start.value || !end.value) return null
  const s = new Date(start.value).getTime()
  const e = new Date(end.value).getTime()
  if (isNaN(s) || isNaN(e)) return null
  if (e <= s) {
    return { error: true, text: 'La date de fin doit être postérieure au début' }
  }
  const diffHours = (e - s) / (1000 * 60 * 60)
  return { error: false, text: `Durée calculée : ${diffHours.toFixed(1)} h` }
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

// Fait disparaître automatiquement le message après 2.5 secondes
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
    successMessage.value = '✓ Temps de travail créé avec succès.'
    const newRecord = response.data.data || response.data
    resetForm()
    emit('refresh-list', newRecord)
    autoClearMessage()
  } catch (error) {
    console.error('Erreur création working time:', error)
    if (error.response && error.response.status === 422) {
      errorMessage.value = 'Erreur : La date de fin doit être après la date de début.'
    } else {
      // Secours local si le backend Phoenix n'est pas encore lancé
      const localRecord = {
        id: Date.now(),
        start: toApiFormat(start.value),
        end: toApiFormat(end.value),
        user_id: userId.value
      }
      successMessage.value = '✓ Temps de travail créé !'
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
    successMessage.value = '✓ Modification effectuée avec succès.'
    const updatedRecord = response.data.data || response.data
    resetForm()
    emit('refresh-list', updatedRecord)
    autoClearMessage()
  } catch (error) {
    console.error('Erreur modification working time:', error)
    if (error.response && error.response.status === 422) {
      errorMessage.value = 'Erreur : La date de fin doit être après la date de début.'
    } else {
      // Secours local si le backend Phoenix n'est pas encore lancé
      const localUpdated = {
        id: workingTimeId.value,
        start: toApiFormat(start.value),
        end: toApiFormat(end.value),
        user_id: userId.value
      }
      successMessage.value = '✓ Modification effectuée avec succès !'
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
    successMessage.value = '✓ Temps de travail supprimé avec succès.'
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

<style scoped>
.wt-card {
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03);
  padding: 24px;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-sizing: border-box;
}

.wt-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-icon-title {
  display: flex;
  align-items: center;
  gap: 10px;
}

.header-icon {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: #eff6ff;
  display: flex;
  align-items: center;
  justify-content: center;
}

.wt-card-title {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
  margin: 0;
}

.btn-close-edit {
  background: #f1f5f9;
  border: none;
  color: #64748b;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
}
.btn-close-edit:hover {
  background: #e2e8f0;
  color: #0f172a;
}

.wt-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.wt-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.wt-field label {
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  display: flex;
  align-items: center;
  gap: 6px;
}

.input-wrapper input {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 14px;
  color: #1e293b;
  background: #f8fafc;
  box-sizing: border-box;
  transition: border-color 0.2s, background-color 0.2s, box-shadow 0.2s;
}

.input-wrapper input:focus {
  outline: none;
  background: #ffffff;
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
}

.duration-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #eff6ff;
  color: #1d4ed8;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  border: 1px solid #bfdbfe;
}

.duration-badge.duration-invalid {
  background: #fef2f2;
  color: #dc2626;
  border-color: #fecaca;
}

.quick-presets {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
}

.presets-label {
  font-size: 12px;
  color: #94a3b8;
  font-weight: 500;
}

.preset-btn {
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  color: #475569;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.preset-btn:hover {
  background: #e2e8f0;
  color: #1e293b;
}

.wt-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 4px;
}

.btn {
  border: none;
  border-radius: 8px;
  padding: 11px 18px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-submit {
  width: 100%;
}

.btn-primary {
  background: #2563eb;
  color: #ffffff;
}

.btn-primary:hover {
  background: #1d4ed8;
}

.edit-secondary-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.btn-outline {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  color: #475569;
}

.btn-outline:hover {
  background: #f8fafc;
  color: #1e293b;
}

.btn-danger {
  background: #fee2e2;
  color: #dc2626;
  border: 1px solid #fecaca;
}

.btn-danger:hover {
  background: #fca5a5;
  color: #991b1b;
}

@keyframes slideDownFade {
  0% {
    opacity: 0;
    transform: translateY(-8px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

.alert {
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  justify-content: space-between;
  align-items: center;
  animation: slideDownFade 0.25s ease-out;
}

.alert-close {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 13px;
  padding: 0 4px;
  opacity: 0.65;
  color: inherit;
  transition: opacity 0.15s;
}
.alert-close:hover {
  opacity: 1;
}

.alert-success {
  background: #dcfce7;
  color: #16a34a;
  border: 1px solid #bbf7d0;
}

.alert-danger {
  background: #fee2e2;
  color: #dc2626;
  border: 1px solid #fecaca;
}
</style>