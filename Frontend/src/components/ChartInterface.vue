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
        ArcElement
    } from 'chart.js'
    import { Chart } from 'vue-chartjs'

    ChartJS.register(Title, Tooltip, Legend, LineElement, PointElement, CategoryScale, LinearScale, BarElement, ArcElement)

    const props = defineProps({
        type: {
            type: String,
            required: true
        },
        chartData: {
            type: Object,
            required: true
        },
        chartOptions: {
            type: Object,
            default: () => ({
                responsive: true,
                maintainAspectRatio: false
            })
        }
    })

</script>

<template>
    <div>
        <div class="chart">
            <Chart 
                :type="props.type"
                :data="props.chartData"
                :options="props.chartOptions"
            />
        </div>
    </div>

</template>

<style scoped>
    .chart {
        height: 400px;
    }
</style>