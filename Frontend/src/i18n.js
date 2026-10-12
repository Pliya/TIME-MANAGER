import { ref, computed } from 'vue'

// Langue courante, gardée d'une visite à l'autre
const saved = (() => { try { return localStorage.getItem('locale') } catch { return null } })()
export const locale = ref(saved === 'en' ? 'en' : 'fr')

export function setLocale(value)
{
  locale.value = value === 'en' ? 'en' : 'fr'
  try { localStorage.setItem('locale', locale.value) } catch { /* vide */ }
}

export function toggleLocale()
{
  setLocale(locale.value === 'fr' ? 'en' : 'fr')
}

// Dictionnaire français -> anglais. Une entrée manquante retombe sur le français.
const en = {}

export function addMessages(map)
{
  Object.assign(en, map)
}

// t('Texte français') ou t('{n} en attente', { n: 5 })
export function t(fr, params)
{
  let text = locale.value === 'en' ? (en[fr] ?? fr) : fr
  if (params) {
    for (const key in params) text = text.replaceAll(`{${key}}`, params[key])
  }
  return text
}

// Pour pluvoir écrire $t dans les templates sans importer à chaque fois
export const i18n = {
  install(app)
  {
    app.config.globalProperties.$t = t
    app.provide('t', t)
  },
}

export const isEnglish = computed(() => locale.value === 'en')
