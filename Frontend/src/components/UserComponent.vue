<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ChevronDown } from 'lucide-vue-next'
import { api } from '@/api'
import { loggedUserId, isManager, isAdmin, clearSession } from '@/session'

const props = defineProps({ userId: { type: Number, default: null } })

const emit = defineEmits(['user-updated'])

const router = useRouter()

const user = ref(null)
const userId = ref(props.userId)
const open = ref(false)
const creating = ref(false)
const loading = ref(false)
const error = ref(null)
const success = ref(null)

const newUsername = ref('')
const newEmail = ref('')
const newPassword = ref('')

const editUsername = ref('')
const editEmail = ref('')

function clearMessages() {
  error.value = null
  success.value = null
}

function formatFieldName(field) {
  const names = {
    username: 'Username',
    email: 'Email',
    password: 'Mot de passe',
    user_id: 'Utilisateur',
    id: 'ID'
  }
  return names[field] || field
}

function getApiErrors(err) {
  if (!err.response) {
    return "Impossible de contacter le serveur. Vérifiez que l'API Phoenix est démarrée."
  }
  const status = err.response.status
  if (status === 400) return "La requête envoyée est invalide."
  if (status === 401) return "Vous devez être authentifié pour effectuer cette action."
  if (status === 403) return "Vous n'avez pas l'autorisation d'effectuer cette action."
  if (status === 404) return "Utilisateur introuvable."
  if (status === 409) return "Cette opération provoque un conflit avec les données existantes."
  if (status === 422) {
    const errors = err.response?.data?.errors
    if (!errors) return "Les informations fournies sont invalides."
    const messages = []
    Object.entries(errors).forEach(([field, fieldErrors]) => {
      if (Array.isArray(fieldErrors)) {
        fieldErrors.forEach((message) => {
          messages.push(`${formatFieldName(field)} : ${message}`)
        })
      } else {
        messages.push(`${formatFieldName(field)} : ${fieldErrors}`)
      }
    })
    return messages.length === 0 ? "Les informations fournies sont invalides." : messages
  }
  if (status === 429) return "Trop de requêtes. Veuillez patienter quelques instants."
  if (status >= 500) return "Une erreur est survenue sur le serveur. Veuillez réessayer plus tard."
  return `Une erreur est survenue (HTTP ${status}).`
}

function getUserFromResponse(response) {
  if (!response?.data?.data) {
    throw new Error("Réponse invalide reçue du serveur.")
  }
  return response.data.data
}

async function getUser() {
  if (!userId.value) {
    user.value = null
    return
  }
  loading.value = true
  clearMessages()
  try {
    const path = userId.value === loggedUserId.value ? '/users/me' : `/users/${userId.value}`
    const response = await api.get(path)
    const fetchedUser = getUserFromResponse(response)
    user.value = fetchedUser
    editUsername.value = user.value.username
    editEmail.value = user.value.email
    emit('user-updated', user.value)
  } catch (err) {
    console.error('GET USER ERROR:', err)
    user.value = null
    if (err instanceof Error && !err.response) {
      error.value = "La réponse du serveur est invalide."
    } else {
      error.value = getApiErrors(err)
    }
  } finally {
    loading.value = false
  }
}

async function createUser() {
  loading.value = true
  clearMessages()
  if (!newUsername.value) {
    error.value = "Le username est obligatoire."
    loading.value = false
    return
  }
  if (!newEmail.value) {
    error.value = "L'email est obligatoire."
    loading.value = false
    return
  }
  try {
    const response = await api.post('/users', {
      user: {
        username: newUsername.value,
        email: newEmail.value,
        password: newPassword.value
      }
    })
    getUserFromResponse(response)
    newUsername.value = ''
    newEmail.value = ''
    newPassword.value = ''
    success.value = "Utilisateur créé avec succès."
    creating.value = false
  } catch (err) {
    console.error('CREATE USER ERROR:', err)
    if (err instanceof Error && !err.response) {
      error.value = "La réponse du serveur est invalide."
    } else {
      error.value = getApiErrors(err)
    }
  } finally {
    loading.value = false
  }
}

async function updateUser() {
  if (!user.value || !userId.value) {
    error.value = "Aucun utilisateur à modifier."
    return
  }
  loading.value = true
  clearMessages()
  if (!editUsername.value) {
    error.value = "Le username est obligatoire."
    loading.value = false
    return
  }
  if (!editEmail.value) {
    error.value = "L'email est obligatoire."
    loading.value = false
    return
  }
  try {
    const response = await api.put(`/users/${userId.value}`, {
      user: {
        username: editUsername.value,
        email: editEmail.value
      }
    })
    const updatedUser = getUserFromResponse(response)
    user.value = updatedUser
    editUsername.value = updatedUser.username
    editEmail.value = updatedUser.email
    success.value = "Utilisateur modifié avec succès."
    emit('user-updated', updatedUser)
  } catch (err) {
    console.error('UPDATE USER ERROR:', err)
    if (err instanceof Error && !err.response) {
      error.value = "La réponse du serveur est invalide."
    } else {
      error.value = getApiErrors(err)
    }
  } finally {
    loading.value = false
  }
}

