import { store } from '@/store'
import { date_key, add_days, to_date } from './kpi'

export const SHIFTS = {
  J: { label: 'Jour', start: '08:00', end: '16:00', hours: 8 },
  N: { label: 'Nuit', start: '22:00', end: '06:00', hours: 8 },
  A: { label: 'Astreinte', start: '18:00', end: '08:00', hours: 14 },
  R: { label: 'Repos', hours: 0 },
}

import { t } from '../i18n'

export const DAY_NAMES = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

export function shift_of(user_id, date)
{
  return store.planning[user_id]?.[date_key(date)] || ''
}

export function set_shift(user_id, date, shift)
{
  store.planning[user_id] = { ...store.planning[user_id], [date_key(date)]: shift }
}

export function week_days(monday)
{
  return DAY_NAMES.map((_, i) => add_days(monday, i))
}

export function planned_nights(user_id, month)
{
  return Object.entries(store.planning[user_id] || {})
    .filter(([day, shift]) => shift === 'N' && day.startsWith(month)).length
}

export function planning_warnings(user_id, monday, name)
{
  const { maxConsecutiveNights: max_consecutive_nights, maxNightsPerMonth: max_nights_per_month, restAfterNight: rest_after_night } = store.rules
  const warnings = []
  let run = 0

  week_days(monday).forEach((day, i) =>
  {
    const shift = shift_of(user_id, day)
    run = shift === 'N' ? run + 1 : 0
    if (run === max_consecutive_nights + 1) {
      warnings.push(t('{name} : plus de {max} nuits d\'affilée ({day})', { name, max: max_consecutive_nights, day: t(DAY_NAMES[i]) }))
    }
    if (rest_after_night && i > 0 && shift_of(user_id, add_days(day, -1)) === 'N' && shift && shift !== 'N' && shift !== 'R') {
      warnings.push(t('{name} : pas de repos après la nuit de {day}', { name, day: t(DAY_NAMES[i - 1]) }))
    }
  })

  const month = date_key(monday).slice(0, 7)
  if (planned_nights(user_id, month) > max_nights_per_month) {
    warnings.push(`${name} : plus de ${max_nights_per_month} nuits prévues ce mois-ci`)
  }
  return warnings
}

export function planned_hours(user_id, monday)
{
  return week_days(monday).reduce((sum, day) => sum + (SHIFTS[shift_of(user_id, day)]?.hours || 0), 0)
}

export function shift_times(shift, date)
{
  const day = date_key(date)
  const { start, end } = SHIFTS[shift]
  const end_day = end <= start ? date_key(add_days(to_date(`${day} 12:00:00`), 1)) : day
  return { start: `${day} ${start}:00`, end: `${end_day} ${end}:00` }
}
