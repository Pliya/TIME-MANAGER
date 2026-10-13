<script setup>
import { Chart as ChartJS, registerables } from 'chart.js'
import { Chart } from 'vue-chartjs'

ChartJS.register(...registerables)

defineProps({
  type: { type: String, required: true },
  chartData: { type: Object, required: true },
  chartOptions: { type: Object, default: () => ({ responsive: true, maintainAspectRatio: false }) },
})
</script>

<template>
  <div class="relative h-full w-full">
    <Chart :type="type" :data="chartData" :options="chartOptions" />
  </div>
</template>
