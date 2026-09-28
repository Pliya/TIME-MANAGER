import { formatDecimalTime } from './date'

export const DARK = '#171717'
export const LIGHT = '#a3a3a3'
export const PALETTE = ['#171717', '#404040', '#525252', '#737373', '#a3a3a3', '#d4d4d4', '#e5e5e5']

export function chartOptions({ legend = false, suffix = '', max, stepSize, formatValue } = {}) {
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: legend, position: 'top', align: 'end', labels: { usePointStyle: true, boxWidth: 6 } },
      tooltip: formatValue
        ? { callbacks: { label: context => `${context.dataset.label} : ${formatValue(context.parsed.y)}` } }
        : {},
    },
    scales: {
      x: { grid: { display: false }, border: { display: false }, ticks: { color: '#a3a3a3' } },
      y: {
        min: 0,
        max,
        grid: { color: '#f5f5f5' },
        border: { display: false },
        ticks: { color: '#a3a3a3', precision: 0, stepSize, callback: value => `${value}${suffix}` },
      },
    },
  }
}

export const hoursOfDayOptions = chartOptions({ legend: true, suffix: 'h', max: 24, stepSize: 4, formatValue: formatDecimalTime })

export const pieOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { position: 'right', labels: { usePointStyle: true, boxWidth: 8 } } },
}
