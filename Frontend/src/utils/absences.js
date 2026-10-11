import { store } from '@/store'
import { hours_to_text, add_days, to_date } from './kpi'

export const LEAVE_DAYS_PER_YEAR = 25

export function working_days(start, end)
{
  let count = 0
  for (let d = to_date(`${start} 12:00:00`); d <= to_date(`${end} 12:00:00`); d = add_days(d, 1)) {
    if (d.getDay() !== 0 && d.getDay() !== 6) count++
  }
  return count
}

export function recovery_balance(user_id)
{
  const earned = Object.entries(store.overtimeDecisions)
    .filter(([key, d]) => key.endsWith(`-${user_id}`) && d.choice === 'recover')
    .reduce((sum, [, d]) => sum + d.hours, 0)
  const taken = store.absences
    .filter(a => a.userId === user_id && a.type === 'Récupération' && a.status !== 'Refusé')
    .reduce((sum, a) => sum + a.hours, 0)
  return earned - taken
}

export function leave_taken(user_id)
{
  const year = String(new Date().getFullYear())
  return store.absences
    .filter(a => a.userId === user_id && a.type === 'Congé' && a.status === 'Validé' && a.start.startsWith(year))
    .reduce((sum, a) => sum + a.days, 0)
}

export function period_text(a)
{
  const format = day => to_date(`${day} 12:00:00`).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
  return a.start === a.end ? format(a.start) : `${format(a.start)} – ${format(a.end)}`
}

export function length_text(a)
{
  return a.type === 'Récupération' ? hours_to_text(a.hours) : `${a.days} jour${a.days > 1 ? 's' : ''}`
}

export function status_color(status)
{
  if (status === 'Validé') return 'green'
  if (status === 'Refusé') return 'red'
  return 'gray'
}

export function absence_on(user_id, day)
{
  return store.absences.find(a =>
    a.userId === user_id && a.status !== 'Refusé' && a.status !== 'En attente' && a.start <= day && a.end >= day)
}

export const ABSENCE_SHORT = { 'Congé': 'Congé', 'Arrêt maladie': 'Arrêt', 'Récupération': 'Récup.' }
