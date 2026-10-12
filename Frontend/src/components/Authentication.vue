<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Eye, EyeOff, CircleHelp, X, Check } from 'lucide-vue-next'
import AccessibilityPanel from './AccessibilityPanel.vue'
import LogoIcon from './LogoIcon.vue'
import gotham from '@/assets/gotham.png'
import seal from '@/assets/gotham-seal.png'
import { accessibility, speak } from '@/accessibility'
import { t } from '@/i18n'
import { api } from '@/api'
import { save_session } from '@/session'

const router = useRouter()

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)
const show_password = ref(false)
const forgotten = ref(false)

const STEPS = [
  { title: 'Se connecter', text: "Utilise l'email et le mot de passe donnés par ton administrateur. Il n'y a pas d'inscription : c'est lui qui crée ton compte." },
  { title: 'Pointer', text: "En arrivant, appuie sur « Pointer l'arrivée ». En partant, sur « Pointer la sortie ». Un seul bouton, rien à saisir." },
  { title: 'Sans réseau ou sans téléphone', text: "Le pointage est gardé sur l'appareil sans réseau. Sans téléphone, utilise la borne : « Journée conforme au planning » en un clic." },
  { title: 'Une erreur ?', text: "Dans « Mes temps », demande une correction. Ton manager répond sous 48 h, et un refus est toujours motivé." },
]
const step = ref(-1)

const POINTS = [
  'Un seul bouton, sur ton téléphone ou à la borne',
  'Fonctionne sans réseau, envoi au retour de la connexion',
  'Aucune comparaison entre collègues',
]

function show_step(index)
{
  step.value = index
  if (accessibility.voice && index >= 0) speak(`${STEPS[index].title}. ${STEPS[index].text}`)
}

