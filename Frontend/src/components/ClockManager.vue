<script setup>
    import { ref, computed, watch, onActivated, onMounted, onUnmounted } from 'vue';
    import { Coffee, Footprints, TriangleAlert, CalendarCheck, WifiOff } from 'lucide-vue-next';
    import { api } from '@/api';
    import Chip from './Chip.vue';
    import { is_night, date_key, sort_by_time } from '@/utils/kpi';
    import { store, new_id } from '@/store';
    import { username } from '@/session';
    import { SHIFTS, shift_of, shift_times } from '@/utils/planning';

    const props = defineProps({
        userId: {
            required: true
        }
    });

    const DAILY_GOAL_HOURS = 7;

    const start_date_time = ref(null);
    const clock_in = ref(false);
    const error = ref("");
    const clocks = ref([]);
    const loaded = ref(false);
    const now = ref(new Date());
    const notice = ref("");
    let timer = null;

    async function refresh()
    {
        error.value = "";
        try {
            const reponse = await api.get(`/clocks/${props.userId}`);
            const clocks_array = sort_by_time(reponse.data.data, 'time');
            clocks.value = clocks_array;
            if (clocks_array && clocks_array.length > 0) {
                const last_clock = clocks_array[clocks_array.length - 1];
                if (last_clock.status) {
                    start_date_time.value = last_clock.time;
                    clock_in.value = true;
                } else {
                    start_date_time.value = null;
                    clock_in.value = false;
                }
            } else {
                start_date_time.value = null;
                clock_in.value = false;
            }
        } catch (err) {
            error.value = "Erreur lors de la récupération des clocks : " + err.message;
        }
        loaded.value = true;
    }

    async function clock()
    {
        error.value = "";
        try {
            const date = new Date();
            const pad = (n) => n.toString().padStart(2, '0');
            const formatted_time = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;

            const payload = {
                clock: {
                    status: !clock_in.value,
                    time: formatted_time
                }
            };
            const reponse = await api.post(`/clocks/${props.userId}`, payload);
            const new_clock = reponse.data.data;
            clocks.value.push(new_clock);

            if (new_clock.status) {
                start_date_time.value = new_clock.time;
                clock_in.value = true;
            } else {
                start_date_time.value = null;
                clock_in.value = false;
                store.pauses[props.userId] = null;
            }
        } catch (err) {
            error.value = "Erreur lors du clocking : " + err.message;
        }
    }

    function to_date(time)
    {
        return new Date(time.replace(' ', 'T'));
    }

    function format_duration(ms)
    {
        const minutes = Math.floor(ms / 60000);
        return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, '0')}m`;
    }

    // Pause de la session en cours : { session, since (début de la pause en cours ou null), total (ms déjà en pause) }
    const pause_state = computed(() =>
    {
        const p = store.pauses[props.userId];
        return p && typeof p === 'object' && p.session === start_date_time.value ? p : null;
    });

    const paused = computed(() => Boolean(pause_state.value?.since));

    const paused_ms = computed(() =>
    {
        const p = pause_state.value;
        if (!p) return 0;
        return p.total + (p.since ? now.value - p.since : 0);
    });

    const elapsed = computed(() =>
    {
        if (!start_date_time.value) return '00:00:00';
        const seconds = Math.max(0, Math.floor((now.value - to_date(start_date_time.value) - paused_ms.value) / 1000));
        const pad = (n) => n.toString().padStart(2, '0');
        return `${pad(Math.floor(seconds / 3600))}:${pad(Math.floor((seconds % 3600) / 60))}:${pad(seconds % 60)}`;
    });

    const sessions = computed(() =>
    {
        const result = [];
        let clock_in_time = null;
        clocks.value.forEach(c =>
        {
            if (c.status) {
                clock_in_time = c.time;
            } else if (clock_in_time) {
                result.push({ id: c.id, start: clock_in_time, end: c.time });
                clock_in_time = null;
            }
        });
        return result;
    });

    const last_sessions = computed(() => sessions.value.slice(-8).reverse());

    const today_ms = computed(() =>
    {
        const today = to_date(`${now.value.getFullYear()}-${String(now.value.getMonth() + 1).padStart(2, '0')}-${String(now.value.getDate()).padStart(2, '0')} 00:00:00`);
        let total = 0;
        sessions.value.forEach(s =>
        {
            if (to_date(s.start) >= today) total += to_date(s.end) - to_date(s.start);
        });
        if (start_date_time.value) total += now.value - to_date(start_date_time.value) - paused_ms.value;
        return total;
    });

    const goal_percent = computed(() => Math.min(100, Math.round(today_ms.value / (DAILY_GOAL_HOURS * 3600000) * 100)));

    const goal_message = computed(() =>
    {
        const remaining = DAILY_GOAL_HOURS * 3600000 - today_ms.value;
        if (remaining <= 0) return 'Objectif atteint, bravo !';
        if (clock_in.value) {
            const leave_at = new Date(now.value.getTime() + remaining);
            return `Tu peux partir à ${String(leave_at.getHours()).padStart(2, '0')}:${String(leave_at.getMinutes()).padStart(2, '0')}`;
        }
        return `Encore ${format_duration(remaining)} à faire aujourd'hui`;
    });

    // La pause ne pointe pas : la session reste ouverte et le minuteur se fige jusqu'à la reprise
    function pause()
    {
        if (!clock_in.value) {
            notice.value = "Pointe ton arrivée avant de prendre une pause.";
            return;
        }
        const p = pause_state.value || { session: start_date_time.value, since: null, total: 0 };
        if (p.since) {
            store.pauses[props.userId] = { ...p, since: null, total: p.total + (Date.now() - p.since) };
            notice.value = 'Pause terminée, le minuteur reprend.';
        } else {
            store.pauses[props.userId] = { ...p, since: Date.now() };
            notice.value = 'Bonne pause ! Reviens ici pour reprendre.';
        }
    }

    const incident_open = ref(false);
    const incident_text = ref('');

    function add_justification(type, text)
    {
        store.justifications.unshift({
            id: new_id(),
            userId: Number(props.userId),
            userName: username.value,
            type,
            text,
            date: date_key(),
            time: new Date().toTimeString().slice(0, 5),
        });
    }

    function travel()
    {
        add_justification('Trajet', 'Trajet entre deux sites, compté comme temps de travail.');
        notice.value = 'Trajet déclaré à ton manager.';
    }

    function send_incident()
    {
        if (!incident_text.value) return;
        add_justification('Incident', incident_text.value);
        incident_text.value = '';
        incident_open.value = false;
        notice.value = 'Incident envoyé à ton manager.';
    }

    const today_shift = computed(() => SHIFTS[shift_of(props.userId, new Date())]);

    async function conform_day()
    {
        const shift = shift_of(props.userId, new Date());
        if (!shift || shift === 'R') {
            notice.value = "Aucun créneau de travail n'est prévu aujourd'hui dans ton planning.";
            return;
        }
        try {
            await api.post(`/workingtime/${props.userId}`, { working_time: shift_times(shift, new Date()) });
            notice.value = 'Journée enregistrée selon le planning.';
        } catch {
            notice.value = "Impossible d'enregistrer la journée.";
        }
    }

    onMounted(() =>
    {
        timer = setInterval(() =>
        {
          now.value = new Date();
        }, 1000);
    });

    onUnmounted(() =>
    {
        clearInterval(timer);
    });

    onActivated(() =>
    {
        refresh();
    });

    watch(() => props.userId, () =>
    {
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
          <Chip v-else :color="clock_in ? 'dark' : 'gray'">{{ clock_in ? 'En cours' : 'Pas pointé' }}</Chip>
          <p class="mt-6 text-5xl font-bold tracking-tight tabular-nums xl:text-6xl">{{ elapsed }}</p>
          <p class="mt-2 text-sm text-neutral-400">{{ clock_in ? `Depuis ${start_date_time.slice(11, 16)}` : "Tu n'as pas encore pointé" }}</p>

          <button v-if="!loaded" disabled class="mt-6 w-full rounded-full bg-neutral-100 py-3 font-semibold text-neutral-400">
            Chargement...
          </button>
          <button
            v-else
            class="mt-6 w-full rounded-full border-2 border-neutral-900 py-3 text-base font-semibold"
            :class="clock_in ? 'bg-white hover:bg-neutral-50' : 'bg-neutral-900 text-white hover:bg-neutral-700'"
            @click="paused ? pause() : clock()"
          >
            {{ paused ? 'Reprendre le travail' : clock_in ? 'Pointer la sortie' : "Pointer l'arrivée" }}
          </button>

          <div class="mt-3 grid w-full grid-cols-3 gap-2 text-xs">
            <button class="flex flex-col items-center gap-1 rounded-xl py-2" :class="paused ? 'bg-neutral-900 text-white' : 'bg-neutral-100 hover:bg-neutral-200'" @click="pause">
              <Coffee class="h-4 w-4" /> {{ paused ? 'Reprendre' : 'Pause' }}
            </button>
            <button class="flex flex-col items-center gap-1 rounded-xl bg-neutral-100 py-2 hover:bg-neutral-200" @click="travel">
              <Footprints class="h-4 w-4" /> Trajet
            </button>
            <button class="flex flex-col items-center gap-1 rounded-xl bg-neutral-100 py-2 hover:bg-neutral-200" @click="incident_open = !incident_open">
              <TriangleAlert class="h-4 w-4" /> Incident
            </button>
          </div>

          <form v-if="incident_open" class="mt-3 w-full" @submit.prevent="send_incident">
            <textarea v-model.trim="incident_text" rows="2" required placeholder="Ex. : route bloquée après une intervention de Batman" class="w-full rounded-xl border border-neutral-200 px-3 py-2 text-sm"></textarea>
            <button type="submit" class="mt-2 w-full rounded-full bg-neutral-900 py-2 text-sm font-semibold text-white">Envoyer au manager</button>
          </form>

          <button
            class="mt-3 flex w-full items-center justify-center gap-1 rounded-lg bg-neutral-100 px-3 py-2.5 text-xs font-medium hover:bg-neutral-200"
            @click="conform_day"
          >
            <CalendarCheck class="h-4 w-4" />
            Journée conforme au planning
            <template v-if="today_shift && today_shift.start">({{ today_shift.start }} – {{ today_shift.end }})</template>
          </button>
          <p v-if="notice" class="mt-3 text-center text-xs text-neutral-500">{{ notice }}</p>
        </div>

        <div v-if="loaded" class="rounded-2xl bg-white p-5">
          <div class="card-title flex items-center justify-between">
            <p class="font-medium">Objectif du jour</p>
            <span class="text-sm text-neutral-400">{{ goal_percent }}%</span>
          </div>
          <p class="mt-4 text-3xl font-semibold">
            {{ format_duration(today_ms) }}
            <span class="text-base font-normal text-neutral-400">/ {{ DAILY_GOAL_HOURS }}h</span>
          </p>
          <div class="mt-4 h-2 rounded-full bg-neutral-100">
            <div class="h-2 rounded-full bg-neutral-900" :style="{ width: `${goal_percent}%` }"></div>
          </div>
          <p class="mt-3 text-sm text-neutral-500">{{ goal_message }}</p>
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
                <tr v-for="session in last_sessions" :key="session.id" class="border-b border-neutral-100 last:border-0">
                  <td class="px-3 py-3 font-medium">{{ session.start.slice(0, 10) }}</td>
                  <td class="px-3 py-3">{{ session.start.slice(11, 16) }}</td>
                  <td class="px-3 py-3">
                    {{ session.end.slice(11, 16) }}
                    <Chip v-if="is_night(session.start)" color="dark">Nuit</Chip>
                  </td>
                  <td class="px-3 py-3">{{ format_duration(to_date(session.end) - to_date(session.start)) }}</td>
                </tr>
                <tr v-if="last_sessions.length === 0">
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
