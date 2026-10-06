import { store } from '@/store'
import { dateKey, addDays, toDate } from './kpi'

export const SHIFTS = {
  J: { label: 'Jour', start: '08:00', end: '16:00', hours: 8 },
  N: { label: 'Nuit', start: '22:00', end: '06:00', hours: 8 },
  A: { label: 'Astreinte', start: '18:00', end: '08:00', hours: 14 },
  R: { label: 'Repos', hours: 0 },
}

export const DAY_NAMES = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

export function shiftOf(userId, date) {
  return store.planning[userId]?.[dateKey(date)] || ''
}

export function setShift(userId, date, shift) {
  store.planning[userId] = { ...store.planning[userId], [dateKey(date)]: shift }
}

export function weekDays(monday) {
  return DAY_NAMES.map((_, i) => addDays(monday, i))
}

export function plannedNights(userId, month) {
  return Object.entries(store.planning[userId] || {})
    .filter(([day, shift]) => shift === 'N' && day.startsWith(month)).length
}

export function planningWarnings(userId, monday, name) {
  const { maxConsecutiveNights, maxNightsPerMonth, restAfterNight } = store.rules
  const warnings = []
  let run = 0

  weekDays(monday).forEach((day, i) => {
    const shift = shiftOf(userId, day)
    run = shift === 'N' ? run + 1 : 0
    if (run === maxConsecutiveNights + 1) {
      warnings.push(`${name} : plus de ${maxConsecutiveNights} nuits d'affilée (${DAY_NAMES[i]})`)
    }
    if (restAfterNight && i > 0 && shiftOf(userId, addDays(day, -1)) === 'N' && shift && shift !== 'N' && shift !== 'R') {
      warnings.push(`${name} : pas de repos après la nuit de ${DAY_NAMES[i - 1]}`)
    }
  })

  const month = dateKey(monday).slice(0, 7)
  if (plannedNights(userId, month) > maxNightsPerMonth) {
    warnings.push(`${name} : plus de ${maxNightsPerMonth} nuits prévues ce mois-ci`)
  }
  return warnings
}

export function plannedHours(userId, monday) {
  return weekDays(monday).reduce((sum, day) => sum + (SHIFTS[shiftOf(userId, day)]?.hours || 0), 0)
}

export function shiftTimes(shift, date) {
  const day = dateKey(date)
  const { start, end } = SHIFTS[shift]
  const endDay = end <= start ? dateKey(addDays(toDate(`${day} 12:00:00`), 1)) : day
  return { start: `${day} ${start}:00`, end: `${endDay} ${end}:00` }
}
