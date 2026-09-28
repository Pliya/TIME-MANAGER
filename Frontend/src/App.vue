<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { LayoutDashboard, Clock, ChartColumn, CalendarDays, User, ChevronDown, LogOut } from 'lucide-vue-next'
import api from '@/api'
import { loggedUserId, logout } from '@/session'

const route = useRoute()
const router = useRouter()
const currentUser = ref(null)

const userId = computed(() => Number(route.params.userID) || loggedUserId.value)

const navigation = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/clock', label: 'Pointage', icon: Clock },
  { to: '/workingTimes', label: 'Temps de travail', icon: CalendarDays },
  { to: '/charts', label: 'Statistiques', icon: ChartColumn },
]

function isActive(path) {
  if (path === '/') return route.path === '/'
  return route.path.startsWith(path)
}

function signOut() {
  logout()
  currentUser.value = null
  router.push('/login')
}

async function fetchCurrentUser() {
  if (!userId.value) return
  try {
    const { data } = await api.get(`/users/${userId.value}`)
    currentUser.value = data.data
  } catch (err) {
    currentUser.value = null
    if (err.response?.status === 404 && userId.value === loggedUserId.value) signOut()
  }
}

watch(userId, fetchCurrentUser, { immediate: true })
</script>

<template>
  <router-view v-if="route.meta.public" />

  <div v-else class="flex h-screen bg-neutral-200 font-sans text-neutral-900">
    <aside class="flex w-72 shrink-0 flex-col border-r border-neutral-200 bg-white px-5 py-7">
      <div class="mb-10 flex items-center gap-3 px-2">
        <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-neutral-900 text-white">
          <Clock class="h-6 w-6" />
        </div>
        <span class="text-xl font-bold">Time Manager</span>
      </div>

      <p class="mb-3 px-3 text-sm font-medium tracking-wider text-neutral-400 uppercase">Navigation</p>
      <nav class="flex flex-col gap-2">
        <router-link
          v-for="item in navigation"
          :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 rounded-full px-4 py-3 text-base"
          :class="isActive(item.to) ? 'bg-neutral-900 font-semibold text-white' : 'text-neutral-500 hover:bg-neutral-100'"
        >
          <component :is="item.icon" class="h-6 w-6" :class="isActive(item.to) ? 'text-white' : 'text-neutral-400'" />
          {{ item.label }}
        </router-link>
      </nav>

      <div class="my-8 border-t border-neutral-100"></div>

      <p class="mb-3 px-3 text-sm font-medium tracking-wider text-neutral-400 uppercase">Compte</p>
      <router-link
        to="/profile"
        class="flex items-center gap-3 rounded-full px-4 py-3 text-base"
        :class="isActive('/profile') ? 'bg-neutral-900 font-semibold text-white' : 'text-neutral-500 hover:bg-neutral-100'"
      >
        <User class="h-6 w-6" :class="isActive('/profile') ? 'text-white' : 'text-neutral-400'" />
        Profil
      </router-link>

      <button
        class="mt-auto flex items-center gap-3 rounded-full px-4 py-3 text-base text-neutral-500 hover:bg-red-50 hover:text-red-600"
        @click="signOut"
      >
        <LogOut class="h-6 w-6" />
        Se déconnecter
      </button>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <header class="flex h-16 shrink-0 items-center justify-between border-b border-neutral-200 bg-white px-8">
        <h1 class="text-xl font-semibold">{{ route.meta.title }}</h1>
        <div class="flex items-center gap-2 rounded-xl border border-neutral-200 px-3 py-1.5">
          <div class="flex h-7 w-7 items-center justify-center rounded-full bg-neutral-200 text-sm font-semibold text-neutral-900">
            {{ currentUser?.username?.charAt(0).toUpperCase() || '?' }}
          </div>
          <span class="text-sm font-medium">{{ currentUser?.username || 'Aucun utilisateur' }}</span>
          <ChevronDown class="h-4 w-4 text-neutral-400" />
        </div>
      </header>

      <main class="flex-1 overflow-y-auto p-8">
        <router-view v-slot="{ Component }">
          <KeepAlive include="ClockManager">
            <component :is="Component" :user-id="userId" @user-updated="currentUser = $event" />
          </KeepAlive>
        </router-view>
      </main>
    </div>
  </div>
</template>
