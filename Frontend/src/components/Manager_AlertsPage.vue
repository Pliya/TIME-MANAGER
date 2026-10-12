<script setup>
import { ref, computed, onMounted } from 'vue'
import LogoIcon from '@/components/LogoIcon.vue'
import { api } from '@/api'
import { now_text } from '@/utils/kpi'
import { store } from '@/store'
import { load_team_members, compute_alerts } from '@/team'

const LOGOS = { open: 'timetable', nights: 'schedule', unusual: 'data', overtime: 'increase' }

const members = ref([])
const loading = ref(true)
const message = ref('')

const alerts = computed(() => compute_alerts(members.value))

async function load()
{
  try {
    members.value = await load_team_members()
  } catch {
    message.value = 'Impossible de charger les équipes.'
  } finally {
    loading.value = false
  }
}

async function close_session(alert)
{
  await api.post(`/clocks/${alert.member.id}`, { clock: { time: now_text() } })
  message.value = `Session de ${alert.member.name} clôturée. Vérifie l'heure dans ses temps de travail.`
  load()
}

function reminders(alert)
{
  return store.reminders[alert.key] || 0
}

function remind(alert)
{
  store.reminders[alert.key] = reminders(alert) + 1
  message.value = `Relance envoyée à ${alert.member.name}.`
}

function dismiss(alert)
{
  store.dismissedAlerts.push(alert.key)
}

onMounted(load)
</script>

<template>
  <div class="space-y-4">
    <p v-if="message" class="rounded-xl bg-white px-4 py-3 text-sm text-neutral-600">{{ message }}</p>
    <p v-if="loading" class="text-sm text-neutral-400">{{ $t('Chargement...') }}</p>
    <p v-else-if="alerts.length === 0" class="rounded-2xl bg-white p-5 text-sm text-neutral-500">{{ $t('Aucune alerte : tout est en ordre.') }}</p>

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
          <button class="rounded-full border-2 border-neutral-900 bg-neutral-900 px-5 py-2 text-sm font-semibold text-white" @click="close_session(alert)">{{ $t('Corriger') }}</button>
          <button
            class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold disabled:opacity-40"
            :disabled="reminders(alert) >= store.rules.maxReminders"
            @click="remind(alert)"
          >
            {{ reminders(alert) >= store.rules.maxReminders ? $t('Relancé') : $t('Relancer ({n} fois)', { n: store.rules.maxReminders }) }}
          </button>
        </template>

        <router-link v-else-if="alert.kind === 'nights'" to="/planning-equipe" class="rounded-full border-2 border-neutral-900 bg-neutral-900 px-5 py-2 text-sm font-semibold text-white">
          {{ $t('Modifier le planning') }}
        </router-link>

        <template v-else-if="alert.kind === 'unusual'">
          <router-link :to="`/workingTime/${alert.member.id}/${alert.wt.id}`" class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold">{{ $t('Vérifier') }}</router-link>
          <button class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold" @click="dismiss(alert)">{{ $t('Valider') }}</button>
        </template>

        <router-link v-else :to="`/workingTimes/${alert.member.id}`" class="rounded-full border-2 border-neutral-900 bg-white px-5 py-2 text-sm font-semibold">
          {{ $t('Voir le détail') }}
        </router-link>
      </div>
    </div>
  </div>
</template>
