export function pad(n) {
  return String(n).padStart(2, '0')
}

export function toDate(value) {
  return new Date(String(value).replace(' ', 'T'))
}

export function localDateKey(date) {
  const d = date instanceof Date ? date : toDate(date)
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

export function formatTime(date) {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function formatDay(date) {
  return date.toLocaleDateString('fr-FR', { weekday: 'short', day: '2-digit', month: 'short' })
}

export function formatDuration(ms) {
  const minutes = Math.max(0, Math.floor(ms / 60000))
  return `${Math.floor(minutes / 60)}h ${pad(minutes % 60)}m`
}

export function formatDecimalHours(hours) {
  return formatDuration(hours * 3600000)
}

export function formatDecimalTime(hours) {
  const minutes = Math.round(hours * 60)
  return `${pad(Math.floor(minutes / 60))}:${pad(minutes % 60)}`
}

export function decimalHour(date) {
  return date.getHours() + date.getMinutes() / 60
}

export function hoursBetween(start, end) {
  return (end - start) / 3600000
}

export function weekdayIndex(date) {
  return (date.getDay() + 6) % 7
}

export function startOfWeek() {
  const monday = new Date()
  monday.setDate(monday.getDate() - weekdayIndex(monday))
  monday.setHours(0, 0, 0, 0)
  return monday
}

export function clocksToSessions(clocks) {
  const sorted = [...clocks].sort((a, b) => toDate(a.time) - toDate(b.time))
  const sessions = []
  let start = null
  for (const clock of sorted) {
    if (clock.status) {
      start = toDate(clock.time)
    } else if (start) {
      sessions.push({ id: clock.id, start, end: toDate(clock.time) })
      start = null
    }
  }
  return sessions
}

export function workingTimesToSessions(workingTimes) {
  return workingTimes
    .map(wt => ({ id: wt.id, start: toDate(wt.start), end: toDate(wt.end) }))
    .filter(s => s.end > s.start)
    .sort((a, b) => a.start - b.start)
}

export const WEEK_DAYS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
