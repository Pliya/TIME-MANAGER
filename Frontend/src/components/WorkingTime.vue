<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '@/api'
import { X } from 'lucide-vue-next'
import { hours_to_text } from '@/utils/kpi'

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

const resolve_user_id = () =>
{
  const from_route = route?.params?.userid || route?.params?.userID
  if (from_route) return Number(from_route)
  if (props.userId) return Number(props.userId)
  return 1
}

const resolve_working_time_id = () =>
{
  const from_route = route?.params?.workingtimeid || route?.params?.workingTimeId
  if (from_route) return Number(from_route)
  if (props.workingTimeId) return Number(props.workingTimeId)
  return null
}

const user_id = ref(resolve_user_id())
const working_time_id = ref(resolve_working_time_id())
const start = ref(null)
const end = ref(null)
const error_message = ref('')
const success_message = ref('')

const is_edit_mode = computed(() => !!working_time_id.value)

const duration_preview = computed(() =>
{
  if (!start.value || !end.value) return null
  const s = new Date(start.value).getTime()
  const e = new Date(end.value).getTime()
  if (isNaN(s) || isNaN(e)) return null
  if (e <= s) {
    return { error: true, text: 'La date de fin doit être postérieure au début' }
  }
  const diff_hours = (e - s) / (1000 * 60 * 60)
  return { error: false, text: `Durée calculée : ${hours_to_text(diff_hours)}` }
})

function to_api_format(local_value)
{
  if (!local_value) return null
  return local_value.replace('T', ' ') + ':00'
}

function to_local_input_format(api_value)
{
  if (!api_value) return null
  const safe = api_value.includes('T') ? api_value : api_value.replace(' ', 'T')
  return safe.slice(0, 16)
}

function set_preset_today(start_h, end_h)
{
  const now = new Date()
  const pad = (n) => n.toString().padStart(2, '0')
  const date_str = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
  
  const start_hour = Math.floor(start_h)
  const start_min = Math.round((start_h - start_hour) * 60)
  const end_hour = Math.floor(end_h)
  const end_min = Math.round((end_h - end_hour) * 60)

  start.value = `${date_str}T${pad(start_hour)}:${pad(start_min)}`
  end.value = `${date_str}T${pad(end_hour)}:${pad(end_min)}`
  clear_messages()
}

let timer = null

function clear_messages()
{
  error_message.value = ''
  success_message.value = ''
  if (timer) {
    clearTimeout(timer)
    timer = null
  }
}

function auto_clear_message()
{
  if (timer) clearTimeout(timer)
  timer = setTimeout(() =>
  {
    clear_messages()
  }, 2500)
}

async function fetch_working_time()
{
  if (!working_time_id.value || !user_id.value) return
  clear_messages()
  try {
    const response = await api.get(`/workingtime/${user_id.value}/${working_time_id.value}`)
    const wt = response.data.data || response.data
    start.value = to_local_input_format(wt.start)
    end.value = to_local_input_format(wt.end)
  } catch (error) {
    console.error('Erreur récupération working time:', error)
    error_message.value = "Impossible de récupérer ce temps de travail. Vérifiez l'ID."
    working_time_id.value = null
  }
}

const get_working_time = fetch_working_time

async function create_working_time()
{
  clear_messages()
  const payload = {
    working_time: {
      start: to_api_format(start.value),
      end: to_api_format(end.value),
    },
  }

  try {
    const response = await api.post(`/workingtime/${user_id.value}`, payload)
    success_message.value = 'Temps de travail créé avec succès.'
    const new_record = response.data.data || response.data
    reset_form()
    emit('refresh-list', new_record)
    auto_clear_message()
  } catch (error) {
    console.error('Erreur création working time:', error)
    if (error.response && error.response.status === 422) {
      error_message.value = 'Erreur : La date de fin doit être après la date de début.'
    } else {
      error_message.value = 'Impossible de créer le temps de travail.'
    }
  }
}

async function update_working_time()
{
  clear_messages()
  const payload = {
    working_time: {
      start: to_api_format(start.value),
      end: to_api_format(end.value),
    },
  }
  try {
    const response = await api.put(`/workingtime/${working_time_id.value}`, payload)
    success_message.value = 'Modification effectuée avec succès.'
    const updated_record = response.data.data || response.data
    reset_form()
    emit('refresh-list', updated_record)
    auto_clear_message()
  } catch (error) {
    console.error('Erreur modification working time:', error)
    if (error.response && error.response.status === 422) {
      error_message.value = 'Erreur : La date de fin doit être après la date de début.'
    } else {
      error_message.value = 'Impossible de modifier le temps de travail.'
    }
  }
}

