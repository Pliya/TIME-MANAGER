export const VIOLET = '#7c3aed'
export const VIOLET_LIGHT = '#c4b5fd'
export const PALETTE = ['#7c3aed', '#a78bfa', '#c4b5fd', '#6366f1', '#38bdf8', '#f472b6', '#fbbf24']

export function chartOptions({ legend = false, suffix = '' } = {}) {
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: legend, position: 'top', align: 'end', labels: { usePointStyle: true, boxWidth: 6 } },
    },
    scales: {
      x: { grid: { display: false }, border: { display: false }, ticks: { color: '#9ca3af' } },
      y: {
        beginAtZero: true,
        grid: { color: '#f3f4f6' },
        border: { display: false },
        ticks: { color: '#9ca3af', precision: 0, callback: value => `${value}${suffix}` },
      },
    },
  }
}

export const pieOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { position: 'right', labels: { usePointStyle: true, boxWidth: 8 } } },
}
