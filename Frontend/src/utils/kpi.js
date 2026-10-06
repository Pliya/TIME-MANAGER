import { store } from '@/store'

export function toDate(time) {
  return new Date(time.replace(' ', 'T'))
}

export function sortByTime(list, key) {
  return [...list].sort((a, b) => (a[key] < b[key] ? -1 : a[key] > b[key] ? 1 : a.id - b.id))
}

export function hoursOf(wt) {
  return (toDate(wt.end) - toDate(wt.start)) / 3600000
}

export function hoursToText(hours) {
  const minutes = Math.round(hours * 60)
  return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, '0')}m`
}

export function dateKey(date = new Date()) {
  const d = new Date(date)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export function monthKey(date = new Date()) {
  return dateKey(date).slice(0, 7)
}

export function addDays(date, days) {
  const d = new Date(date)
  d.setDate(d.getDate() + days)
  return d
}

export function startOfWeek(date = new Date()) {
  const monday = new Date(date)
  monday.setDate(monday.getDate() - (monday.getDay() + 6) % 7)
  monday.setHours(0, 0, 0, 0)
  return monday
}

export function isNight(time) {
  const hour = toDate(time).getHours()
  return hour >= store.rules.nightStart || hour < store.rules.nightEnd
}

export function inWeek(times, date = new Date()) {
  const monday = startOfWeek(date)
  const nextMonday = addDays(monday, 7)
  return times.filter(wt => toDate(wt.start) >= monday && toDate(wt.start) < nextMonday)
}

export function inMonth(times, month = monthKey()) {
  return times.filter(wt => wt.start.startsWith(month))
}

export function summarize(times) {
  let total = 0
  let night = 0
  let nights = 0
  const perWeek = {}

  times.forEach(wt => {
    const hours = hoursOf(wt)
    total += hours
    if (isNight(wt.start)) {
      night += hours
      nights++
    }
    const week = startOfWeek(toDate(wt.start)).getTime()
    perWeek[week] = (perWeek[week] || 0) + hours
  })

  const overtime = Object.values(perWeek).reduce((sum, h) => sum + Math.max(0, h - store.rules.weekHours), 0)
  return { total, night, nights, overtime, normal: Math.max(0, total - night - overtime) }
}

export function maxConsecutiveNights(times) {
  const days = [...new Set(times.filter(wt => isNight(wt.start)).map(wt => wt.start.slice(0, 10)))].sort()
  let best = 0
  let run = 0
  days.forEach((day, i) => {
    run = i > 0 && dateKey(addDays(toDate(`${day} 12:00:00`), -1)) === days[i - 1] ? run + 1 : 1
    best = Math.max(best, run)
  })
  return best
}

export function computeKpi(workingTimes) {
  const days = new Set(workingTimes.map(wt => wt.start.slice(0, 10)))
  const total = workingTimes.reduce((sum, wt) => sum + Math.max(0, hoursOf(wt)), 0)
  return {
    totalHours: hoursToText(total),
    daysWorked: days.size,
    avgHours: hoursToText(days.size ? total / days.size : 0),
    totalEntries: workingTimes.length,
  }
}
