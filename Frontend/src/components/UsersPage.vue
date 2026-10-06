<script setup>
import { ref, computed, onMounted } from 'vue'
import { Search, UserPlus } from 'lucide-vue-next'
import { api } from '@/api'
import Toggle from '@/components/Toggle.vue'
import Chip from '@/components/Chip.vue'
import DataTable from '@/components/DataTable.vue'
import { store } from '@/store'
import { username } from '@/session'

const ROLES = { Employee: 'Employé', Manager: 'Manager', Administrator: 'Administrateur' }
const ASSIGNABLE = { Employee: 'Employé', Manager: 'Manager' }

const users = ref([])
const search = ref('')
const error = ref('')
const PERMISSIONS = { validate: 'Valider les heures', plan: 'Modifier le planning' }

const showForm = ref(false)
const newUser = ref({ username: '', email: '', password: '' })

const filteredUsers = computed(() =>
  users.value.filter(u => `${u.username} ${u.email}`.toLowerCase().includes(search.value.toLowerCase()))
)

async function loadUsers() {
  try {
    const { data } = await api.get('/users')
    users.value = data.data
  } catch {
    error.value = 'Impossible de charger les utilisateurs (réservé aux managers et administrateurs).'
  }
}

function log(action) {
  store.rightsHistory.unshift([new Date().toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' }), username.value, action])
}

function permission(user, name) {
  return store.permissions[user.id]?.[name] ?? user.role !== 'Employee'
}

function setPermission(user, name, value) {
  store.permissions[user.id] = { validate: permission(user, 'validate'), plan: permission(user, 'plan'), [name]: value }
  log(`${value ? 'Ajout' : 'Retrait'} du droit « ${PERMISSIONS[name]} » à ${user.username}`)
}

async function changeRole(user, event) {
  const role = event.target.value
  try {
    await api.put(`/users/${user.id}/role`, { user: { role } })
    log(`Rôle ${ROLES[role]} attribué à ${user.username}`)
    user.role = role
  } catch {
    event.target.value = user.role
    error.value = `Impossible de changer le rôle de ${user.username}.`
  }
}

async function addUser() {
  try {
    await api.post('/users', { user: newUser.value })
    newUser.value = { username: '', email: '', password: '' }
    showForm.value = false
    loadUsers()
  } catch {
    error.value = "Impossible de créer l'utilisateur. L'email est peut-être déjà utilisé."
  }
}

onMounted(loadUsers)
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
      <label class="flex items-center gap-2 rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm text-neutral-500 xl:w-80">
        <Search class="h-4 w-4" />
        <input v-model="search" placeholder="Rechercher un agent" class="w-full outline-none" />
      </label>
      <button class="inline-flex items-center justify-center gap-2 rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white" @click="showForm = !showForm">
        <UserPlus class="h-4 w-4" /> Ajouter un utilisateur
      </button>
    </div>

    <p v-if="error" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

    <form v-if="showForm" class="grid grid-cols-1 gap-3 rounded-2xl bg-white p-5 xl:grid-cols-4" @submit.prevent="addUser">
      <input v-model.trim="newUser.username" required placeholder="Nom d'utilisateur" class="rounded-xl border border-neutral-200 px-3 py-2 text-sm" />
      <input v-model.trim="newUser.email" type="email" required placeholder="Email" class="rounded-xl border border-neutral-200 px-3 py-2 text-sm" />
      <input v-model="newUser.password" type="password" required minlength="8" placeholder="Mot de passe (8 caractères min.)" class="rounded-xl border border-neutral-200 px-3 py-2 text-sm" />
      <button type="submit" class="rounded-full bg-neutral-900 px-5 py-2 text-sm font-semibold text-white">Créer</button>
    </form>

    <div class="rounded-2xl bg-white p-5">
      <div class="overflow-x-auto">
        <table class="w-full min-w-max text-sm">
          <thead>
            <tr class="bg-neutral-50 text-left text-neutral-500">
              <th class="rounded-l-lg px-3 py-3 font-medium">Nom</th>
              <th class="px-3 py-3 font-medium">Email</th>
              <th class="px-3 py-3 font-medium">Rôle</th>
              <th class="px-3 py-3 font-medium">Valider les heures</th>
              <th class="rounded-r-lg px-3 py-3 font-medium">Modifier le planning</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in filteredUsers" :key="user.id" class="border-b border-neutral-100 last:border-0">
              <td class="px-3 py-3 font-medium">{{ user.username }}</td>
              <td class="px-3 py-3">{{ user.email }}</td>
              <td class="px-3 py-3">
                <Chip v-if="user.role === 'Administrator'" color="dark">Administrateur</Chip>
                <select
                  v-else
                  :value="user.role"
                  class="rounded-full px-2.5 py-1 text-xs font-medium"
                  :class="user.role === 'Employee' ? 'bg-neutral-100' : 'bg-neutral-900 text-white'"
                  @change="changeRole(user, $event)"
                >
                  <option v-for="(label, value) in ASSIGNABLE" :key="value" :value="value">{{ label }}</option>
                </select>
              </td>
              <td v-for="(label, name) in PERMISSIONS" :key="name" class="px-3 py-3">
                <Toggle :model-value="permission(user, name)" @update:model-value="setPermission(user, name, $event)" />
              </td>
            </tr>
            <tr v-if="filteredUsers.length === 0">
              <td colspan="5" class="px-4 py-8 text-center text-neutral-400">Aucun utilisateur.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-4 font-medium">Historique des droits</p>
      <DataTable v-if="store.rightsHistory.length" :head="['Date', 'Par', 'Action']" :rows="store.rightsHistory" />
      <p v-else class="text-sm text-neutral-400">Aucun changement de droits pour l'instant.</p>
    </div>
  </div>
</template>
