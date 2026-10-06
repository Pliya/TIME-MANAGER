<script setup>
import { ref, computed, onMounted } from 'vue'
import { Eye } from 'lucide-vue-next'
import StatCard from '@/components/StatCard.vue'
import Chip from '@/components/Chip.vue'
import ChartInterface from '@/components/ChartInterface.vue'
import LogoIcon from '@/components/LogoIcon.vue'
import { store } from '@/store'
import { loadTeamMembers } from '@/team'
import { hoursToText, hoursOf, summarize, inWeek, inMonth, toDate } from '@/utils/kpi'
import { DAY_NAMES } from '@/utils/planning'

const BLUE = '#2f6496'
const RED = '#ef4444'

const members = ref([])
onMounted(async () => {
  members.value = await loadTeamMembers().catch(() => [])
})

const rows = computed(() => members.value.map(m => ({
  name: m.name,
  week: summarize(inWeek(m.times)),
  nights: summarize(inMonth(m.times)).nights,
  weekTimes: inWeek(m.times),
})))

const total = computed(() => rows.value.reduce((t, r) => ({
  hours: t.hours + r.week.total,
  night: t.night + r.week.night,
  overtime: t.overtime + r.week.overtime,
  nights: t.nights + r.nights,
}), { hours: 0, night: 0, overtime: 0, nights: 0 }))

const average = computed(() => (rows.value.length ? total.value.hours / rows.value.length : 0))

const round = h => Number(h.toFixed(1))

const charts = computed(() => {
  const perDay = [0, 0, 0, 0, 0, 0, 0]
  rows.value.forEach(r => r.weekTimes.forEach(wt => { perDay[(toDate(wt.start).getDay() + 6) % 7] += hoursOf(wt) }))
  const names = rows.value.map(r => r.name)
  const limit = store.rules.maxNightsPerMonth
  const day = total.value.hours - total.value.night - total.value.overtime

  return [
    {
      key: 'perDay', title: "Heures de l'équipe par jour", subtitle: 'Heures cumulées de tous les agents, cette semaine',
      logo: 'schedule', types: ['bar', 'line', 'radar'],
      data: { labels: DAY_NAMES, datasets: [{ label: 'Heures travaillées (h)', data: perDay.map(round), backgroundColor: BLUE, borderColor: BLUE, borderRadius: 4 }] },
    },
    {
      key: 'perAgent', title: 'Heures par agent', subtitle: 'Total de la semaine, par ordre alphabétique',
      logo: 'bar-chart', types: ['bar', 'line', 'radar'],
      data: { labels: names, datasets: [{ label: 'Heures de la semaine (h)', data: rows.value.map(r => round(r.week.total)), backgroundColor: BLUE, borderColor: BLUE, borderRadius: 4 }] },
    },
    {
      key: 'split', title: 'Répartition des heures', subtitle: 'Jour, nuit et heures supplémentaires, cette semaine',
      logo: 'chart', types: ['pie', 'doughnut', 'polarArea'],
      data: { labels: ['Jour', 'Nuit', 'Heures sup'], datasets: [{ data: [day, total.value.night, total.value.overtime].map(round), backgroundColor: [BLUE, '#818cf8', '#f43f5e'] }] },
    },
    {
      key: 'nights', title: 'Nuits par agent', subtitle: `Ce mois-ci, plafond de ${limit} nuits (en rouge au-delà)`,
      logo: 'schedule', types: ['bar', 'line', 'radar'],
      data: {
        labels: names,
        datasets: [
          { label: 'Sous le plafond', data: rows.value.map(r => Math.min(r.nights, limit)), backgroundColor: BLUE, borderColor: BLUE, borderRadius: 4 },
          { label: 'Au-dessus du plafond', data: rows.value.map(r => Math.max(0, r.nights - limit)), backgroundColor: RED, borderColor: RED, borderRadius: 4 },
        ],
      },
    },
  ]
})

const chartTypes = ref({ perDay: 'bar', perAgent: 'bar', split: 'pie', nights: 'bar' })
const TYPE_LABELS = { line: 'Ligne', bar: 'Barres', radar: 'Radar', pie: 'Camembert', doughnut: 'Anneau', polarArea: 'Polaire' }

const options = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { position: 'top', align: 'end', labels: { usePointStyle: true, boxWidth: 6 } } },
}
</script>

<template>
  <div class="space-y-8">
    <div class="flex flex-col gap-3 rounded-2xl bg-white p-5 xl:flex-row xl:items-center xl:justify-between">
      <div class="flex flex-wrap gap-2">
        <Chip color="dark">Toute l'équipe</Chip>
        <router-link v-for="m in members" :key="m.id" :to="`/chartManager/${m.id}`">
          <Chip>{{ m.name }}</Chip>
        </router-link>
      </div>
      <p class="flex items-center gap-2 text-xs text-neutral-500">
        <Eye class="h-4 w-4 shrink-0" /> Par agent : les mêmes graphiques que ceux de l'agent.
      </p>
    </div>

    <div class="stat-grid">
      <StatCard label="Heures de l'équipe" :value="hoursToText(total.hours)" hint="Cette semaine" icon="timetable" />
      <StatCard label="Moyenne par agent" :value="hoursToText(average)" hint="Cette semaine" icon="trend" />
      <StatCard label="Heures sup" :value="hoursToText(total.overtime)" hint="Cette semaine" icon="increase" />
      <StatCard label="Nuits" :value="total.nights" hint="Ce mois-ci" icon="schedule" />
    </div>

    <section>
      <div class="mb-4 flex items-center gap-3 text-neutral-600">
        <LogoIcon name="monitor" class="h-6 w-6" />
        <h2 class="text-lg font-bold text-neutral-900">Statistiques de l'équipe</h2>
      </div>
      <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
        <div v-for="chart in charts" :key="chart.key" class="rounded-2xl bg-white p-5 shadow-sm">
          <div class="card-title flex flex-wrap items-center gap-4">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white">
              <LogoIcon :name="chart.logo" class="h-6 w-6" />
            </div>
            <div>
              <p class="font-semibold">{{ chart.title }}</p>
              <p class="text-sm text-neutral-400">{{ chart.subtitle }}</p>
            </div>
            <select v-model="chartTypes[chart.key]" class="ml-auto rounded-lg border border-neutral-200 px-3 py-1.5 text-sm text-neutral-600">
              <option v-for="type in chart.types" :key="type" :value="type">{{ TYPE_LABELS[type] }}</option>
            </select>
          </div>
          <div class="mt-6 h-64">
            <ChartInterface :key="chartTypes[chart.key]" :type="chartTypes[chart.key]" :chart-data="chart.data" :chart-options="options" />
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
