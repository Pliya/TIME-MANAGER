<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/api'
import { username, role, clear_session } from '@/session'

const router = useRouter()

const form = ref({ username: '', email: '', password: '' })
const message = ref('')
const error = ref('')

onMounted(async () =>
{
  try {
    const { data } = await api.get('/users/me')
    form.value.username = data.data.username
    form.value.email = data.data.email
  } catch {
    error.value = 'Impossible de charger ton profil.'
  }
})

async function save()
{
  message.value = ''
  error.value = ''
  const user = { username: form.value.username, email: form.value.email }
  if (form.value.password) user.password = form.value.password
  try {
    const { data } = await api.put('/users/me', { user })
    username.value = data.data.username
    localStorage.setItem('username', data.data.username)
    form.value.password = ''
    message.value = 'Profil mis à jour.'
  } catch {
    error.value = 'La mise à jour a échoué.'
  }
}

async function remove()
{
  if (!confirm('Supprimer définitivement ton compte ?')) return
  try {
    await api.delete('/users/me')
    clear_session()
    router.push('/sign_in')
  } catch {
    error.value = 'La suppression a échoué.'
  }
}
</script>

<template>
  <div class="mx-auto max-w-lg space-y-6">
    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-4 font-medium">{{ $t('Mon profil') }}</p>

      <p v-if="message" class="mb-4 rounded-xl bg-green-50 px-4 py-3 text-sm text-green-700">{{ message }}</p>
      <p v-if="error" class="mb-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

      <form @submit.prevent="save">
        <label class="block">
          <span class="text-sm font-medium">{{ $t("Nom d'utilisateur") }}</span>
          <input v-model.trim="form.username" required class="mt-1 w-full rounded-xl border border-neutral-300 px-3 py-2 text-sm" />
        </label>

        <label class="mt-4 block">
          <span class="text-sm font-medium">{{ $t('Email') }}</span>
          <input v-model.trim="form.email" type="email" required class="mt-1 w-full rounded-xl border border-neutral-300 px-3 py-2 text-sm" />
        </label>

        <label class="mt-4 block">
          <span class="text-sm font-medium">{{ $t('Nouveau mot de passe') }}</span>
          <input v-model="form.password" type="password" :placeholder="$t('Laisser vide pour ne pas changer')" class="mt-1 w-full rounded-xl border border-neutral-300 px-3 py-2 text-sm" />
        </label>

        <p class="mt-4 text-sm text-neutral-500">{{ $t('Rôle') }} : <span class="font-medium text-neutral-900">{{ $t(role) }}</span></p>

        <button type="submit" class="mt-4 w-full rounded-full bg-neutral-900 py-2.5 text-sm font-semibold text-white hover:bg-neutral-700">
          {{ $t('Enregistrer') }}
        </button>
      </form>
    </div>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title mb-2 font-medium">{{ $t('Supprimer mon compte') }}</p>
      <p class="mb-4 text-sm text-neutral-500">{{ $t('Cette action est définitive : tes données seront effacées.') }}</p>
      <button type="button" @click="remove" class="rounded-full border-2 border-red-600 px-5 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50">
        {{ $t('Supprimer mon compte') }}
      </button>
    </div>
  </div>
</template>
