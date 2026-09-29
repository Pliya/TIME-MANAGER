<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { LayoutDashboard, Clock, ChartColumn, CalendarDays, LogOut, Menu, X } from 'lucide-vue-next'
import UserComponent from './components/UserComponent.vue'
import { loggedUserId, logout } from '@/session'

const route = useRoute()
const router = useRouter()
const menuOpen = ref(false)

const userId = computed(() => Number(route.params.userID || route.params.userid) || loggedUserId.value)

const navigation = computed(() => [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: `/clock/${userId.value}`, label: 'Pointage', icon: Clock },
  { to: `/workingTimes/${userId.value}`, label: 'Temps de travail', icon: CalendarDays },
  { to: `/chartManager/${userId.value}`, label: 'Statistiques', icon: ChartColumn },
])

function isActive(path) {
  if (path === '/') return route.path === '/'
  return route.path.startsWith(path.split('/').slice(0, 2).join('/'))
}

function signOut() {
  logout()
  router.push('/login')
}

watch(() => route.path, () => { menuOpen.value = false })
</script>

<template>
  <router-view v-if="route.meta.public" />

  <div v-else class="flex h-dvh bg-neutral-200 font-sans text-neutral-900">
    <div v-if="menuOpen" class="fixed inset-0 z-30 bg-black/40 lg:hidden" @click="menuOpen = false"></div>

    <aside
      class="fixed inset-y-0 left-0 z-40 flex w-72 shrink-0 flex-col border-r border-neutral-200 bg-white px-5 py-7 transition-transform lg:static lg:translate-x-0"
      :class="menuOpen ? 'translate-x-0' : '-translate-x-full'"
    >
      <button class="absolute top-7 right-5 text-neutral-400 lg:hidden" @click="menuOpen = false">
        <X class="h-6 w-6" />
      </button>

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

      <button
        class="mt-auto flex items-center gap-3 rounded-full px-4 py-3 text-base text-neutral-500 hover:bg-red-50 hover:text-red-600"
        @click="signOut"
      >
        <LogOut class="h-6 w-6" />
        Se déconnecter
      </button>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <header class="flex h-16 shrink-0 items-center justify-between gap-3 border-b border-neutral-200 bg-white px-4 lg:px-8">
        <div class="flex items-center gap-3">
          <button class="text-neutral-700 lg:hidden" @click="menuOpen = true">
            <Menu class="h-6 w-6" />
          </button>
          <h1 class="text-lg font-semibold lg:text-xl">{{ route.meta.title }}</h1>
        </div>
        <UserComponent :user-id="userId" />
      </header>

      <main class="flex-1 overflow-y-auto p-4 lg:p-8">
        <router-view v-slot="{ Component }">
          <KeepAlive include="ClockManager">
            <component :is="Component" :user-id="userId" />
          </KeepAlive>
        </router-view>
      </main>
    </div>
  </div>
</template>
