<script setup>
    import axios from 'axios'
    import { ref, onMounted, watch } from 'vue'
    import ChartInterface from './ChartInterface.vue'

    const props = defineProps({
        userId: {
            required: true
        }
    })

    const clocks = ref([])

    const chartData = ref({ labels: [], datasets: [] })
    const chartOptions = {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
            y: { min: 0, max: 24, title: { display: true, text: 'Heure' } }
        }
    }

    async function getClocks() {
        try {
            const response = await axios.get(`http://localhost:4000/api/clocks/${props.userId}`)
            clocks.value = response.data.data
            createChart()
        } catch (error) {
            console.error("Erreur API :", error)
        }
    }

    function createChart() {
        const days = {}

        clocks.value.forEach(clock => {
            const date = new Date(clock.time.replace(' ', 'T'))
            const dateKey = clock.time.substring(0, 10)
            const day = date.toLocaleDateString('fr-FR', { weekday: 'short' })

            if (!days[dateKey]) {
                days[dateKey] = { label: day, clockIn: null, clockOut: null }
            }
            
            const hour = date.getHours() + date.getMinutes() / 60
            if (clock.status)
                days[dateKey].clockIn = hour
            else
                days[dateKey].clockOut = hour
        })

        const daysArray = Object.values(days)

        chartData.value = {
            labels: daysArray.map(d => d.label),
            datasets: [
                {
                    label: 'Clock In',
                    data: daysArray.map(d => d.clockIn),
                    borderColor: '#4f46e5',
                    backgroundColor: '#4f46e5',
                },
                {
                    label: 'Clock Out',
                    data: daysArray.map(d => d.clockOut),
                    borderColor: '#dc2626',
                    backgroundColor: '#dc2626',
                }
            ]
        }
    }

    onMounted(() => {
        getClocks()
    })
</script>

<template>
    <div>
        <ChartInterface type="line" :chart-data="chartData" :chart-options="chartOptions" />
    </div>
</template>
