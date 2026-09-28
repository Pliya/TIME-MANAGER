<script setup>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/api'
import { loggedUserId, logout } from '@/session'

const props = defineProps({ userId: { type: Number, required: true } })

const emit = defineEmits(['user-updated'])

const router = useRouter()

const user = ref(null)
const editUsername = ref('')
const editEmail = ref('')
const newUsername = ref('')
const newEmail = ref('')
const error = ref('')
const success = ref('')
const loading = ref(false)

function errorMessage(err) {
  if (!err.response) return "Impossible de contacter l'API."
  if (err.response.status === 404) return 'Utilisateur introuvable.'
  const errors = err.response.data?.errors
  if (err.response.status === 422 && errors) {
    return Object.entries(errors).map(([field, messages]) => `${field} : ${[].concat(messages).join(', ')}`).join(' ; ')
  }
  return `Erreur ${err.response.status}.`
}

function setUser(value) {
  user.value = value
  editUsername.value = value?.username || ''
  editEmail.value = value?.email || ''
  emit('user-updated', value)
}

async function run(action, message) {
  loading.value = true
  error.value = ''
  success.value = ''
  try {
    await action()
    success.value = message
  } catch (err) {
    error.value = errorMessage(err)
  } finally {
    loading.value = false
  }
}

async function loadUser() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await api.get(`/users/${props.userId}`)
    setUser(data.data)
  } catch (err) {
    setUser(null)
    error.value = errorMessage(err)
  } finally {
    loading.value = false
  }
}

function createUser() {
  return run(async () => {
    await api.post('/users', { user: { username: newUsername.value, email: newEmail.value } })
    newUsername.value = ''
    newEmail.value = ''
  }, 'Utilisateur créé.')
}

function updateUser() {
  return run(async () => {
    const { data } = await api.put(`/users/${user.value.id}`, { user: { username: editUsername.value, email: editEmail.value } })
    setUser(data.data)
  }, 'Utilisateur modifié.')
}

function deleteUser() {
  if (!confirm(`Supprimer l'utilisateur ${user.value.username} ?`)) return
  return run(async () => {
    const deletedId = user.value.id
    await api.delete(`/users/${deletedId}`)
    setUser(null)
    if (deletedId === loggedUserId.value) {
      logout()
      router.push('/login')
    }
  }, 'Utilisateur supprimé.')
}

watch(() => props.userId, loadUser, { immediate: true })
</script>

<template>
  <div class="space-y-6">
    <p v-if="error" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>
    <p v-if="success" class="rounded-xl bg-green-50 px-4 py-3 text-sm text-green-600">{{ success }}</p>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
      <div v-if="user" class="rounded-2xl bg-white p-6">
        <div class="mb-6 flex items-center gap-4">
          <div class="flex h-14 w-14 items-center justify-center rounded-full bg-neutral-200 text-xl font-semibold text-neutral-900">
            {{ user.username.charAt(0).toUpperCase() }}
          </div>
          <div>
            <p class="text-lg font-semibold">{{ user.username }}</p>
            <p class="text-sm text-neutral-400">{{ user.email }} · ID {{ user.id }}</p>
          </div>
        </div>

        <form class="space-y-4" @submit.prevent="updateUser">
          <label class="block">
            <span class="text-sm text-neutral-500">Nom d'utilisateur</span>
            <input v-model.trim="editUsername" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
          </label>
          <label class="block">
            <span class="text-sm text-neutral-500">Email</span>
            <input v-model.trim="editEmail" type="email" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
          </label>
          <div class="flex gap-2">
            <button type="submit" :disabled="loading" class="flex-1 rounded-xl bg-neutral-900 py-2.5 font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">Enregistrer</button>
            <button type="button" :disabled="loading" class="rounded-xl bg-red-50 px-4 py-2.5 text-sm font-medium text-red-600 hover:bg-red-100 disabled:opacity-50" @click="deleteUser">Supprimer</button>
          </div>
        </form>
      </div>

      <div class="rounded-2xl bg-white p-6">
        <p class="mb-6 font-medium">Créer un utilisateur</p>
        <form class="space-y-4" @submit.prevent="createUser">
          <label class="block">
            <span class="text-sm text-neutral-500">Nom d'utilisateur</span>
            <input v-model.trim="newUsername" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
          </label>
          <label class="block">
            <span class="text-sm text-neutral-500">Email</span>
            <input v-model.trim="newEmail" type="email" required placeholder="exemple@email.com" class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
          </label>
          <button type="submit" :disabled="loading" class="w-full rounded-xl bg-neutral-900 py-2.5 font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">Créer</button>
        </form>
      </div>
    </div>
  </div>
</template>
