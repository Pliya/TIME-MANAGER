<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Accessibility, CircleHelp, LogOut, Menu, X } from 'lucide-vue-next'
import UserComponent from './components/UserComponent.vue'
import AccessibilityPanel from './components/AccessibilityPanel.vue'
import LogoIcon from './components/LogoIcon.vue'
import seal from '@/assets/gotham-seal.png'
import { api } from '@/api'
import { logged_user_id, clear_session, role } from '@/session'

const route = useRoute()
const router = useRouter()
const menu_open = ref(false)
const accessibility_open = ref(false)

const user_id = computed(() => Number(route.params.userID || route.params.userid) || logged_user_id.value)

const all_sections = computed(() => [
  {
    title: 'Employé',
    roles: ['Employee'],
    links: [
      { to: '/', label: 'Dashboard', logo: 'dashboard' },
      { to: `/clock/${user_id.value}`, label: 'Pointage', logo: 'timetable' },
      { to: `/workingTimes/${user_id.value}`, label: 'Mes temps', logo: 'list' },
      { to: '/planning', label: 'Planning', logo: 'schedule' },
      { to: '/absences', label: 'Absences', logo: 'list-interface-symbol' },
      { to: `/chartManager/${user_id.value}`, label: 'Statistiques', logo: 'bar-chart' },
    ],
  },
  {
    title: 'Administrateur / RH',
    roles: ['Administrator'],
    links: [
      { to: '/utilisateurs', label: 'Utilisateurs', logo: 'data' },
      { to: '/regles', label: 'Règles', logo: 'work-plan' },
      { to: '/paie', label: 'Paie', logo: 'trend' },
      { to: '/absences-rh', label: 'Absences', logo: 'list-interface-symbol' },
    ],
  },
  {
    title: 'Manager',
    roles: ['Manager', 'Administrator'],
    links: [
      { to: '/equipe', label: 'Équipe', logo: 'monitor' },
      { to: '/alertes', label: 'Alertes', logo: 'increase' },
      { to: '/validation', label: 'Validation', logo: 'planning' },
      { to: '/planning-equipe', label: 'Planning', logo: 'schedule' },
      { to: '/statistiques-equipe', label: 'Statistiques', logo: 'chart' },
    ],
  },
])

const navigation = computed(() => all_sections.value.filter(section => section.roles.includes(role.value)))

function is_active(path)
{
  return route.path.split('/')[1] === path.split('/')[1]
}

async function disconnect()
{
  await api.post('/users/sign_out').catch(() =>
  {
  })
  clear_session()
  router.push('/sign_in')
}

watch(() => route.path, () =>
{
  menu_open.value = false
})
</script>

<template>
  <router-view v-if="route.meta.public" />

  <div v-else class="flex h-dvh bg-[#F0F0F0] font-sans text-neutral-900">
    <div v-if="menu_open" class="fixed inset-0 z-30 bg-black/40 lg:hidden" @click="menu_open = false"></div>

    <aside
      class="fixed inset-y-0 left-0 z-40 flex w-72 shrink-0 flex-col bg-gradient-to-b from-[#2b3170] to-[#171b45] text-white transition-transform lg:static lg:translate-x-0"
      :class="menu_open ? 'translate-x-0' : '-translate-x-full'"
    >
      <button class="absolute top-6 right-5 z-10 text-white lg:hidden" @click="menu_open = false">
        <X class="h-6 w-6" />
      </button>

      <div class="flex h-20 shrink-0 items-center gap-3 bg-brand px-6">
        <img :src="seal" alt="Sceau de la ville de Gotham" class="h-11 w-11 rounded-full ring-2 ring-white/70" />
        <div class="flex flex-col leading-tight">
          <span class="text-base font-bold tracking-wide uppercase">Time Manager</span>
          <span class="text-xs text-white/80 uppercase">Ville de Gotham</span>
        </div>
      </div>

      <nav class="flex-1 overflow-y-auto pt-8 pb-6">
        <div v-for="section in navigation" :key="section.title" class="mb-5">
          <p class="mb-3 px-6 text-xs font-semibold tracking-widest text-[#a7abcf] uppercase">{{ section.title }}</p>
          <router-link
            v-for="item in section.links"
            :key="item.to"
            :to="item.to"
            class="mx-3 flex items-center gap-4 rounded-[10px] px-3 py-3.5 text-sm tracking-wide uppercase"
            :class="is_active(item.to) ? 'bg-brand font-semibold text-white' : 'text-white/85 hover:bg-white/10'"
          >
            <LogoIcon :name="item.logo" class="h-5 w-5 invert" />
            {{ item.label }}
          </router-link>
        </div>
      </nav>

      <button
        v-if="logged_user_id"
        class="mb-8 flex items-center gap-4 px-6 py-4 text-sm tracking-wide text-white/85 uppercase hover:bg-white/10"
        @click="disconnect"
      >
        <LogOut class="h-5 w-5" />
        Se déconnecter
      </button>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <header class="flex h-20 shrink-0 items-center justify-between gap-3 bg-[#aec0cc] px-4 text-neutral-900 lg:px-8">
        <div class="flex items-center gap-3">
          <button class="text-neutral-900 lg:hidden" @click="menu_open = true">
            <Menu class="h-6 w-6" />
          </button>
          <h1 class="text-lg font-bold tracking-wide uppercase lg:text-xl">{{ route.meta.title }}</h1>
        </div>
        <div class="flex items-center gap-3 text-neutral-900">
          <div class="relative">
            <button class="flex hover:text-neutral-900" aria-label="Accessibilité" @click="accessibility_open = !accessibility_open">
              <Accessibility class="h-5 w-5" />
            </button>
            <div v-if="accessibility_open" class="fixed inset-0 z-40" @click="accessibility_open = false"></div>
            <AccessibilityPanel v-if="accessibility_open" class="absolute right-0 z-50 mt-3 w-72 bg-white text-neutral-900 shadow-xl" />
          </div>
          <CircleHelp class="h-5 w-5" />
          <UserComponent :user-id="user_id" />
        </div>
      </header>

      <main class="main-content flex-1 overflow-y-auto p-4 lg:px-16 lg:py-8">
        <router-view v-slot="{ Component }">
          <KeepAlive include="ClockManager">
            <component :is="Component" :user-id="user_id" />
          </KeepAlive>
        </router-view>
      </main>
    </div>
  </div>
</template>
