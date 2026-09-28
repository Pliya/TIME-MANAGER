<template>
  <div class="user">

    <h1>Gestion des utilisateurs</h1>

    <div v-if="loading" class="message loading">
      Chargement...
    </div>

    <div v-if="error" class="message error">
      <strong>Erreur :</strong>
      <ul v-if="Array.isArray(error)">
        <li v-for="(message, index) in error" :key="index">
          {{ message }}
        </li>
      </ul>
      <p v-else>
        {{ error }}
      </p>
    </div>

    <div v-if="success" class="message success">
      {{ success }}
    </div>

    <div v-if="user && !loading" class="user-info">
      <h2>Utilisateur actuel</h2>
      <div class="info-row">
        <strong>ID :</strong>
        <span>{{ user.id }}</span>
      </div>
      <div class="info-row">
        <strong>Username :</strong>
        <span>{{ user.username }}</span>
      </div>
      <div class="info-row">
        <strong>Email :</strong>
        <span>{{ user.email }}</span>
      </div>
    </div>

    <hr />

    <div class="section">
      <h2>Créer un utilisateur</h2>
      <form @submit.prevent="createUser">
        <div class="form-group">
          <label for="new-username">Username</label>
          <input
            id="new-username"
            v-model.trim="newUsername"
            type="text"
            placeholder="Entrez le username"
            required
            minlength="1"
          />
        </div>

        <div class="form-group">
          <label for="new-email">Email</label>
          <input
            id="new-email"
            v-model.trim="newEmail"
            type="email"
            placeholder="exemple@email.com"
            required
          />
        </div>

        <button type="submit" :disabled="loading">
          {{ loading ? 'Création...' : 'Créer' }}
        </button>
      </form>
    </div>

    <div v-if="user" class="section">
      <hr />
      <h2>Modifier l'utilisateur</h2>
      <form @submit.prevent="updateUser">
        <div class="form-group">
          <label for="update-username">Username</label>
          <input
            id="update-username"
            v-model.trim="editUsername"
            type="text"
            required
            minlength="1"
          />
        </div>

        <div class="form-group">
          <label for="update-email">Email</label>
          <input
            id="update-email"
            v-model.trim="editEmail"
            type="email"
            required
          />
        </div>

        <button type="submit" :disabled="loading">
          {{ loading ? 'Modification...' : 'Modifier' }}
        </button>
      </form>
    </div>

    <div v-if="user" class="section">
      <hr />
      <h2>Supprimer l'utilisateur</h2>
      <button
        type="button"
        class="delete-button"
        :disabled="loading"
        @click="deleteUser"
      >
        {{ loading ? 'Suppression...' : 'Supprimer' }}
      </button>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const emit = defineEmits(['user-updated'])

const API_URL = 'http://92.4.131.118/api/users'

const user = ref(null)
const userId = ref(1)
const loading = ref(false)
const error = ref(null)
const success = ref(null)

const newUsername = ref('')
const newEmail = ref('')

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
  if (status === 400)
    return "La requête envoyée est invalide."
  if (status === 401)
    return "Vous devez être authentifié pour effectuer cette action."
  if (status === 403)
    return "Vous n'avez pas l'autorisation d'effectuer cette action."
  if (status === 404)
    return "Utilisateur introuvable."
  if (status === 409)
    return "Cette opération provoque un conflit avec les données existantes."
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
  if (status === 429)
    return "Trop de requêtes. Veuillez patienter quelques instants."
  if (status >= 500)
    return "Une erreur est survenue sur le serveur. Veuillez réessayer plus tard."
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
    const response = await axios.get(`${API_URL}/${userId.value}`)
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
    const response = await axios.post(API_URL, {
      user: {
        username: newUsername.value,
        email: newEmail.value
      }
    })
    const createdUser = getUserFromResponse(response)
    user.value = createdUser
    userId.value = createdUser.id
    editUsername.value = createdUser.username
    editEmail.value = createdUser.email
    newUsername.value = ''
    newEmail.value = ''
    success.value = "Utilisateur créé avec succès."
    emit('user-updated', createdUser)
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
    const response = await axios.put(`${API_URL}/${userId.value}`, {
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
    await axios.delete(`${API_URL}/${userId.value}`)
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
</script>

<style scoped>
.user {
  max-width: 650px;
  background: #ffffff;
  border-radius: 14px;
  padding: 32px;
  box-shadow: 0 2px 8px rgba(30,42,74,0.04);
  border: 1px solid #f1f5f9;
  margin: 0 auto;
}
h1 { font-size: 22px; font-weight: 700; color: #1e293b; margin-bottom: 24px; }
h2 { font-size: 16px; font-weight: 700; color: #334155; margin-bottom: 16px; }
.user-info { padding: 20px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; margin-bottom: 20px; }
.info-row { display: flex; gap: 10px; margin-bottom: 8px; font-size: 14px; color: #334155; }
.section { margin: 24px 0; }
form { display: flex; flex-direction: column; gap: 16px; }
.form-group { display: flex; flex-direction: column; gap: 6px; }
label { font-size: 13px; font-weight: 600; color: #475569; }
input { width: 100%; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 14px; box-sizing: border-box; }
input:focus { outline: none; border-color: #2563eb; }
button { width: fit-content; padding: 10px 20px; border: none; border-radius: 8px; cursor: pointer; font-size: 14px; font-weight: 600; background: #2563eb; color: white; transition: background 0.15s; }
button:hover { background: #1d4ed8; }
button:disabled { opacity: 0.6; cursor: not-allowed; }
.delete-button { background: #ef4444; color: white; }
.delete-button:hover { background: #dc2626; }
.message { padding: 12px 16px; margin-bottom: 20px; border-radius: 8px; font-size: 14px; }
.loading { background: #f1f5f9; color: #475569; }
.error { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
.success { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; }
.error ul { margin-top: 8px; margin-bottom: 0; padding-left: 20px; }
hr { margin: 24px 0; border: none; border-top: 1px solid #e2e8f0; }
</style>
