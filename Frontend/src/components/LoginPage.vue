<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Clock } from 'lucide-vue-next'
import axios from 'axios'
import { API_URL } from '@/api'
import { login } from '@/session'

const router = useRouter()

const creating = ref(false)
const email = ref('')
const username = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  try {
    const user = creating.value ? await createAccount() : await findAccount()
    if (user) {
      login(user.id)
      router.push('/')
    }
  } catch {
    error.value = creating.value ? 'Impossible de créer ce compte. Cet email est peut-être déjà utilisé.' : "Impossible de contacter l'API."
  } finally {
    loading.value = false
  }
}

async function findAccount() {
  const { data } = await axios.get(`${API_URL}/users`, { params: { email: email.value } })
  if (data.data.length === 0) error.value = 'Aucun compte avec cet email.'
  return data.data[0]
}

async function createAccount() {
  const { data } = await axios.post(`${API_URL}/users`, { user: { username: username.value, email: email.value } })
  return data.data
}
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-neutral-200 p-4 font-sans text-neutral-900">
    <div class="w-full max-w-sm rounded-2xl bg-white p-8">
      <div class="mb-8 flex items-center gap-3">
        <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-neutral-900 text-white">
          <Clock class="h-6 w-6" />
        </div>
        <span class="text-xl font-bold">Time Manager</span>
      </div>

      <p class="text-2xl font-semibold">{{ creating ? 'Créer un compte' : 'Connexion' }}</p>
      <p class="mt-1 text-sm text-neutral-400">
        {{ creating ? 'Renseigne ton nom et ton email.' : 'Entre l\'email de ton compte.' }}
      </p>

      <p v-if="error" class="mt-6 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

      <form class="mt-6 space-y-4" @submit.prevent="submit">
        <label v-if="creating" class="block">
          <span class="text-sm text-neutral-500">Nom d'utilisateur</span>
          <input v-model.trim="username" required class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
        </label>
        <label class="block">
          <span class="text-sm text-neutral-500">Email</span>
          <input v-model.trim="email" type="email" required placeholder="exemple@email.com" class="mt-1 w-full rounded-xl border border-neutral-200 px-3 py-2 focus:border-neutral-900 focus:outline-none" />
        </label>
        <button type="submit" :disabled="loading" class="w-full rounded-full bg-neutral-900 py-3 font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">
          {{ creating ? 'Créer et se connecter' : 'Se connecter' }}
        </button>
      </form>

      <button class="mt-6 w-full text-sm text-neutral-500 hover:text-neutral-900" @click="creating = !creating; error = ''">
        {{ creating ? 'J\'ai déjà un compte' : 'Pas encore de compte ? Créer un compte' }}
      </button>
    </div>
  </div>
</template>