async function delete_working_time()
{
  const id_to_delete = working_time_id.value
  clear_messages()
  try {
    await api.delete(`/workingtime/${id_to_delete}`)
    success_message.value = 'Temps de travail supprimé avec succès.'
    reset_form()
    emit('refresh-list', { deletedId: id_to_delete })
    auto_clear_message()
  } catch (error) {
    console.error('Erreur suppression working time:', error)
    error_message.value = 'Erreur lors de la suppression du temps de travail.'
  }
}

function on_delete()
{
  if (window.confirm('Supprimer définitivement ce temps de travail ?')) {
    delete_working_time()
  }
}

function on_submit()
{
  is_edit_mode.value ? update_working_time() : create_working_time()
}

function cancel_edit()
{
  reset_form()
  emit('cancel-edit')
}

function reset_form()
{
  start.value = null
  end.value = null
  working_time_id.value = null
}

watch(
  () => [props.workingTimeId, route?.params?.workingtimeid, route?.params?.workingTimeId],
  ([new_prop_id, new_route_id, new_route_alt_id]) =>
  {
    const target = new_route_id || new_route_alt_id || new_prop_id || null
    working_time_id.value = target ? Number(target) : null
    if (working_time_id.value) {
      fetch_working_time()
    } else {
      start.value = null
      end.value = null
    }
  }
)

watch(
  () => [props.userId, route?.params?.userid, route?.params?.userID],
  ([new_prop_id, new_route_id, new_route_alt_id]) =>
  {
    const target = new_route_id || new_route_alt_id || new_prop_id
    if (target) {
      user_id.value = Number(target)
    }
    reset_form()
    clear_messages()
    if (working_time_id.value) {
      fetch_working_time()
    }
  }
)

onMounted(() =>
{
  if (working_time_id.value) fetch_working_time()
})

defineExpose({
  user_id,
  working_time_id,
  create_working_time,
  update_working_time,
  delete_working_time,
  fetch_working_time,
  get_working_time,
  reset_form,
  set_preset_today
})
</script>

<template>
  <div class="w-full max-w-xl rounded-2xl bg-white p-6">
    <div class="card-title mb-6 flex items-center justify-between">
      <p class="font-medium">{{ is_edit_mode ? `Modifier la plage #${working_time_id}` : 'Create a Working Time' }}</p>
      <button v-if="is_edit_mode" type="button" class="text-neutral-400 hover:text-neutral-600" title="Annuler le mode édition" @click="cancel_edit">
        <X class="h-5 w-5" />
      </button>
    </div>

    <div v-if="success_message" class="mb-4 flex items-center justify-between rounded-xl bg-green-50 px-4 py-3 text-sm text-green-600">
      <span>{{ success_message }}</span>
      <button type="button" title="Fermer" @click="clear_messages"><X class="h-4 w-4" /></button>
    </div>
    <div v-if="error_message" class="mb-4 flex items-center justify-between rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">
      <span>{{ error_message }}</span>
      <button type="button" title="Fermer" @click="clear_messages"><X class="h-4 w-4" /></button>
    </div>

    <form class="space-y-4" @submit.prevent="on_submit">
      <label class="block">
        <span class="text-sm text-neutral-500">{{ $t('Date & Heure de début') }}</span>
        <input v-model="start" type="datetime-local" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" @focus="clear_messages" />
      </label>

      <label class="block">
        <span class="text-sm text-neutral-500">{{ $t('Date & Heure de fin') }}</span>
        <input v-model="end" type="datetime-local" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" @focus="clear_messages" />
      </label>

      <p v-if="duration_preview" class="text-sm" :class="duration_preview.error ? 'text-red-600' : 'text-neutral-500'">
        {{ duration_preview.text }}
      </p>

      <div class="flex flex-wrap items-center gap-2">
        <span class="text-sm text-neutral-400">{{ $t('Raccourcis :') }}</span>
        <button type="button" class="rounded-lg bg-neutral-100 px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-200" @click="set_preset_today(9, 17)">{{ $t('Aujourd\'hui 8h (9h-17h)') }}</button>
        <button type="button" class="rounded-lg bg-neutral-100 px-3 py-1.5 text-sm text-neutral-600 hover:bg-neutral-200" @click="set_preset_today(8, 16.5)">{{ $t('8h30 (8h-16h30)') }}</button>
      </div>

      <button type="submit" class="w-full rounded-full bg-neutral-900 py-2.5 font-semibold text-white hover:bg-neutral-700">
        {{ is_edit_mode ? 'Enregistrer les modifications' : '+ Create' }}
      </button>

      <div v-if="is_edit_mode" class="flex gap-2">
        <button type="button" class="flex-1 rounded-full border border-neutral-200 py-2.5 text-sm font-medium hover:bg-neutral-50" @click="cancel_edit">{{ $t('Annuler') }}</button>
        <button type="button" class="flex-1 rounded-full bg-red-50 py-2.5 text-sm font-medium text-red-600 hover:bg-red-100" @click="on_delete">{{ $t('Supprimer') }}</button>
      </div>
    </form>
  </div>
</template>
