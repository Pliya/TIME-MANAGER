<script setup>
    import { ref, computed, watch, onActivated, onMounted, onUnmounted } from 'vue';
    import axios from 'axios';
    import { API_URL } from '@/api';

    const props = defineProps({
        userId: {
            required: true
        }
    });

    const DAILY_GOAL_HOURS = 7;

    const startDateTime = ref(null);
    const clockIn = ref(false);
    const error = ref("");
    const clocks = ref([]);
    const loaded = ref(false);
    const now = ref(new Date());
    let timer = null;

    async function refresh() {
        error.value = "";
        try {
            const reponse = await axios.get(`${API_URL}/clocks/${props.userId}`);
            const clocksArray = reponse.data.data;
            clocks.value = clocksArray;
            if (clocksArray && clocksArray.length > 0) {
                const lastClock = clocksArray[clocksArray.length - 1];
                if (lastClock.status) {
                    startDateTime.value = lastClock.time;
                    clockIn.value = true;
                } else {
                    startDateTime.value = null;
                    clockIn.value = false;
                }
            } else {
                startDateTime.value = null;
                clockIn.value = false;
            }
        } catch (err) {
            error.value = "Erreur lors de la récupération des clocks : " + err.message;
        }
        loaded.value = true;
    }

    async function clock() {
        error.value = "";
        try {
            const date = new Date();
            const pad = (n) => n.toString().padStart(2, '0');
            const formattedTime = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;

            const payload = {
                clock: {
                    status: !clockIn.value,
                    time: formattedTime
                }
            };
            const reponse = await axios.post(`${API_URL}/clocks/${props.userId}`, payload);
            const newClock = reponse.data.data;
            clocks.value.push(newClock);

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

    function toDate(time) {
        return new Date(time.replace(' ', 'T'));
    }

    function formatDuration(ms) {
        const minutes = Math.floor(ms / 60000);
        return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, '0')}m`;
    }

    const elapsed = computed(() => {
        if (!startDateTime.value) return '00:00:00';
        const seconds = Math.max(0, Math.floor((now.value - toDate(startDateTime.value)) / 1000));
        const pad = (n) => n.toString().padStart(2, '0');
        return `${pad(Math.floor(seconds / 3600))}:${pad(Math.floor((seconds % 3600) / 60))}:${pad(seconds % 60)}`;
    });

    const sessions = computed(() => {
        const result = [];
        let clockInTime = null;
        clocks.value.forEach(c => {
            if (c.status) {
                clockInTime = c.time;
            } else if (clockInTime) {
                result.push({ id: c.id, start: clockInTime, end: c.time });
                clockInTime = null;
            }
        });
        return result;
    });

    const lastSessions = computed(() => sessions.value.slice(-8).reverse());

    const todayMs = computed(() => {
        const today = toDate(`${now.value.getFullYear()}-${String(now.value.getMonth() + 1).padStart(2, '0')}-${String(now.value.getDate()).padStart(2, '0')} 00:00:00`);
        let total = 0;
        sessions.value.forEach(s => {
            if (toDate(s.start) >= today) total += toDate(s.end) - toDate(s.start);
        });
        if (startDateTime.value) total += now.value - toDate(startDateTime.value);
        return total;
    });

    const goalPercent = computed(() => Math.min(100, Math.round(todayMs.value / (DAILY_GOAL_HOURS * 3600000) * 100)));

    const goalMessage = computed(() => {
        const remaining = DAILY_GOAL_HOURS * 3600000 - todayMs.value;
        if (remaining <= 0) return 'Objectif atteint, bravo !';
        if (clockIn.value) {
            const leaveAt = new Date(now.value.getTime() + remaining);
            return `Tu peux partir à ${String(leaveAt.getHours()).padStart(2, '0')}:${String(leaveAt.getMinutes()).padStart(2, '0')}`;
        }
        return `Encore ${formatDuration(remaining)} à faire aujourd'hui`;
    });

    onMounted(() => {
        timer = setInterval(() => { now.value = new Date(); }, 1000);
    });

    onUnmounted(() => {
        clearInterval(timer);
    });

    onActivated(() => {
        refresh();
    });

    watch(() => props.userId, () => {
        refresh();
    });
