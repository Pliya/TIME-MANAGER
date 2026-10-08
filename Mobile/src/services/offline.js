import { ref } from 'vue'
import { http, isNetworkError } from './http'
import { queue, queuedItems, flush } from './db'
import { showSpinner, hideSpinner } from './spinner'

export const isOnline = () =>
  navigator.connection?.type ? navigator.connection.type !== 'none' : navigator.onLine

export const online = ref(true)
export const pendingCount = ref(0)
export const syncMessage = ref('')
// Incrémenté quand les données locales ont changé après une synchro :
// App.vue s'en sert pour recharger la vue affichée.
export const syncVersion = ref(0)

export const updatePending = () => (pendingCount.value = queue.count())

// Format des dates renvoyées par l'API : "YYYY-MM-DD hh:mm:ss" en UTC
export const toApiTime = (d) => d.toISOString().slice(0, 19).replace('T', ' ')

let seq = 0
const tempId = () => -(Date.now() * 10 + (seq++ % 10))

function notify(msg) {
  syncMessage.value = msg
  setTimeout(() => {
    if (syncMessage.value === msg) syncMessage.value = ''
  }, 5000)
}

// Ajoute une requête d'écriture à la file FIFO
export async function enqueue(method, url, data) {
  const now = new Date()
  const item = {
    method,
    url,
    data: data === undefined ? undefined : JSON.parse(JSON.stringify(data)),
    tempId: method === 'post' ? tempId() : null,
    at: toApiTime(now),
  }
  // Pointage : on envoie l'heure réelle du pointage (ISO 8601) pour que le
  // serveur l'enregistre à cette heure-là et non à l'heure de la synchro.
  if (method === 'post' && url.startsWith('/clocks/')) {
    item.data = { clock: { ...(data?.clock || {}), time: now.toISOString() } }
  }
  const saved = queue.insert(item)
  await flush()
  updatePending()
  if (isOnline()) setTimeout(() => syncQueue({ spinner: false }), 0)
  return saved
}

// Remplace un identifiant temporaire par l'identifiant donné par le serveur
const remapUrl = (url, from, to) =>
  url.split('/').map((p) => (p === String(from) ? String(to) : p)).join('/')

let syncing = false
let refreshAfterSync = () => Promise.resolve()
export const onSynced = (fn) => (refreshAfterSync = fn)

export async function syncQueue({ spinner = true } = {}) {
  if (syncing || !isOnline()) return 'skipped'
  const items = queuedItems()
  if (items.length === 0) {
    updatePending()
    return 'empty'
  }

  syncing = true
  if (spinner) showSpinner('Synchronisation...')
  let result = 'ok'
  let done = 0

  try {
    for (const it of queuedItems()) {
      const res = await http.request({ method: it.method, url: it.url, data: it.data })
      const realId = res.data?.data?.id
      if (it.tempId && realId) {
        // Les requêtes suivantes qui visaient l'objet temporaire visent maintenant le vrai
        for (const next of queuedItems()) {
          const url = remapUrl(next.url, it.tempId, realId)
          if (url !== next.url) queue.update(Object.assign(next, { url }))
        }
      }
      queue.remove(it)
      done++
      updatePending()
    }
  } catch (err) {
    const status = err.response?.status
    if (!isNetworkError(err) && status !== 401) {
      // Le serveur refuse une modification : on annule tout et on reprend ses données
      queue.clear()
      result = 'rejected'
    } else {
      // Réseau coupé ou session expirée : on garde la file pour plus tard
      result = 'failed'
    }
  } finally {
    syncing = false
    await flush()
    updatePending()
  }

  if (result !== 'failed') {
    try { await refreshAfterSync() } catch (e) { /* données locales conservées */ }
  }
  if (spinner) hideSpinner()

  if (result === 'rejected') {
    notify('Le serveur a refusé une modification : les changements locaux ont été annulés.')
    syncVersion.value++
  } else if (result === 'ok' && spinner) {
    notify(`${done} modification(s) synchronisée(s).`)
    syncVersion.value++
  }

  // Des requêtes ont pu être ajoutées pendant la synchro
  if (result === 'ok' && queue.count() > 0) return syncQueue({ spinner: false })
  return result
}

export function startNetworkWatch() {
  const update = () => {
    const was = online.value
    online.value = isOnline()
    if (online.value && !was) syncQueue()
  }
  online.value = isOnline()
  updatePending()
  document.addEventListener('online', update)
  document.addEventListener('offline', update)
  window.addEventListener('online', update)
  window.addEventListener('offline', update)
  // Retour de l'appli au premier plan
  document.addEventListener('resume', () => {
    update()
    if (online.value) syncQueue()
  })
}