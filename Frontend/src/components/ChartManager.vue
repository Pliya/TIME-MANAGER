<script setup>
    import ClockChart from './ClockChart.vue'

    const props = defineProps({
        userId: {
            required: true
        }
    })
</script>

<template>
    <div class="dashboard-container">
        <h1>Stats</h1>
        
        <div class="charts-wrapper">
            <ClockChart :userId="props.userId" />
        </div>
    </div>
</template>

<style scoped>
    .dashboard-container {
        padding: 20px;
        background-color: var(--background-color);
    }

    .charts-wrapper {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
    }
</style>