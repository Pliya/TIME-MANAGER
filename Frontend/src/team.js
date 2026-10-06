import { api } from './api'
import { store } from './store'
import { toDate, hoursOf, hoursToText, inMonth, inWeek, summarize, maxConsecutiveNights, dateKey, monthKey, startOfWeek, sortByTime } from './utils/kpi'

async function withData(user) {
  const [clocks, times] = await Promise.all([
    api.get(`/clocks/${user.id}`).then(res => sortByTime(res.data.data, 'time')).catch(() => []),
    api.get(`/workingtime/${user.id}`).then(res => sortByTime(res.data.data, 'start')).catch(() => []),
  ])
  const last = clocks[clocks.length - 1]
  return {
    id: user.id,
    name: user.username,
    email: user.email,
    role: user.role,
    clocks,
    times,
    present: Boolean(last?.status),
    since: last?.status ? last.time : null,
  }
}

function byName(list) {
  return list.sort((a, b) => a.name.localeCompare(b.name))
}

export async function loadTeamMembers() {
  const { data } = await api.get('/teams')
  const users = new Map()
  data.data.forEach(team => team.users.forEach(user => users.set(user.id, user)))
  return byName(await Promise.all([...users.values()].map(withData)))
}

export async function loadAllUsers() {
  const { data } = await api.get('/users')
  return byName(await Promise.all(data.data.map(withData)))
}

export function teamAverage(members, day, excludeId = null) {
  const durations = members
    .filter(m => m.id !== excludeId)
    .flatMap(m => m.times.filter(wt => wt.start.startsWith(day)).map(hoursOf))
  return durations.length ? durations.reduce((a, b) => a + b, 0) / durations.length : 0
}

export function computeAlerts(members) {
  const { maxNightsPerMonth, maxConsecutiveNights: maxRun, weekHours } = store.rules
  const alerts = []

  members.forEach(m => {
    if (m.present && (Date.now() - toDate(m.since)) > 12 * 3600000) {
      alerts.push({
        key: `open-${m.id}-${m.since}`, kind: 'open', red: true, member: m,
        title: `Pointage de sortie oublié · ${m.name}`,
        text: `Session ouverte depuis le ${m.since.slice(0, 16)}. Bloque la validation du mois.`,
      })
    }

    const month = inMonth(m.times)
    const nights = summarize(month).nights
    const run = maxConsecutiveNights(month)
    if (nights > maxNightsPerMonth || run > maxRun) {
      alerts.push({
        key: `nights-${m.id}-${monthKey()}-${nights}`, kind: 'nights', red: true, member: m,
        title: `Trop de nuits · ${m.name}`,
        text: `${run} nuits consécutives au plus, ${nights} nuits ce mois-ci (plafond : ${maxNightsPerMonth}).`,
      })
    }

    const week = summarize(inWeek(m.times))
    if (week.total > weekHours) {
      alerts.push({
        key: `overtime-${m.id}-${dateKey(startOfWeek())}`, kind: 'overtime', red: false, member: m,
        title: `Heures sup élevées · ${m.name}`,
        text: `${hoursToText(week.total)} cette semaine, dont ${hoursToText(week.total - weekHours)} au-delà de ${weekHours}h.`,
      })
    }

    const limit = Date.now() - 30 * 86400000
    m.times.filter(wt => toDate(wt.start) > limit).forEach(wt => {
      const day = wt.start.slice(0, 10)
      const average = teamAverage(members, day, m.id)
      if (average && hoursOf(wt) > average * 1.5) {
        alerts.push({
          key: `unusual-${wt.id}`, kind: 'unusual', red: false, member: m, wt,
          title: `Durée inhabituelle · ${m.name}`,
          text: `${hoursToText(hoursOf(wt))} déclarées le ${day}. Moyenne de l'équipe ce jour-là : ${hoursToText(average)}.`,
        })
      }
    })
  })

  return alerts.filter(a => !store.dismissedAlerts.includes(a.key))
}
