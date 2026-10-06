<script setup>
import { ref, computed, onMounted } from 'vue'
import LogoIcon from '@/components/LogoIcon.vue'
import { api } from '@/api'
import { store } from '@/store'
import { loadTeamMembers, computeAlerts } from '@/team'

const LOGOS = { open: 'timetable', nights: 'schedule', unusual: 'data', overtime: 'increase' }

const members = ref([])
const loading = ref(true)
const message = ref('')

const alerts = computed(() => computeAlerts(members.value))

async function load() {
  try {
    members.value = await loadTeamMembers()
  } catch {
    message.value = 'Impossible de charger les équipes.'
  } finally {
    loading.value = false
  }
}

async function closeSession(alert) {
  await api.post(`/clocks/${alert.member.id}`)
  message.value = `Session de ${alert.member.name} clôturée. Vérifie l'heure dans ses temps de travail.`
  load()
}

function reminders(alert) {
  return store.reminders[alert.key] || 0
}

function remind(alert) {
  store.reminders[alert.key] = reminders(alert) + 1
  message.value = `Relance envoyée à ${alert.member.name}.`
}

function dismiss(alert) {
  store.dismissedAlerts.push(alert.key)
}

onMounted(load)
</script>

<template>
  <div class="space-y-4">
    <p v-if="message" class="rounded-xl bg-white px-4 py-3 text-sm text-neutral-600">{{ message }}</p>
    <p v-if="loading" class="text-sm text-neutral-400">Chargement...</p>
    <p v-else-if="alerts.length === 0" class="rounded-2xl bg-white p-5 text-sm text-neutral-500">Aucune alerte : tout est en ordre.</p>

    <div v-for="alert in alerts" :key="alert.key" class="flex flex-col gap-4 rounded-2xl bg-white p-5 xl:flex-row xl:items-center">
      <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl" :class="alert.red ? 'bg-red-50 text-red-600' : 'bg-neutral-100'">
        <LogoIcon :name="LOGOS[alert.kind]" class="h-6 w-6" />
      </div>
      <div class="flex-1">
        <p class="font-medium">{{ alert.title }}</p>
        <p class="text-sm text-neutral-500">{{ alert.text }}</p>
      </div>

      <div class="flex flex-wrap gap-2">
        <template v-if="alert.kind === 'open'">
          <button class="rounded-full border-2 border-neutral-900 bg-neutral-900 px-5 py-2 text-sm font-semibold text-white" @click="closeSession(alert)">Corriger</button>
          <button
            class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold disabled:opacity-40"
            :disabled="reminders(alert) >= store.rules.maxReminders"
            @click="remind(alert)"
          >
            {{ reminders(alert) >= store.rules.maxReminders ? 'Relancé' : `Relancer (${store.rules.maxReminders} fois)` }}
          </button>
        </template>

        <router-link v-else-if="alert.kind === 'nights'" to="/planning-equipe" class="rounded-full border-2 border-neutral-900 bg-neutral-900 px-5 py-2 text-sm font-semibold text-white">
          Modifier le planning
        </router-link>

        <template v-else-if="alert.kind === 'unusual'">
          <router-link :to="`/workingTime/${alert.member.id}/${alert.wt.id}`" class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold">Vérifier</router-link>
          <button class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold" @click="dismiss(alert)">Valider</button>
        </template>

        <router-link v-else :to="`/workingTimes/${alert.member.id}`" class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold">
          Voir le détail
        </router-link>
      </div>
    </div>
  </div>
</template>
