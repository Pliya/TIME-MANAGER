<script setup>
import { ref, computed, onMounted } from 'vue'
import { Download } from 'lucide-vue-next'
import StatCard from '@/components/StatCard.vue'
import DataTable from '@/components/DataTable.vue'
import { store } from '@/store'
import { loadAllUsers } from '@/team'
import { hoursToText, summarize, inMonth, monthKey } from '@/utils/kpi'

const month = monthKey()
const monthName = new Date().toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })

const users = ref([])
const error = ref('')

onMounted(async () => {
  try {
    users.value = await loadAllUsers()
  } catch {
    error.value = 'Impossible de charger les utilisateurs.'
  }
})

const lines = computed(() => users.value.map(u => {
  const s = summarize(inMonth(u.times, month))
  const recover = store.overtimeDecisions[`${month}-${u.id}`]?.choice === 'recover'
  return {
    name: u.name,
    normal: s.normal,
    night: s.night,
    paidOvertime: recover ? 0 : s.overtime,
    recovery: recover ? s.overtime : 0,
  }
}))

const totals = computed(() => lines.value.reduce((t, l) => ({
  normal: t.normal + l.normal,
  night: t.night + l.night,
  paidOvertime: t.paidOvertime + l.paidOvertime,
  recovery: t.recovery + l.recovery,
}), { normal: 0, night: 0, paidOvertime: 0, recovery: 0 }))

const head = computed(() => ['Agent', 'Normales', `Nuit × ${store.rules.nightRate}`, `Sup × ${store.rules.overtimeRate}`, 'Récupération'])
const rows = computed(() => lines.value.map(l => [l.name, hoursToText(l.normal), hoursToText(l.night), hoursToText(l.paidOvertime), hoursToText(l.recovery)]))

function exportCsv() {
  const csv = [
    ['Agent', 'Normales', 'Nuit', 'Heures sup payées', 'Récupération'],
    ...lines.value.map(l => [l.name, l.normal, l.night, l.paidOvertime, l.recovery].map(v => (typeof v === 'number' ? v.toFixed(2) : v))),
  ].map(line => line.join(';')).join('\n')

  const link = document.createElement('a')
  link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }))
  link.download = `paie-${month}.csv`
  link.click()
}
</script>

<template>
  <div class="space-y-6">
    <div class="stat-grid">
      <StatCard label="Heures normales" :value="hoursToText(totals.normal)" :hint="monthName" icon="timetable" />
      <StatCard :label="`Nuit × ${store.rules.nightRate}`" :value="hoursToText(totals.night)" :hint="monthName" icon="schedule" />
      <StatCard :label="`Heures sup × ${store.rules.overtimeRate}`" :value="hoursToText(totals.paidOvertime)" :hint="`Au-delà de ${store.rules.weekHours}h / semaine`" icon="increase" />
      <StatCard label="À récupérer" :value="hoursToText(totals.recovery)" hint="Non payées" icon="timetable" />
    </div>

    <p v-if="error" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

    <div class="rounded-2xl bg-white p-5">
      <div class="card-title mb-4 flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
        <p class="font-medium">Détail par agent</p>
        <button class="inline-flex items-center justify-center gap-2 rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white" @click="exportCsv">
          <Download class="h-4 w-4" /> Exporter pour la comptabilité
        </button>
      </div>
      <DataTable :head="head" :rows="rows" />
    </div>
  </div>
</template>
