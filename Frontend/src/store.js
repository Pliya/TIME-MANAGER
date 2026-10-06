import { reactive, watch } from 'vue'

const STORAGE_KEY = 'timeManagerData'

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

function load() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY)) || {}
    return { ...defaults, ...saved, rules: { ...defaults.rules, ...saved.rules } }
  } catch {
    return { ...defaults }
  }
}

export const store = reactive(load())

watch(store, () => localStorage.setItem(STORAGE_KEY, JSON.stringify(store)), { deep: true })

export function newId() {
  return Date.now() + Math.floor(Math.random() * 1000)
}
