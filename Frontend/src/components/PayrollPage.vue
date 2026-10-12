<script setup>
import { ref, computed, onMounted } from 'vue'
import { dateLocale, t } from '@/i18n'
import { Download } from 'lucide-vue-next'
import StatCard from '@/components/StatCard.vue'
import DataTable from '@/components/DataTable.vue'
import { store } from '@/store'
import { load_all_users } from '@/team'
import { hours_to_text, summarize, in_month, month_key } from '@/utils/kpi'

const month = month_key()
const month_name = new Date().toLocaleDateString(dateLocale(), { month: 'long', year: 'numeric' })

const users = ref([])
const error = ref('')

onMounted(async () =>
{
  try {
    users.value = await load_all_users()
  } catch {
    error.value = 'Impossible de charger les utilisateurs.'
  }
})

const lines = computed(() => users.value.map(u =>
{
  const s = summarize(in_month(u.times, month))
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

const head = computed(() => [t('Agent'), t('Normales'), t('Nuit × {r}', { r: store.rules.nightRate }), t('Sup × {r}', { r: store.rules.overtimeRate }), t('Récupération')])
const rows = computed(() => lines.value.map(l => [l.name, hours_to_text(l.normal), hours_to_text(l.night), hours_to_text(l.paidOvertime), hours_to_text(l.recovery)]))

function export_csv()
{
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
      <StatCard label="Heures normales" :value="hours_to_text(totals.normal)" :hint="month_name" icon="timetable" />
      <StatCard :label="$t('Nuit × {r}', { r: store.rules.nightRate })" :value="hours_to_text(totals.night)" :hint="month_name" icon="schedule" />
      <StatCard :label="$t('Heures sup × {r}', { r: store.rules.overtimeRate })" :value="hours_to_text(totals.paidOvertime)" :hint="$t('Au-delà de {h}h / semaine', { h: store.rules.weekHours })" icon="increase" />
      <StatCard label="À récupérer" :value="hours_to_text(totals.recovery)" hint="Non payées" icon="timetable" />
    </div>

    <p v-if="error" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

    <div class="rounded-2xl bg-white p-5">
      <div class="card-title mb-4 flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
        <p class="font-medium">{{ $t('Détail par agent') }}</p>
        <button class="inline-flex items-center justify-center gap-2 rounded-full bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white" @click="export_csv">
          <Download class="h-4 w-4" /> {{ $t('Exporter pour la comptabilité') }}
        </button>
      </div>
      <DataTable :head="head" :rows="rows" />
    </div>
  </div>
</template>
