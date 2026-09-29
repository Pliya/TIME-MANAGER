export function hoursToText(hours) {
  const minutes = Math.round(hours * 60)
  return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, '0')}m`
}

export function computeKpi(workingTimes) {
  let totalMs = 0
  const uniqueDays = new Set()

  workingTimes.forEach(wt => {
    if (!wt.start || !wt.end) return
    const s = new Date(wt.start.replace(' ', 'T')).getTime()
    const e = new Date(wt.end.replace(' ', 'T')).getTime()
    if (!isNaN(s) && !isNaN(e) && e > s) {
      totalMs += e - s
      uniqueDays.add(wt.start.slice(0, 10))
    }
  })

  const totalHours = totalMs / (1000 * 60 * 60)
  const daysWorked = uniqueDays.size
  const avgHours = daysWorked > 0 ? totalHours / daysWorked : 0

  return {
    totalHours: hoursToText(totalHours),
    daysWorked,
    avgHours: hoursToText(avgHours),
    totalEntries: workingTimes.length
  }
}
