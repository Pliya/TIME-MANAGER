import { store } from '@/store'
import { hoursToText, addDays, toDate } from './kpi'

export const LEAVE_DAYS_PER_YEAR = 25

export function workingDays(start, end) {
  let count = 0
  for (let d = toDate(`${start} 12:00:00`); d <= toDate(`${end} 12:00:00`); d = addDays(d, 1)) {
    if (d.getDay() !== 0 && d.getDay() !== 6) count++
  }
  return count
}

export function recoveryBalance(userId) {
  const earned = Object.entries(store.overtimeDecisions)
    .filter(([key, d]) => key.endsWith(`-${userId}`) && d.choice === 'recover')
    .reduce((sum, [, d]) => sum + d.hours, 0)
  const taken = store.absences
    .filter(a => a.userId === userId && a.type === 'Récupération' && a.status !== 'Refusé')
    .reduce((sum, a) => sum + a.hours, 0)
  return earned - taken
}

export function leaveTaken(userId) {
  const year = String(new Date().getFullYear())
  return store.absences
    .filter(a => a.userId === userId && a.type === 'Congé' && a.status === 'Validé' && a.start.startsWith(year))
    .reduce((sum, a) => sum + a.days, 0)
}

export function periodText(a) {
  const format = day => toDate(`${day} 12:00:00`).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
  return a.start === a.end ? format(a.start) : `${format(a.start)} – ${format(a.end)}`
}

export function lengthText(a) {
  return a.type === 'Récupération' ? hoursToText(a.hours) : `${a.days} jour${a.days > 1 ? 's' : ''}`
}

export function statusColor(status) {
  if (status === 'Validé') return 'green'
  if (status === 'Refusé') return 'red'
  return 'gray'
}
