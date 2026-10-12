import { ref, computed } from 'vue'

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

const en = {}

export function addMessages(map)
{
  Object.assign(en, map)
}

export function t(fr, params)
{
  let text = locale.value === 'en' ? (en[fr] ?? fr) : fr
  if (params) {
    for (const key in params) text = text.replaceAll(`{${key}}`, params[key])
  }
  return text
}

export const i18n = {
  install(app)
  {
    app.config.globalProperties.$t = t
    app.provide('t', t)
  },
}

export const isEnglish = computed(() => locale.value === 'en')

export function dateLocale()
{
  return locale.value === 'en' ? 'en-US' : 'fr-FR'
}
