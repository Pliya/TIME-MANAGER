<script setup>
import { useRoute } from 'vue-router'
import { Menu } from 'lucide-vue-next'
import LogoIcon from '@web/components/LogoIcon.vue'
import { tabs, isActive } from '../navigation'
import { pendingCount } from '../services/offline'

const route = useRoute()
</script>

<template>
  <!-- Mêmes couleurs que la sidebar du web, placée en bas (plus facile à atteindre au pouce) -->
  <nav class="flex shrink-0 bg-gradient-to-b from-[#2b3170] to-[#171b45] pb-[env(safe-area-inset-bottom)] text-white">
    <router-link
      v-for="tab in tabs"
      :key="tab.to"
      :to="tab.to"
      class="relative flex min-w-0 flex-1 flex-col items-center gap-1 px-1 pt-2.5 pb-2 text-[10px] font-semibold tracking-wide uppercase"
      :class="isActive(route.path, tab.to) ? 'bg-brand text-white' : 'text-white/75'"
    >
      <Menu v-if="tab.more" class="h-5 w-5" />
      <LogoIcon v-else :name="tab.logo" class="h-5 w-5 invert" />
      <span class="w-full truncate text-center">{{ $t(tab.label) }}</span>
      <span
        v-if="tab.more && pendingCount"
        class="absolute top-1.5 left-1/2 ml-2 rounded-full bg-amber-500 px-1.5 text-[10px] leading-4 text-white"
      >{{ pendingCount }}</span>
    </router-link>
  </nav>
</template>