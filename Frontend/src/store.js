import { reactive, watch } from 'vue'
import { api } from './api'
import { logged_user_id } from './session'

const defaults = {
  rules: {
    weekHours: 40,
    overtimeRate: 2,
    lateCountsAsOvertime: true,
    weekendCountsAsOvertime: true,
    dutyNotOvertime: true,
    nightStart: 22,
    nightEnd: 6,
    nightRate: 1.5,
    maxConsecutiveNights: 2,
    maxNightsPerMonth: 6,
    restAfterNight: true,
    lunchMinutes: 30,
    workedLunch: true,
    travelIsWork: true,
    mileage: true,
    minQuota: 70,
    justificationAdjustsQuota: true,
    maxReminders: 1,
    correctionsUntilValidation: true,
    managerDelayHours: 48,
    refusalNeedsReason: true,
    planningNoticeDays: 14,
  },
  planning: {},
  published: {},
  corrections: [],
  justifications: [],
  absences: [],
  overtimeDecisions: {},
  validatedSheets: {},
  reminders: {},
  dismissedAlerts: [],
  pauses: {},
  batSignal: { active: false, sector: '', since: '', mobilized: [] },
  permissions: {},
  rightsHistory: [],
}

const copy = value => JSON.parse(JSON.stringify(value))

export const store = reactive(copy(defaults))

const KEYS = Object.keys(defaults)
const synced = {}
const pending = {}

function assign(key, value)
{
  const v = key === 'rules' ? { ...defaults.rules, ...value } : value ?? copy(defaults[key])
  synced[key] = JSON.stringify(v)
  store[key] = v
}

export async function load_shared_data()
{
  if (!logged_user_id.value) return
  try {
    const { data } = await api.get('/data')
    KEYS.forEach(key =>
    {
      if (key in data.data && !pending[key]) assign(key, data.data[key])
    })
  } catch {
    return
  }
}

async function save(key)
{
  try {
    const { data } = await api.put(`/data/${key}`, { value: store[key] })
    assign(key, data.data)
  } catch {
    load_shared_data()
  } finally {
    pending[key] = null
  }
}

KEYS.forEach(key =>
{
  watch(() => store[key], value =>
  {
    if (!logged_user_id.value || JSON.stringify(value) === synced[key]) return
    clearTimeout(pending[key])
    pending[key] = setTimeout(() => save(key), 300)
  }, { deep: true })
})

watch(logged_user_id, id => (id ? load_shared_data() : KEYS.forEach(key => assign(key, copy(defaults[key])))), { immediate: true })

setInterval(load_shared_data, 15000)

export function new_id()
{
  return Date.now() + Math.floor(Math.random() * 1000)
}
