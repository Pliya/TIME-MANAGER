<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { LayoutDashboard, Clock, ChartColumn, CalendarDays, User, ChevronDown } from 'lucide-vue-next'
import api from '@/api'

const route = useRoute()
const currentUser = ref(null)

const userId = computed(() => Number(route.params.userID) || 1)

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

async function fetchCurrentUser() {
  try {
    const { data } = await api.get(`/users/${userId.value}`)
    currentUser.value = data.data
  } catch {
    currentUser.value = null
  }
}

watch(userId, fetchCurrentUser, { immediate: true })
</script>

<template>
  <div class="flex h-screen bg-gray-100 font-sans text-gray-900">
    <aside class="flex w-64 shrink-0 flex-col border-r border-gray-200 bg-white px-4 py-6">
      <div class="mb-8 flex items-center gap-2 px-2">
        <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-600 text-white">
          <Clock class="h-5 w-5" />
        </div>
        <span class="text-lg font-bold">Time Manager</span>
      </div>

      <p class="mb-2 px-3 text-xs font-medium tracking-wider text-gray-400 uppercase">Navigation</p>
      <nav class="flex flex-col gap-1">
        <router-link
          v-for="item in navigation"
          :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm"
          :class="isActive(item.to) ? 'bg-gray-100 font-semibold text-gray-900' : 'text-gray-500 hover:bg-gray-50'"
        >
          <component :is="item.icon" class="h-5 w-5" :class="isActive(item.to) ? 'text-violet-600' : 'text-gray-400'" />
          {{ item.label }}
        </router-link>
      </nav>

      <div class="my-6 border-t border-gray-100"></div>

      <p class="mb-2 px-3 text-xs font-medium tracking-wider text-gray-400 uppercase">Compte</p>
      <router-link
        to="/profile"
        class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm"
        :class="isActive('/profile') ? 'bg-gray-100 font-semibold text-gray-900' : 'text-gray-500 hover:bg-gray-50'"
      >
        <User class="h-5 w-5" :class="isActive('/profile') ? 'text-violet-600' : 'text-gray-400'" />
        Profil
      </router-link>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <header class="flex h-16 shrink-0 items-center justify-between border-b border-gray-200 bg-white px-8">
        <h1 class="text-xl font-semibold">{{ route.meta.title }}</h1>
        <div class="flex items-center gap-2 rounded-xl border border-gray-200 px-3 py-1.5">
          <div class="flex h-7 w-7 items-center justify-center rounded-full bg-violet-100 text-sm font-semibold text-violet-700">
            {{ currentUser?.username?.charAt(0).toUpperCase() || '?' }}
          </div>
          <span class="text-sm font-medium">{{ currentUser?.username || 'Aucun utilisateur' }}</span>
          <ChevronDown class="h-4 w-4 text-gray-400" />
        </div>
      </header>

      <main class="flex-1 overflow-y-auto p-8">
        <router-view :user-id="userId" @user-updated="currentUser = $event" />
      </main>
    </div>
  </div>
</template>
