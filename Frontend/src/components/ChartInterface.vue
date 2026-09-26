<script setup>
import {
    Chart as ChartJS,
    Title,
    Tooltip,
    Legend,
    LineElement,
    PointElement,
    CategoryScale,
    LinearScale,
    BarElement,
    ArcElement,
    LineController,
    BarController
} from 'chart.js'
import { Chart } from 'vue-chartjs'

ChartJS.register(
    Title, Tooltip, Legend,
    LineElement, PointElement, CategoryScale, LinearScale,
    BarElement, ArcElement, LineController, BarController
)

const props = defineProps({
    type: { type: String, required: true },
    chartData: { type: Object, required: true },
    chartOptions: {
        type: Object,
        default: () => ({ responsive: true, maintainAspectRatio: false })
    }
})
</script>

<template>
    <div class="chart-wrapper">
        <Chart 
            :type="props.type"
            :data="props.chartData"
            :options="props.chartOptions"
        />
    </div>
</template>

<style scoped>
.chart-wrapper {
    position: relative;
    width: 100%;
    height: 100%;
}
</style>