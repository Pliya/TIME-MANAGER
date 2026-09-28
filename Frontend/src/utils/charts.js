export const DARK = '#171717'

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