async function deleteUser() {
  if (!user.value || !userId.value) {
    error.value = "Aucun utilisateur à supprimer."
    return
  }
  const confirmed = window.confirm(`Voulez-vous vraiment supprimer l'utilisateur "${user.value.username}" ?`)
  if (!confirmed) return

  loading.value = true
  clearMessages()
  try {
    await api.delete(`/users/${userId.value}`)
    if (userId.value === loggedUserId.value) {
      clearSession()
      router.push('/sign_in')
    }
    user.value = null
    userId.value = null
    editUsername.value = ''
    editEmail.value = ''
    success.value = "Utilisateur supprimé avec succès."
    emit('user-updated', null)
  } catch (err) {
    console.error('DELETE USER ERROR:', err)
    error.value = getApiErrors(err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  getUser()
})

watch(() => props.userId, (newId) => {
  userId.value = newId
  getUser()
})
</script>

<template>
  <div class="relative">
    <button class="flex items-center gap-2 rounded-xl bg-neutral-900 px-3 py-2 text-white hover:bg-neutral-700" @click="open = !open">
      <span class="flex h-7 w-7 items-center justify-center rounded-full bg-white text-sm font-semibold text-neutral-900">
        {{ user ? user.username.charAt(0).toUpperCase() : '?' }}
      </span>
      <span class="hidden text-sm font-medium sm:inline">{{ user ? user.username : 'Aucun utilisateur' }}</span>
      <ChevronDown class="h-4 w-4 text-neutral-400" />
    </button>

    <div v-if="open" class="fixed inset-0 z-40" @click="open = false"></div>

    <div v-if="open" class="absolute right-0 z-50 mt-2 w-80 max-w-[calc(100vw-2rem)] rounded-2xl bg-white p-5 text-neutral-900 shadow-xl ring-1 ring-neutral-200">
      <div v-if="user && !loading" class="mb-5 flex items-center gap-3">
        <span class="flex h-12 w-12 items-center justify-center rounded-full bg-neutral-200 text-lg font-semibold">
          {{ user.username.charAt(0).toUpperCase() }}
        </span>
        <div class="min-w-0">
          <p class="truncate font-semibold">{{ user.username }}</p>
          <p class="truncate text-sm text-neutral-400">{{ user.email }}</p>
          <p v-if="user.role" class="mt-1 inline-block rounded-full bg-neutral-100 px-2.5 py-0.5 text-xs font-medium">{{ user.role }}</p>
        </div>
      </div>

      <p v-if="loading" class="mb-4 text-sm text-neutral-400">Chargement...</p>

      <div v-if="error" class="mb-4 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600">
        <ul v-if="Array.isArray(error)">
          <li v-for="(message, index) in error" :key="index">{{ message }}</li>
        </ul>
        <p v-else>{{ error }}</p>
      </div>
      <p v-if="success" class="mb-4 rounded-xl bg-green-50 px-3 py-2 text-sm text-green-600">{{ success }}</p>

      <form v-if="isManager() && user && !creating" class="space-y-3" @submit.prevent="updateUser">
        <input v-model.trim="editUsername" type="text" required placeholder="Username" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model.trim="editEmail" type="email" required placeholder="Email" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <div class="flex gap-2">
          <button type="submit" :disabled="loading" class="flex-1 rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">
            {{ loading ? 'Modification...' : 'Modifier' }}
          </button>
          <button type="button" :disabled="loading" class="rounded-full bg-red-50 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-100 disabled:opacity-50" @click="deleteUser">
            Supprimer
          </button>
        </div>
      </form>

      <form v-if="creating" class="space-y-3" @submit.prevent="createUser">
        <p class="text-sm font-medium">Créer un utilisateur</p>
        <input v-model.trim="newUsername" type="text" required placeholder="Entrez le username" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model.trim="newEmail" type="email" required placeholder="exemple@email.com" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model="newPassword" type="password" required minlength="8" autocomplete="new-password" placeholder="Mot de passe (8 caractères minimum)" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <button type="submit" :disabled="loading" class="w-full rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">
          {{ loading ? 'Création...' : 'Créer' }}
        </button>
      </form>

      <button v-if="isAdmin()" class="mt-4 w-full text-center text-sm text-neutral-500 hover:text-neutral-900" @click="creating = !creating; clearMessages()">
        {{ creating ? 'Retour à mon profil' : 'Créer un autre utilisateur' }}
      </button>
    </div>
  </div>
</template>
