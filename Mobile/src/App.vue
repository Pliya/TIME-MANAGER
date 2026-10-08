<script setup>
// Version mobile de Frontend/src/App.vue : même header, mêmes couleurs,
// même zone de contenu. La sidebar du web devient une tab bar en bas.
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Accessibility, ChevronLeft, CircleHelp, WifiOff } from 'lucide-vue-next'
import UserComponent from '@web/components/UserComponent.vue'
import AccessibilityPanel from '@web/components/AccessibilityPanel.vue'
import TabBar from './components/TabBar.vue'
import { logged_user_id } from '@/session'
import { tabs, isActive } from './navigation'
import { online, pendingCount, syncMessage, syncVersion } from './services/offline'
import { spinnerMessage } from './services/spinner'

const route = useRoute()
const router = useRouter()
const accessibilityOpen = ref(false)

const userId = computed(() => Number(route.params.userID || route.params.userid) || logged_user_id.value)

// Sous-page (ex. temps d'un agent ouvert depuis "Équipe") : bouton retour
const isSubPage = computed(() => !tabs.value.some((tab) => isActive(route.path, tab.to)))

// Une clé par vue + version de synchro : après une synchro, la vue affichée
// est rechargée avec les données du serveur.
const viewKey = computed(() => `${route.matched[0]?.path}:${syncVersion.value}`)

watch(() => route.path, () => { accessibilityOpen.value = false })
</script>

<template>
  <router-view v-if="route.meta.public" />

  <div v-else class="flex h-dvh flex-col bg-[#F0F0F0] font-sans text-neutral-900">
    <header class="shrink-0 bg-[#aec0cc] pt-[env(safe-area-inset-top)] text-neutral-900">
      <div class="flex h-16 items-center justify-between gap-3 px-4">
        <div class="flex min-w-0 items-center gap-2">
          <button v-if="isSubPage" class="-ml-1 p-1" aria-label="Retour" @click="router.back()">
            <ChevronLeft class="h-6 w-6" />
          </button>
          <h1 class="truncate text-lg font-bold tracking-wide uppercase">{{ route.meta.title }}</h1>
        </div>
        <div class="flex shrink-0 items-center gap-3">
          <div class="relative">
            <button class="flex" aria-label="Accessibilité" @click="accessibilityOpen = !accessibilityOpen">
              <Accessibility class="h-5 w-5" />
            </button>
            <div v-if="accessibilityOpen" class="fixed inset-0 z-40" @click="accessibilityOpen = false"></div>
            <AccessibilityPanel v-if="accessibilityOpen" class="absolute right-0 z-50 mt-3 w-72 max-w-[calc(100vw-2rem)] bg-white text-neutral-900 shadow-xl" />
          </div>
          <CircleHelp class="h-5 w-5" />
          <UserComponent :user-id="userId" />
        </div>
      </div>
      <div v-if="!online" class="flex items-center justify-center gap-2 bg-amber-600 px-4 py-1.5 text-xs font-medium text-white">
        <WifiOff class="h-3.5 w-3.5" />
        Hors ligne<template v-if="pendingCount"> · {{ pendingCount }} modification(s) en attente</template>
      </div>
      <div v-else-if="pendingCount" class="bg-brand px-4 py-1.5 text-center text-xs font-medium text-white">
        {{ pendingCount }} modification(s) en attente de synchronisation
      </div>
    </header>

    <main class="main-content flex-1 overflow-y-auto p-4">
      <router-view v-slot="{ Component }">
        <KeepAlive include="ClockManager" :max="3">
          <component :is="Component" :key="viewKey" :user-id="userId" />
        </KeepAlive>
      </router-view>
    </main>

    <TabBar />
  </div>

  <!-- Repli quand le plugin natif SpinnerDialog n'est pas disponible (navigateur) -->
  <div v-if="spinnerMessage" class="fixed inset-0 z-[60] flex flex-col items-center justify-center gap-4 bg-neutral-900/60 text-white">
    <span class="h-10 w-10 animate-spin rounded-full border-4 border-white border-t-transparent"></span>
    <p class="text-sm">{{ spinnerMessage }}</p>
  </div>
  <div
    v-if="syncMessage"
    class="fixed inset-x-3 top-[calc(env(safe-area-inset-top)+0.75rem)] z-[70] rounded-xl bg-neutral-900 px-4 py-3 text-center text-sm text-white shadow-xl"
  >
    {{ syncMessage }}
  </div>
</template>