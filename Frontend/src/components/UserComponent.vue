<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ChevronDown } from 'lucide-vue-next'
import { api } from '@/api'
import { logged_user_id, is_manager, is_admin, clear_session } from '@/session'

const props = defineProps({ userId: { type: Number, default: null } })

const emit = defineEmits(['user-updated'])

const router = useRouter()

const user = ref(null)
const user_id = ref(props.userId)
const open = ref(false)
const creating = ref(false)
const loading = ref(false)
const error = ref(null)
const success = ref(null)

const new_username = ref('')
const new_email = ref('')
const new_password = ref('')

const edit_username = ref('')
const edit_email = ref('')

function clear_messages()
{
  error.value = null
  success.value = null
}

function format_field_name(field)
{
  const names = {
    username: 'Username',
    email: 'Email',
    password: 'Mot de passe',
    user_id: 'Utilisateur',
    id: 'ID'
  }
  return names[field] || field
}

function get_api_errors(err)
{
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
    Object.entries(errors).forEach(([field, field_errors]) =>
    {
      if (Array.isArray(field_errors)) {
        field_errors.forEach((message) =>
        {
          messages.push(`${format_field_name(field)} : ${message}`)
        })
      } else {
        messages.push(`${format_field_name(field)} : ${field_errors}`)
      }
    })
    return messages.length === 0 ? "Les informations fournies sont invalides." : messages
  }
  if (status === 429) return "Trop de requêtes. Veuillez patienter quelques instants."
  if (status >= 500) return "Une erreur est survenue sur le serveur. Veuillez réessayer plus tard."
  return `Une erreur est survenue (HTTP ${status}).`
}

function get_user_from_response(response)
{
  if (!response?.data?.data) {
    throw new Error("Réponse invalide reçue du serveur.")
  }
  return response.data.data
}

async function get_user()
{
  if (!user_id.value) {
    user.value = null
    return
  }
  loading.value = true
  clear_messages()
  try {
    const path = user_id.value === logged_user_id.value ? '/users/me' : `/users/${user_id.value}`
    const response = await api.get(path)
    const fetched_user = get_user_from_response(response)
    user.value = fetched_user
    edit_username.value = user.value.username
    edit_email.value = user.value.email
    emit('user-updated', user.value)
  } catch (err) {
    console.error('GET USER ERROR:', err)
    user.value = null
    if (err instanceof Error && !err.response) {
      error.value = "La réponse du serveur est invalide."
    } else {
      error.value = get_api_errors(err)
    }
  } finally {
    loading.value = false
  }
}

async function create_user()
{
  loading.value = true
  clear_messages()
  if (!new_username.value) {
    error.value = "Le username est obligatoire."
    loading.value = false
    return
  }
  if (!new_email.value) {
    error.value = "L'email est obligatoire."
    loading.value = false
    return
  }
  try {
    const response = await api.post('/users', {
      user: {
        username: new_username.value,
        email: new_email.value,
        password: new_password.value
      }
    })
    get_user_from_response(response)
    new_username.value = ''
    new_email.value = ''
    new_password.value = ''
    success.value = "Utilisateur créé avec succès."
    creating.value = false
  } catch (err) {
    console.error('CREATE USER ERROR:', err)
    if (err instanceof Error && !err.response) {
      error.value = "La réponse du serveur est invalide."
    } else {
      error.value = get_api_errors(err)
    }
  } finally {
    loading.value = false
  }
}

async function update_user()
{
  if (!user.value || !user_id.value) {
    error.value = "Aucun utilisateur à modifier."
    return
  }
  loading.value = true
  clear_messages()
  if (!edit_username.value) {
    error.value = "Le username est obligatoire."
    loading.value = false
    return
  }
  if (!edit_email.value) {
    error.value = "L'email est obligatoire."
    loading.value = false
    return
  }
  try {
    const response = await api.put(`/users/${user_id.value}`, {
      user: {
        username: edit_username.value,
        email: edit_email.value
      }
    })
    const updated_user = get_user_from_response(response)
    user.value = updated_user
    edit_username.value = updated_user.username
    edit_email.value = updated_user.email
    success.value = "Utilisateur modifié avec succès."
    emit('user-updated', updated_user)
  } catch (err) {
    console.error('UPDATE USER ERROR:', err)
    if (err instanceof Error && !err.response) {
      error.value = "La réponse du serveur est invalide."
    } else {
      error.value = get_api_errors(err)
    }
  } finally {
    loading.value = false
  }
}

async function delete_user()
{
  if (!user.value || !user_id.value) {
    error.value = "Aucun utilisateur à supprimer."
    return
  }
  const confirmed = window.confirm(`Voulez-vous vraiment supprimer l'utilisateur "${user.value.username}" ?`)
  if (!confirmed) return

  loading.value = true
  clear_messages()
  try {
    await api.delete(`/users/${user_id.value}`)
    if (user_id.value === logged_user_id.value) {
      clear_session()
      router.push('/sign_in')
    }
    user.value = null
    user_id.value = null
    edit_username.value = ''
    edit_email.value = ''
    success.value = "Utilisateur supprimé avec succès."
    emit('user-updated', null)
  } catch (err) {
    console.error('DELETE USER ERROR:', err)
    error.value = get_api_errors(err)
  } finally {
    loading.value = false
  }
}

onMounted(() =>
{
  get_user()
})

watch(() => props.userId, (new_id) =>
{
  user_id.value = new_id
  get_user()
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

      <form v-if="is_manager() && user && !creating" class="space-y-3" @submit.prevent="update_user">
        <input v-model.trim="edit_username" type="text" required placeholder="Username" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model.trim="edit_email" type="email" required placeholder="Email" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <div class="flex gap-2">
          <button type="submit" :disabled="loading" class="flex-1 rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">
            {{ loading ? 'Modification...' : 'Modifier' }}
          </button>
          <button type="button" :disabled="loading" class="rounded-full bg-red-50 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-100 disabled:opacity-50" @click="delete_user">
            Supprimer
          </button>
        </div>
      </form>

      <form v-if="creating" class="space-y-3" @submit.prevent="create_user">
        <p class="text-sm font-medium">Créer un utilisateur</p>
        <input v-model.trim="new_username" type="text" required placeholder="Entrez le username" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model.trim="new_email" type="email" required placeholder="exemple@email.com" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <input v-model="new_password" type="password" required minlength="8" autocomplete="new-password" placeholder="Mot de passe (8 caractères minimum)" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm focus:border-neutral-900 focus:outline-none" />
        <button type="submit" :disabled="loading" class="w-full rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">
          {{ loading ? 'Création...' : 'Créer' }}
        </button>
      </form>

      <button v-if="is_admin()" class="mt-4 w-full text-center text-sm text-neutral-500 hover:text-neutral-900" @click="creating = !creating; clear_messages()">
        {{ creating ? 'Retour à mon profil' : 'Créer un autre utilisateur' }}
      </button>
    </div>
  </div>
</template>
