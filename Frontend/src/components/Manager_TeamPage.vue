<script setup>
import { ref, computed, onMounted } from 'vue'
import { X } from 'lucide-vue-next'
import { api } from '@/api'
import { is_admin } from '@/session'
import StatCard from '@/components/StatCard.vue'
import Chip from '@/components/Chip.vue'
import { store } from '@/store'
import { load_team_members, compute_alerts } from '@/team'
import { hours_to_text, summarize, in_week, in_month } from '@/utils/kpi'

const members = ref([])
const loading = ref(true)
const error = ref('')

const rows = computed(() => members.value.map(m =>
{
  const week = summarize(in_week(m.times))
  return { ...m, week: week.total, overtime: week.overtime, nights: summarize(in_month(m.times)).nights }
}))

const present_count = computed(() => rows.value.filter(m => m.present).length)
const team_hours = computed(() => rows.value.reduce((sum, m) => sum + m.week, 0))
const team_overtime = computed(() => rows.value.reduce((sum, m) => sum + m.overtime, 0))
const alert_count = computed(() => compute_alerts(members.value).length)

const justifications = computed(() =>
{
  const ids = members.value.map(m => m.id)
  return store.justifications.filter(j => ids.includes(j.userId)).slice(0, 5)
})

const teams = ref([])
const users = ref([])
const new_team = ref({ name: '', managerId: '' })
const to_add = ref({})
const message = ref('')

const managers = computed(() => users.value.filter(u => u.role !== 'Employee'))

function candidates(team)
{
  const in_team = team.users.map(u => u.id)
  return users.value.filter(u => !in_team.includes(u.id))
}

async function load()
{
  try {
    const [teams_res, users_res] = await Promise.all([api.get('/teams'), api.get('/users')])
    teams.value = teams_res.data.data
    users.value = users_res.data.data
    members.value = await load_team_members()
  } catch {
    error.value = 'Impossible de charger les équipes.'
  } finally {
    loading.value = false
  }
}

async function run(action, success)
{
  message.value = ''
  try {
    await action()
    message.value = success
    await load()
  } catch (err) {
    message.value = err.response?.status === 403 ? "Tu n'as pas les droits sur cette équipe." : "L'action a échoué."
  }
}

function create_team()
{
  const team = { name: new_team.value.name }
  if (is_admin()) team.manager_id = Number(new_team.value.managerId)
  run(() => api.post('/teams', { team }), `Équipe « ${team.name} » créée.`)
  new_team.value = { name: '', managerId: '' }
}

function delete_team(team)
{
  if (!confirm(`Supprimer l'équipe « ${team.name} » ?`)) return
  run(() => api.delete(`/teams/${team.id}`), `Équipe « ${team.name} » supprimée.`)
}

function add_member(team)
{
  const user_id = to_add.value[team.id]
  if (!user_id) return
  run(() => api.post(`/teams/${team.id}/users/${user_id}`), 'Agent ajouté.')
  to_add.value[team.id] = ''
}

function remove_member(team, user)
{
  run(() => api.delete(`/teams/${team.id}/users/${user.id}`), `${user.username} retiré de « ${team.name} ».`)
}

onMounted(load)
</script>

