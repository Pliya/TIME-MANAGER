import { api } from './api'
import { store } from './store'
import { to_date, hours_of, hours_to_text, in_month, in_week, summarize, max_consecutive_nights, date_key, month_key, start_of_week, sort_by_time } from './utils/kpi'

async function with_data(user)
{
  const [clocks, times] = await Promise.all([
    api.get(`/clocks/${user.id}`).then(res => sort_by_time(res.data.data, 'time')).catch(() => []),
    api.get(`/workingtime/${user.id}`).then(res => sort_by_time(res.data.data, 'start')).catch(() => []),
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

function by_name(list)
{
  return list.sort((a, b) => a.name.localeCompare(b.name))
}

export async function load_team_members()
{
  const { data } = await api.get('/teams')
  const users = new Map()
  data.data.forEach(team => team.users.forEach(user => users.set(user.id, user)))
  return by_name(await Promise.all([...users.values()].map(with_data)))
}

export async function load_all_users()
{
  const { data } = await api.get('/users')
  return by_name(await Promise.all(data.data.map(with_data)))
}

export function team_average(members, day, exclude_id = null)
{
  const durations = members
    .filter(m => m.id !== exclude_id)
    .flatMap(m => m.times.filter(wt => wt.start.startsWith(day)).map(hours_of))
  return durations.length ? durations.reduce((a, b) => a + b, 0) / durations.length : 0
}

export function compute_alerts(members)
{
  const { maxNightsPerMonth: max_nights_per_month, maxConsecutiveNights: max_run, weekHours: week_hours } = store.rules
  const alerts = []

  members.forEach(m =>
  {
    if (m.present && (Date.now() - to_date(m.since)) > 12 * 3600000) {
      alerts.push({
        key: `open-${m.id}-${m.since}`, kind: 'open', red: true, member: m,
        title: `Pointage de sortie oublié · ${m.name}`,
        text: `Session ouverte depuis le ${m.since.slice(0, 16)}. Bloque la validation du mois.`,
      })
    }

    const month = in_month(m.times)
    const nights = summarize(month).nights
    const run = max_consecutive_nights(month)
    if (nights > max_nights_per_month || run > max_run) {
      alerts.push({
        key: `nights-${m.id}-${month_key()}-${nights}`, kind: 'nights', red: true, member: m,
        title: `Trop de nuits · ${m.name}`,
        text: `${run} nuits consécutives au plus, ${nights} nuits ce mois-ci (plafond : ${max_nights_per_month}).`,
      })
    }

    const week = summarize(in_week(m.times))
    if (week.total > week_hours) {
      alerts.push({
        key: `overtime-${m.id}-${date_key(start_of_week())}`, kind: 'overtime', red: false, member: m,
        title: `Heures sup élevées · ${m.name}`,
        text: `${hours_to_text(week.total)} cette semaine, dont ${hours_to_text(week.total - week_hours)} au-delà de ${week_hours}h.`,
      })
    }

    const limit = Date.now() - 30 * 86400000
    m.times.filter(wt => to_date(wt.start) > limit).forEach(wt =>
    {
      const day = wt.start.slice(0, 10)
      const average = team_average(members, day, m.id)
      if (average && hours_of(wt) > average * 1.5) {
        alerts.push({
          key: `unusual-${wt.id}`, kind: 'unusual', red: false, member: m, wt,
          title: `Durée inhabituelle · ${m.name}`,
          text: `${hours_to_text(hours_of(wt))} déclarées le ${day}. Moyenne de l'équipe ce jour-là : ${hours_to_text(average)}.`,
        })
      }
    })
  })

  return alerts.filter(a => !store.dismissedAlerts.includes(a.key))
}
