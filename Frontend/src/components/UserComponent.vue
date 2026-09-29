<script setup>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ChevronDown } from 'lucide-vue-next'
import api from '@/api'
import { loggedUserId, logout } from '@/session'

const props = defineProps({ userId: { type: Number, default: null } })

const router = useRouter()

const open = ref(false)
const creating = ref(false)
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
}

function signOutIfCurrent(deletedId) {
  if (deletedId !== loggedUserId.value) return
  logout()
  router.push('/login')
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

async function getUser() {
  if (!props.userId) return setUser(null)
  try {
    const { data } = await api.get(`/users/${props.userId}`)
    setUser(data.data)
  } catch (err) {
    setUser(null)
    if (err.response?.status === 404) signOutIfCurrent(props.userId)
  }
}

function createUser() {
  return run(async () => {
    await api.post('/users', { user: { username: newUsername.value, email: newEmail.value } })
    newUsername.value = ''
    newEmail.value = ''
    creating.value = false
  }, 'Utilisateur créé.')
}

function updateUser() {
  return run(async () => {
    const { data } = await api.put(`/users/${user.value.id}`, { user: { username: editUsername.value, email: editEmail.value } })
    setUser(data.data)
  }, 'Profil modifié.')
}

function deleteUser() {
  if (!confirm(`Supprimer l'utilisateur ${user.value.username} ?`)) return
  return run(async () => {
    const deletedId = user.value.id
    await api.delete(`/users/${deletedId}`)
    setUser(null)
    signOutIfCurrent(deletedId)
  }, 'Utilisateur supprimé.')
}

watch(() => props.userId, getUser, { immediate: true })
</script>

<template>
  <div class="relative">
    <button class="flex items-center gap-2 rounded-xl border border-neutral-200 px-3 py-1.5 hover:bg-neutral-50" @click="open = !open">
      <span class="flex h-7 w-7 items-center justify-center rounded-full bg-neutral-200 text-sm font-semibold">
        {{ user?.username.charAt(0).toUpperCase() || '?' }}
      </span>
      <span class="hidden text-sm font-medium sm:inline">{{ user?.username || 'Aucun utilisateur' }}</span>
      <ChevronDown class="h-4 w-4 text-neutral-400" />
    </button>

    <div v-if="open" class="fixed inset-0 z-40" @click="open = false"></div>

    <div v-if="open" class="absolute right-0 z-50 mt-2 w-80 max-w-[calc(100vw-2rem)] rounded-2xl bg-white p-5 shadow-xl ring-1 ring-neutral-200">
      <div v-if="user" class="mb-5 flex items-center gap-3">
        <span class="flex h-12 w-12 items-center justify-center rounded-full bg-neutral-200 text-lg font-semibold">
          {{ user.username.charAt(0).toUpperCase() }}
        </span>
        <div class="min-w-0">
          <p class="truncate font-semibold">{{ user.username }}</p>
          <p class="truncate text-sm text-neutral-400">{{ user.email }}</p>
        </div>
      </div>

      <p v-if="error" class="mb-4 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600">{{ error }}</p>
      <p v-if="success" class="mb-4 rounded-xl bg-green-50 px-3 py-2 text-sm text-green-600">{{ success }}</p>

      <form v-if="user && !creating" class="space-y-3" @submit.prevent="updateUser">
        <input v-model.trim="editUsername" required placeholder="Nom d'utilisateur" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model.trim="editEmail" type="email" required placeholder="Email" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <div class="flex gap-2">
          <button type="submit" :disabled="loading" class="flex-1 rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">Enregistrer</button>
          <button type="button" :disabled="loading" class="rounded-full bg-red-50 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-100 disabled:opacity-50" @click="deleteUser">Supprimer</button>
        </div>
      </form>

      <form v-if="creating" class="space-y-3" @submit.prevent="createUser">
        <p class="text-sm font-medium">Créer un utilisateur</p>
        <input v-model.trim="newUsername" required placeholder="Nom d'utilisateur" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model.trim="newEmail" type="email" required placeholder="exemple@email.com" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <button type="submit" :disabled="loading" class="w-full rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">Créer</button>
      </form>

      <button class="mt-4 w-full text-center text-sm text-neutral-500 hover:text-neutral-900" @click="creating = !creating; error = ''; success = ''">
        {{ creating ? 'Retour à mon profil' : 'Créer un autre utilisateur' }}
      </button>
    </div>
  </div>
</template>