<template>
  <div class="space-y-6">
    <div class="stat-grid">
      <StatCard label="Présents" :value="`${present_count} / ${rows.length}`" hint="En ce moment" icon="monitor" />
      <StatCard label="Heures de l'équipe" :value="hours_to_text(team_hours)" hint="Cette semaine" icon="timetable" />
      <StatCard label="Heures sup" :value="hours_to_text(team_overtime)" hint="Cette semaine" icon="increase" />
      <StatCard label="Alertes" :value="alert_count" hint="À traiter" icon="data" />
    </div>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="rounded-2xl bg-white p-5 xl:col-span-2">
        <p class="card-title mb-4 font-medium">{{ $t('Mon équipe') }}</p>

        <p v-if="loading" class="text-sm text-neutral-400">{{ $t('Chargement...') }}</p>
        <p v-else-if="error" class="rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600">{{ error }}</p>
        <p v-else-if="rows.length === 0" class="text-sm text-neutral-400">{{ $t('Aucun agent dans les équipes.') }}</p>

        <div v-else class="overflow-x-auto">
          <table class="w-full min-w-max text-sm">
            <thead>
              <tr class="bg-neutral-50 text-left text-neutral-500">
                <th class="rounded-l-lg px-3 py-3 font-medium">{{ $t('Agent') }}</th>
                <th class="px-3 py-3 font-medium">{{ $t('Statut') }}</th>
                <th class="px-3 py-3 font-medium">{{ $t('Semaine') }}</th>
                <th class="px-3 py-3 font-medium">{{ $t('Heures sup') }}</th>
                <th class="rounded-r-lg px-3 py-3 font-medium">{{ $t('Nuits (mois)') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="m in rows" :key="m.id" class="border-b border-neutral-100 last:border-0">
                <td class="px-3 py-3 font-medium">
                  <router-link :to="`/workingTimes/${m.id}`" class="hover:underline">{{ m.name }}</router-link>
                </td>
                <td class="px-3 py-3">
                  <Chip v-if="m.present && store.pauses[m.id]?.since" color="outline">{{ $t('En pause') }}</Chip>
                  <Chip v-else :color="m.present ? 'dark' : 'gray'">{{ m.present ? $t('Pointé') : $t('Sorti') }}</Chip>
                </td>
                <td class="px-3 py-3">{{ hours_to_text(m.week) }}</td>
                <td class="px-3 py-3">{{ hours_to_text(m.overtime) }}</td>
                <td class="px-3 py-3">
                  <Chip v-if="m.nights > store.rules.maxNightsPerMonth" color="red">{{ m.nights }} / {{ store.rules.maxNightsPerMonth }}</Chip>
                  <template v-else>{{ m.nights }}</template>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-5">
        <p class="card-title mb-4 font-medium">{{ $t('Justifications reçues') }}</p>
        <div class="space-y-3 text-sm">
          <div v-for="j in justifications" :key="j.id" class="rounded-xl bg-neutral-50 p-3">
            <p class="font-medium">{{ j.userName }} · {{ j.type }}</p>
            <p class="text-xs text-neutral-500">« {{ j.text }} » Le {{ j.date }} à {{ j.time }}.</p>
            <p class="mt-2 text-xs text-neutral-400">{{ $t('Vu par : manager, chef d\'équipe') }}</p>
          </div>
          <p v-if="justifications.length === 0" class="text-neutral-400">{{ $t('Aucune justification pour l\'instant.') }}</p>
        </div>
      </div>
    </div>
    <div class="rounded-2xl bg-white p-5">
      <p class="card-title font-medium">{{ $t('Gérer les équipes') }}</p>
      <p v-if="!is_admin()" class="mb-2 text-xs text-neutral-400">{{ $t('Seul l’administrateur crée les équipes et nomme les managers.') }}</p>

      <form v-if="is_admin()" class="flex flex-col gap-2 xl:flex-row" @submit.prevent="create_team">
        <input v-model.trim="new_team.name" required placeholder="Nom de la nouvelle équipe" class="flex-1 rounded-xl border border-neutral-200 px-3 py-2 text-sm" />
        <select v-if="is_admin()" v-model="new_team.managerId" required class="rounded-xl border border-neutral-200 px-3 py-2 text-sm">
          <option value="" disabled>{{ $t('Manager de l\'équipe') }}</option>
          <option v-for="u in managers" :key="u.id" :value="u.id">{{ u.username }}</option>
        </select>
        <button type="submit" class="rounded-full bg-neutral-900 px-5 py-2 text-sm font-semibold text-white">{{ $t('Créer l\'équipe') }}</button>
      </form>

      <p v-if="message" class="mt-3 rounded-xl bg-neutral-100 px-3 py-2 text-sm">{{ message }}</p>

      <div class="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-2">
        <div v-for="team in teams" :key="team.id" class="rounded-xl border border-neutral-200 p-4">
          <div class="flex items-center justify-between gap-2">
            <p class="font-semibold">{{ team.name }} <span class="text-sm font-normal text-neutral-400">({{ team.users.length }})</span></p>
            <button v-if="is_admin()" class="text-xs font-medium text-red-600 hover:underline" @click="delete_team(team)">{{ $t('Supprimer') }}</button>
          </div>

          <div class="mt-3 flex flex-wrap gap-2">
            <span v-for="u in team.users" :key="u.id" class="inline-flex items-center gap-1 rounded-full bg-neutral-100 py-1 pr-1 pl-3 text-xs font-medium">
              {{ u.username }}
              <button class="rounded-full p-0.5 hover:bg-neutral-200" :aria-label="`Retirer ${u.username}`" @click="remove_member(team, u)"><X class="h-3 w-3" /></button>
            </span>
            <span v-if="team.users.length === 0" class="text-xs text-neutral-400">{{ $t('Aucun agent pour l\'instant.') }}</span>
          </div>

          <div class="mt-3 flex gap-2">
            <select v-model="to_add[team.id]" class="flex-1 rounded-xl border border-neutral-200 px-3 py-2 text-sm">
              <option value="">{{ $t('Ajouter un agent…') }}</option>
              <option v-for="u in candidates(team)" :key="u.id" :value="u.id">{{ u.username }}</option>
            </select>
            <button class="rounded-full border-2 border-neutral-900 px-4 text-sm font-semibold" @click="add_member(team)">{{ $t('Ajouter') }}</button>
          </div>
        </div>
        <p v-if="teams.length === 0 && !loading" class="text-sm text-neutral-400">{{ $t('Aucune équipe : crée la première ci-dessus.') }}</p>
      </div>
    </div>
  </div>
</template>
