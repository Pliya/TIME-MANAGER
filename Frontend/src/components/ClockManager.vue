<script setup>
    import { ref, computed, watch, onActivated, onMounted, onUnmounted } from 'vue';
    import { Coffee, Footprints, TriangleAlert, CalendarCheck, WifiOff } from 'lucide-vue-next';
    import { api } from '@/api';
    import Chip from './Chip.vue';
    import { isNight, dateKey, sortByTime } from '@/utils/kpi';
    import { store, newId } from '@/store';
    import { username } from '@/session';
    import { SHIFTS, shiftOf, shiftTimes } from '@/utils/planning';

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
    const notice = ref("");
    let timer = null;

    async function refresh() {
        error.value = "";
        try {
            const reponse = await api.get(`/clocks/${props.userId}`);
            const clocksArray = sortByTime(reponse.data.data, 'time');
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
            const reponse = await api.post(`/clocks/${props.userId}`, payload);
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

    const paused = computed(() => Boolean(store.pauses[props.userId]));

    async function pause() {
        if (!paused.value && !clockIn.value) {
            notice.value = "Pointe ton arrivée avant de prendre une pause.";
            return;
        }
        await clock();
        store.pauses[props.userId] = !paused.value;
        notice.value = paused.value ? 'Bonne pause ! Reviens ici pour reprendre.' : 'Pause terminée.';
    }

    const incidentOpen = ref(false);
    const incidentText = ref('');

    function addJustification(type, text) {
        store.justifications.unshift({
            id: newId(),
            userId: Number(props.userId),
            userName: username.value,
            type,
            text,
            date: dateKey(),
            time: new Date().toTimeString().slice(0, 5),
        });
    }

    function travel() {
        addJustification('Trajet', 'Trajet entre deux sites, compté comme temps de travail.');
        notice.value = 'Trajet déclaré à ton manager.';
    }

    function sendIncident() {
        if (!incidentText.value) return;
        addJustification('Incident', incidentText.value);
        incidentText.value = '';
        incidentOpen.value = false;
        notice.value = 'Incident envoyé à ton manager.';
    }

    const todayShift = computed(() => SHIFTS[shiftOf(props.userId, new Date())]);

    async function conformDay() {
        const shift = shiftOf(props.userId, new Date());
        if (!shift || shift === 'R') {
            notice.value = "Aucun créneau de travail n'est prévu aujourd'hui dans ton planning.";
            return;
        }
        try {
            await api.post(`/workingtime/${props.userId}`, { working_time: shiftTimes(shift, new Date()) });
            notice.value = 'Journée enregistrée selon le planning.';
        } catch {
            notice.value = "Impossible d'enregistrer la journée.";
        }
    }

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
        <div class="flex flex-col items-center rounded-2xl bg-white p-6 xl:p-8">
          <Chip v-if="paused" color="outline">En pause</Chip>
          <Chip v-else :color="clockIn ? 'dark' : 'gray'">{{ clockIn ? 'En cours' : 'Pas pointé' }}</Chip>
          <p class="mt-6 text-5xl font-bold tracking-tight tabular-nums xl:text-6xl">{{ elapsed }}</p>
          <p class="mt-2 text-sm text-neutral-400">{{ clockIn ? `Depuis ${startDateTime.slice(11, 16)}` : "Tu n'as pas encore pointé" }}</p>

          <button v-if="!loaded" disabled class="mt-6 w-full rounded-full bg-neutral-100 py-3 font-semibold text-neutral-400">
            Chargement...
          </button>
          <button
            v-else
            class="mt-6 w-full rounded-full border-2 border-neutral-900 py-3 text-base font-semibold"
            :class="clockIn ? 'bg-white hover:bg-neutral-50' : 'bg-neutral-900 text-white hover:bg-neutral-700'"
            @click="paused ? pause() : clock()"
          >
            {{ paused ? 'Reprendre le travail' : clockIn ? 'Pointer la sortie' : "Pointer l'arrivée" }}
          </button>

          <div class="mt-3 grid w-full grid-cols-3 gap-2 text-xs">
            <button class="flex flex-col items-center gap-1 rounded-xl py-2" :class="paused ? 'bg-neutral-900 text-white' : 'bg-neutral-100 hover:bg-neutral-200'" @click="pause">
              <Coffee class="h-4 w-4" /> {{ paused ? 'Reprendre' : 'Pause' }}
            </button>
            <button class="flex flex-col items-center gap-1 rounded-xl bg-neutral-100 py-2 hover:bg-neutral-200" @click="travel">
              <Footprints class="h-4 w-4" /> Trajet
            </button>
            <button class="flex flex-col items-center gap-1 rounded-xl bg-neutral-100 py-2 hover:bg-neutral-200" @click="incidentOpen = !incidentOpen">
              <TriangleAlert class="h-4 w-4" /> Incident
            </button>
          </div>

          <form v-if="incidentOpen" class="mt-3 w-full" @submit.prevent="sendIncident">
            <textarea v-model.trim="incidentText" rows="2" required placeholder="Ex. : route bloquée après une intervention de Batman" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm"></textarea>
            <button type="submit" class="mt-2 w-full rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white">Envoyer au manager</button>
          </form>

          <button
            class="mt-3 flex w-full items-center justify-center gap-1 rounded-lg bg-neutral-100 px-3 py-2.5 text-xs font-medium hover:bg-neutral-200"
            @click="conformDay"
          >
            <CalendarCheck class="h-4 w-4" />
            Journée conforme au planning
            <template v-if="todayShift && todayShift.start">({{ todayShift.start }} – {{ todayShift.end }})</template>
          </button>
          <p v-if="notice" class="mt-3 text-center text-xs text-neutral-500">{{ notice }}</p>
        </div>

        <div v-if="loaded" class="rounded-2xl bg-white p-5">
          <div class="card-title flex items-center justify-between">
            <p class="font-medium">Objectif du jour</p>
            <span class="text-sm text-neutral-400">{{ goalPercent }}%</span>
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

      <div class="space-y-6 xl:col-span-2">
        <div class="rounded-2xl bg-white p-5">
          <p class="card-title mb-4 font-medium">Dernières sessions</p>
          <div class="overflow-x-auto">
            <table class="w-full min-w-max text-sm">
              <thead>
                <tr class="bg-neutral-50 text-left text-neutral-500">
                  <th class="rounded-l-lg px-3 py-3 font-medium">Date</th>
                  <th class="px-3 py-3 font-medium">Arrivée</th>
                  <th class="px-3 py-3 font-medium">Sortie</th>
                  <th class="rounded-r-lg px-3 py-3 font-medium">Durée</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="session in lastSessions" :key="session.id" class="border-b border-neutral-100 last:border-0">
                  <td class="px-3 py-3 font-medium">{{ session.start.slice(0, 10) }}</td>
                  <td class="px-3 py-3">{{ session.start.slice(11, 16) }}</td>
                  <td class="px-3 py-3">
                    {{ session.end.slice(11, 16) }}
                    <Chip v-if="isNight(session.start)" color="dark">Nuit</Chip>
                  </td>
                  <td class="px-3 py-3">{{ formatDuration(toDate(session.end) - toDate(session.start)) }}</td>
                </tr>
                <tr v-if="lastSessions.length === 0">
                  <td colspan="4" class="px-4 py-8 text-center text-neutral-400">Aucune session enregistrée.</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="flex items-center gap-3 rounded-2xl bg-white p-5 text-sm text-neutral-500">
          <WifiOff class="h-4 w-4 shrink-0" />
          Pas de réseau ? Le pointage est gardé sur l'appareil et envoyé au retour de la connexion.
        </div>
      </div>
    </div>
  </div>
</template>
