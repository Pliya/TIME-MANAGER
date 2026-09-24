<script setup >
    import {ref} from 'vue';
    import axios from 'axios';
    import { useRoute } from 'vue-router';


    const startDateTime = ref(null);
    const clockIn = ref(false);
    const error = ref("");
    const route = useRoute();
    const userId = route.params.userId;
    const data = ref("");

    async function refresh() {
        error.value = "";
        try {
            const reponse = await axios.get(`http://localhost:4000/api/clocks/${userId}`);
            const clocksArray = reponse.data.data;
            if (clocksArray && clocksArray.length > 0) {
                const lastClock = clocksArray[clocksArray.length - 1];
                if (lastClock.status) {
                    startDateTime.value = lastClock.time;
                    console.log("lastClock.time", startDateTime.value);
                    clockIn.value = true;
                } else {
                    startDateTime.value = null;
                    console.log("lastClock.time", startDateTime.value);
                    clockIn.value = false;
                }
            } else {
                startDateTime.value = null;
                clockIn.value = false;
            }
        } catch (err) {
            error.value = "Erreur lors de la récupération des clocks : " + err.message;
        }
           
    }

    async function clock() {
        error.value = "";
        try {
            const reponse = await axios.post(`http://localhost:4000/api/clocks/${userId}`);
            const newClock = reponse.data.data;
            
            if (newClock.status) {
                startDateTime.value = newClock.time;
                clockIn.value = true;
            } else {
                startDateTime.value = null;
                clockIn.value = false;
            }
        } catch (err) {
            error.value = "Erreur lors du clocking : " + err.message;
        }

    }

</script>


<template>
    <div class="container">
        <h1>Clock Manager</h1>
        <p v-if="error" class="error">{{ error }}</p>
        <p v-if="clockIn">Clocked in at: {{ startDateTime }}</p>
        <p v-else>Not clocked in</p>
        <div class="buttons">
            <button @click="clock">{{ clockIn ? 'Clock Out' : 'Clock In' }}</button>
            <button class="refresh" @click="refresh">Refresh</button>
        </div>
    </div>
</template>


<style scoped>
* {
    font-family: sans-serif;
    box-sizing: border-box;
}

.container {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: 32px;
    max-width: 400px;
    margin: 60px auto;
    background: #fff;
    border-radius: 12px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.08);
}

h1 {
    font-size: 1.4rem;
    margin-bottom: 12px;
    color: #1f2937;
}

p {
    margin: 4px 0 16px;
    color: #6b7280;
    font-size: 0.95rem;
}

.error {
    color: #dc2626;
}

.buttons {
    display: flex;
    gap: 10px;
    margin-top: 4px;
}

button {
    padding: 10px 20px;
    border: none;
    border-radius: 8px;
    background-color: #4f46e5;
    color: white;
    font-size: 0.9rem;
    cursor: pointer;
    transition: background 0.2s;
}

button:hover {
    background-color: #4338ca;
}

.refresh {
    background-color: #6b7280;
}

.refresh:hover {
    background-color: #4b5563;
}
</style>