async function sign_in()
{
  error.value = ''
  loading.value = true
  try {
    const { data } = await api.post('/users/sign_in', { user: { email: email.value, password: password.value } })
    save_session(data.data.user, data.data.xsrf_token)
    router.push('/')
  } catch (err) {
	const status = err.response?.status
    if (status === 401) error.value = t('Email ou mot de passe incorrect.')
    else if (status === 429) error.value = t('Trop de tentatives. Réessayez dans une minute.')
    else error.value = t("Impossible de contacter l'API.")
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex min-h-screen flex-wrap bg-[#F0F0F0] font-sans text-neutral-900">
    <section class="flex min-w-0 flex-[1_1_440px] flex-col bg-[#171b45] bg-cover bg-center text-white" :style="{ backgroundImage: `linear-gradient(to bottom, rgba(23, 27, 69, 0.35), rgba(23, 27, 69, 0.9)), url(${gotham})` }">
      <div class="flex h-24 shrink-0 items-center gap-4 bg-brand px-8">
        <img :src="seal" alt="Sceau de la ville de Gotham" class="h-16 w-16 rounded-full shadow-lg ring-2 ring-white/70" />
        <div class="flex flex-col leading-tight">
          <span class="text-2xl font-bold tracking-wide uppercase">Time Manager</span>
          <span class="text-sm text-white/80 uppercase">Ville de Gotham</span>
        </div>
      </div>

      <div class="flex flex-1 flex-col justify-center gap-6 px-8 py-10 xl:px-14">
        <h1 class="text-3xl leading-tight font-bold xl:text-5xl">{{ $t('Ton temps de travail, simplement.') }}</h1>
        <p class="max-w-md text-white/80">{{ $t('Pointer en un geste, suivre tes heures, demander une correction. Tes chiffres restent à toi.') }}</p>
        <ul class="space-y-3 text-sm">
          <li v-for="point in POINTS" :key="point" class="flex items-center gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-brand"><Check class="h-4 w-4" /></span>
            {{ $t(point) }}
          </li>
        </ul>
      </div>

      <p class="px-8 pb-6 text-xs text-white/60 uppercase xl:px-14">{{ $t('Mairie de Gotham · Ressources humaines') }}</p>
    </section>

    <section class="flex min-w-0 flex-[1.5_1_480px] items-center justify-center p-4 xl:p-10">
      <div class="w-full max-w-md overflow-hidden rounded-[20px] bg-white p-5">
        <p class="card-title font-medium">{{ $t('Connexion · Espace agent') }}</p>

      <p v-if="error" class="mb-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-600">{{ error }}</p>

      <form @submit.prevent="sign_in">
        <label class="block">
          <span class="text-sm font-medium">{{ $t('Email professionnel') }}</span>
          <input v-model.trim="email" type="email" required autocomplete="email" placeholder="prenom.nom@gotham.gov" class="mt-1 w-full rounded-[12px] border border-neutral-300 px-3 py-3 text-sm focus:border-brand focus:outline-none" />
        </label>

        <label class="mt-4 block">
          <span class="text-sm font-medium">{{ $t('Mot de passe') }}</span>
          <span class="relative mt-1 block">
            <input v-model="password" :type="show_password ? 'text' : 'password'" required autocomplete="current-password" placeholder="••••••••••" class="w-full rounded-[12px] border border-neutral-300 py-3 pr-12 pl-3 text-sm focus:border-brand focus:outline-none" />
            <button type="button" class="absolute top-2.5 right-3 text-neutral-400 hover:text-neutral-900" :aria-label="show_password ? $t('Masquer le mot de passe') : $t('Afficher le mot de passe')" @click="show_password = !show_password">
              <EyeOff v-if="show_password" class="h-5 w-5" />
              <Eye v-else class="h-5 w-5" />
            </button>
          </span>
        </label>

        <button type="button" class="mt-2 block w-full text-right text-sm font-medium text-brand underline" @click="forgotten = !forgotten">
          {{ $t('Mot de passe oublié ?') }}
        </button>
        <p v-if="forgotten" class="mt-2 rounded-xl bg-neutral-100 px-3 py-2 text-xs text-neutral-600">
          {{ $t('Contacte ton administrateur ou le service RH : ils réinitialisent ton mot de passe.') }}
        </p>

        <button type="submit" :disabled="loading" class="mt-4 w-full rounded-md bg-neutral-900 py-3 font-semibold text-white hover:bg-neutral-700 disabled:opacity-50">
          {{ loading ? $t('Connexion...') : $t('Se connecter') }}
        </button>
      </form>

      <AccessibilityPanel large class="mt-6" />

      <button class="mt-6 flex w-full items-center justify-center gap-2 text-sm text-neutral-500 hover:text-neutral-900" @click="show_step(0)">
        <CircleHelp class="h-4 w-4" /> {{ $t('Première connexion ? Suivre le tutoriel') }}
      </button>
      </div>
    </section>

    <div v-if="step >= 0" class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/40 p-4" @click.self="step = -1">
      <div class="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
        <div class="flex items-center justify-between">
          <p class="text-xs font-semibold tracking-wider text-neutral-400 uppercase">Étape {{ step + 1 }} / {{ STEPS.length }}</p>
          <button class="text-neutral-400 hover:text-neutral-900" :aria-label="$t('Fermer le tutoriel')" @click="step = -1"><X class="h-5 w-5" /></button>
        </div>
        <p class="mt-3 text-lg font-semibold">{{ $t(STEPS[step].title) }}</p>
        <p class="mt-2 text-sm text-neutral-600">{{ $t(STEPS[step].text) }}</p>

        <div class="mt-5 flex gap-1.5">
          <span v-for="(_, i) in STEPS" :key="i" class="h-1.5 flex-1 rounded-full" :class="i <= step ? 'bg-neutral-900' : 'bg-neutral-200'"></span>
        </div>

        <div class="mt-5 flex justify-between gap-2">
          <button class="rounded-full border-2 border-neutral-200 px-5 py-2 text-sm font-semibold disabled:opacity-40" :disabled="step === 0" @click="show_step(step - 1)">{{ $t('Précédent') }}</button>
          <button v-if="step < STEPS.length - 1" class="rounded-full bg-neutral-900 px-5 py-2 text-sm font-semibold text-white" @click="show_step(step + 1)">{{ $t('Suivant') }}</button>
          <button v-else class="rounded-full bg-neutral-900 px-5 py-2 text-sm font-semibold text-white" @click="step = -1">{{ $t("C'est parti") }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