</script>

<template>
  <div class="space-y-6">
    <p v-if="error" class="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <div class="space-y-6">
        <div class="flex flex-col items-center rounded-2xl bg-white p-6 sm:p-8">
          <span
            class="rounded-full px-3 py-1 text-sm font-medium"
            :class="clockIn ? 'bg-neutral-900 text-white' : 'bg-neutral-100 text-neutral-500'"
          >
            {{ clockIn ? 'En cours' : 'Arrêté' }}
          </span>
          <p class="mt-6 text-5xl font-bold tracking-tight tabular-nums sm:mt-8 sm:text-7xl">{{ elapsed }}</p>
          <p class="mt-2 text-sm text-neutral-400">
            {{ clockIn ? `Clocked in at: ${startDateTime}` : 'Not clocked in' }}
          </p>
          <button
            v-if="!loaded"
            disabled
            class="mt-8 w-full rounded-full bg-neutral-100 py-3 font-semibold text-neutral-400"
          >
            Chargement...
          </button>
          <button
            v-else
            class="mt-8 w-full rounded-full py-3 font-semibold"
            :class="clockIn ? 'border-2 border-neutral-900 bg-white text-neutral-900 hover:bg-neutral-100' : 'bg-neutral-900 text-white hover:bg-neutral-700'"
            @click="clock"
          >
            {{ clockIn ? 'Clock Out' : 'Clock In' }}
          </button>
          <button class="mt-3 text-sm text-neutral-500 hover:text-neutral-900" @click="refresh">Refresh</button>
        </div>

        <div v-if="loaded" class="rounded-2xl bg-white p-6">
          <div class="flex items-center justify-between">
            <p class="font-medium">Objectif du jour</p>
            <span class="text-sm font-medium text-neutral-400">{{ goalPercent }}%</span>
          </div>
          <p class="mt-4 text-3xl font-semibold">
            {{ formatDuration(todayMs) }}
            <span class="text-base font-normal text-neutral-400">/ {{ DAILY_GOAL_HOURS }}h</span>
          </p>
          <div class="mt-4 h-2 rounded-full bg-neutral-100">
            <div class="h-2 rounded-full bg-neutral-900" :style="{ width: `${goalPercent}%` }"></div>
          </div>
          <p class="mt-3 text-sm text-neutral-500">{{ goalMessage }}</p>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6 xl:col-span-2">
        <p class="mb-4 font-medium">Dernières sessions</p>
        <div class="overflow-x-auto">
          <table class="w-full min-w-max text-sm">
            <thead>
              <tr class="bg-neutral-50 text-left text-neutral-500">
                <th class="rounded-l-lg px-3 py-3 font-medium sm:px-4">Date</th>
                <th class="px-3 py-3 font-medium sm:px-4">Clock In</th>
                <th class="px-3 py-3 font-medium sm:px-4">Clock Out</th>
                <th class="rounded-r-lg px-3 py-3 font-medium sm:px-4">Durée</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="session in lastSessions" :key="session.id" class="border-b border-neutral-100 last:border-0">
                <td class="px-3 py-3 font-medium sm:px-4">{{ session.start.slice(0, 10) }}</td>
                <td class="px-3 py-3 sm:px-4">{{ session.start.slice(11, 16) }}</td>
                <td class="px-3 py-3 sm:px-4">{{ session.end.slice(11, 16) }}</td>
                <td class="px-3 py-3 sm:px-4">{{ formatDuration(toDate(session.end) - toDate(session.start)) }}</td>
              </tr>
              <tr v-if="lastSessions.length === 0">
                <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune session enregistrée.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
