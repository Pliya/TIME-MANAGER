<script setup>
import { useRoute, useRouter } from 'vue-router'
import { ChevronRight, LogOut, RefreshCw, Wifi, WifiOff } from 'lucide-vue-next'
import LogoIcon from '@web/components/LogoIcon.vue'
import { api } from '@/api'
import { clear_session } from '@/session'
import { sections, isActive } from '../navigation'
import { online, pendingCount, syncQueue } from '../services/offline'
import { clearLocalData } from '../services/db'
import { confirmDialog } from '../services/dialog'

const route = useRoute()
const router = useRouter()

async function disconnect() {
  await syncQueue()
  if (pendingCount.value > 0) {
    const ok = await confirmDialog(
      `${pendingCount.value} modification(s) n'ont pas encore été envoyées au serveur et seront perdues. Se déconnecter quand même ?`,
      'Déconnexion',
    )
    if (!ok) return
  }
  await api.post('/users/sign_out').catch(() => {})
  await clearLocalData()
  clear_session()
  router.push('/sign_in')
}
</script>

<template>
  <div class="space-y-6">
    <div v-for="section in sections" :key="section.title" class="rounded-2xl bg-white p-5">
      <p class="card-title">{{ section.title }}</p>
      <router-link
        v-for="item in section.links"
        :key="item.to"
        :to="item.to"
        class="flex items-center gap-4 border-b border-neutral-100 py-3 text-sm tracking-wide uppercase last:border-0"
        :class="isActive(route.path, item.to) ? 'font-semibold text-brand' : 'text-neutral-900'"
      >
        <LogoIcon :name="item.logo" class="h-5 w-5" />
        <span class="flex-1">{{ item.label }}</span>
        <ChevronRight class="h-4 w-4 text-neutral-400" />
      </router-link>
    </div>

    <div class="rounded-2xl bg-white p-5">
      <p class="card-title">Synchronisation</p>
      <div class="flex items-center gap-3 text-sm">
        <Wifi v-if="online" class="h-5 w-5 shrink-0" />
        <WifiOff v-else class="h-5 w-5 shrink-0 text-amber-600" />
        <p class="flex-1">
          {{ online ? 'Connecté' : 'Hors ligne' }}
          <span class="block text-neutral-500">
            {{ pendingCount ? `${pendingCount} modification(s) en attente d'envoi` : 'Toutes les modifications sont envoyées' }}
          </span>
        </p>
      </div>
      <button
        class="mt-4 flex w-full items-center justify-center gap-2 rounded-full border-2 border-neutral-900 py-2.5 text-sm font-semibold disabled:opacity-40"
        :disabled="!online || !pendingCount"
        @click="syncQueue()"
      >
        <RefreshCw class="h-4 w-4" /> Synchroniser maintenant
      </button>
    </div>

    <button
      class="flex w-full items-center justify-center gap-3 rounded-full bg-neutral-900 py-3 text-sm font-semibold tracking-wide text-white uppercase"
      @click="disconnect"
    >
      <LogOut class="h-5 w-5" /> Se déconnecter
    </button>
  </div>
</template>