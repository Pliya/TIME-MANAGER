import { store } from '@/store'

export function to_date(time)
{
  return new Date(time.replace(' ', 'T'))
}

export function sort_by_time(list, key)
{
  return [...list].sort((a, b) => (a[key] < b[key] ? -1 : a[key] > b[key] ? 1 : a.id - b.id))
}

export function hours_of(wt)
{
  return (to_date(wt.end) - to_date(wt.start)) / 3600000
}

export function hours_to_text(hours)
{
  const minutes = Math.round(hours * 60)
  return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, '0')}m`
}

export function date_key(date = new Date())
{
  const d = new Date(date)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export function now_text()
{
  const now = new Date()
  return `${date_key(now)} ${now.toTimeString().slice(0, 8)}`
}

export function month_key(date = new Date())
{
  return date_key(date).slice(0, 7)
}

export function add_days(date, days)
{
  const d = new Date(date)
  d.setDate(d.getDate() + days)
  return d
}

export function start_of_week(date = new Date())
{
  const monday = new Date(date)
  monday.setDate(monday.getDate() - (monday.getDay() + 6) % 7)
  monday.setHours(0, 0, 0, 0)
  return monday
}

export function is_night(time)
{
  const hour = to_date(time).getHours()
  return hour >= store.rules.nightStart || hour < store.rules.nightEnd
}

export function in_week(times, date = new Date())
{
  const monday = start_of_week(date)
  const next_monday = add_days(monday, 7)
  return times.filter(wt => to_date(wt.start) >= monday && to_date(wt.start) < next_monday)
}

export function in_month(times, month = month_key())
{
  return times.filter(wt => wt.start.startsWith(month))
}

export function summarize(times)
{
  let total = 0
  let night = 0
  let nights = 0
  const per_week = {}

  times.forEach(wt =>
  {
    const hours = hours_of(wt)
    total += hours
    if (is_night(wt.start)) {
      night += hours
      nights++
    }
    const week = start_of_week(to_date(wt.start)).getTime()
    per_week[week] = (per_week[week] || 0) + hours
  })

  const overtime = Object.values(per_week).reduce((sum, h) => sum + Math.max(0, h - store.rules.weekHours), 0)
  return { total, night, nights, overtime, normal: Math.max(0, total - night - overtime) }
}

export function max_consecutive_nights(times)
{
  const days = [...new Set(times.filter(wt => is_night(wt.start)).map(wt => wt.start.slice(0, 10)))].sort()
  let best = 0
  let run = 0
  days.forEach((day, i) =>
  {
    run = i > 0 && date_key(add_days(to_date(`${day} 12:00:00`), -1)) === days[i - 1] ? run + 1 : 1
    best = Math.max(best, run)
  })
  return best
}

export function compute_kpi(working_times)
{
  const days = new Set(working_times.map(wt => wt.start.slice(0, 10)))
  const total = working_times.reduce((sum, wt) => sum + Math.max(0, hours_of(wt)), 0)
  return {
    totalHours: hours_to_text(total),
    daysWorked: days.size,
    avgHours: hours_to_text(days.size ? total / days.size : 0),
    totalEntries: working_times.length,
  }
}
