// API utilisée par les vues web partagées (elles importent "@/api").
// Même interface que Frontend/src/api.js (api.get/post/put/delete),
// mais avec le mode hors ligne du mobile :
//  - GET  : on demande d'abord au serveur (priorité au serveur) et on met la
//           réponse en cache LokiJS ; sans réseau, on renvoie le cache.
//  - écritures : envoyées directement si possible, sinon mises dans la file
//           FIFO et rejouées au retour du réseau.
import { http, isNetworkError } from './services/http'
import { readCache, writeCache, queuedItems } from './services/db'
import { applyPending, entityFor } from './services/pending'
import { isOnline, enqueue, onSynced } from './services/offline'
import { logged_user_id, role } from '@/session'

// Ces requêtes n'ont de sens qu'en ligne : jamais mises en file
const ONLINE_ONLY = ['/users/sign_in', '/users/sign_out']

function context() {
  const view = (url) => {
    const body = readCache(url)
    return body === undefined ? undefined : applyPending(url, body, queuedItems(), context())
  }
  return {
    loggedUserId: logged_user_id.value,
    view,
    findUser(id) {
      const users = readCache('/users')?.data || []
      const pendingUsers = queuedItems()
        .filter((it) => it.method === 'post' && it.url === '/users')
        .map((it) => ({ id: it.tempId, ...(it.data?.user || {}) }))
      const me = readCache('/users/me')?.data
      return [...users, ...pendingUsers, me].find((u) => u && String(u.id) === String(id))
    },
  }
}

const withPending = (url, body) => {
  const items = queuedItems()
  return items.length ? applyPending(url, body, items, context()) : body
}

async function get(url, config) {
  if (isOnline()) {
    try {
      const res = await http.get(url, config)
      writeCache(url, res.data)
      return { ...res, data: withPending(url, res.data) }
    } catch (err) {
      if (!isNetworkError(err)) throw err
    }
  }
  const body = readCache(url)
  if (body === undefined) {
    throw new Error('Hors ligne : cette page n’a pas encore été chargée sur ce téléphone.')
  }
  return { data: withPending(url, body), status: 200, offline: true, config: { url } }
}

async function write(method, url, data, config = {}) {
  if (ONLINE_ONLY.some((p) => url.startsWith(p))) {
    return http.request({ ...config, method, url, data })
  }
  // En ligne et rien en attente : requête directe (l'ordre FIFO est respecté)
  if (isOnline() && queuedItems().length === 0) {
    try {
      return await http.request({ ...config, method, url, data })
    } catch (err) {
      if (!isNetworkError(err)) throw err
    }
  }
  const item = await enqueue(method, url, data)
  return { data: { data: entityFor(item, context()) }, status: 202, queued: true, config: { url } }
}

export const api = {
  get,
  post: (url, data, config) => write('post', url, data, config),
  put: (url, data, config) => write('put', url, data, config),
  patch: (url, data, config) => write('patch', url, data, config),
  delete: (url, config) => write('delete', url, undefined, config),
  defaults: http.defaults,
  interceptors: http.interceptors,
}

// Au démarrage et après chaque synchro : on recharge depuis le serveur les
// données dont l'utilisateur aura besoin hors ligne, selon son rôle.

export async function prefetch() {
  const id = logged_user_id.value
  if (!id || !isOnline()) return
  const urls = ['/users/me', '/data', `/clocks/${id}`, `/workingtime/${id}`]
  if (role.value === 'Manager' || role.value === 'Administrator') urls.push('/users', '/teams')
  await Promise.allSettled(urls.map((u) => get(u)))
  // Pointages et temps de chaque membre des équipes (pages Équipe, Alertes, Validation...)
  if (role.value === 'Manager' || role.value === 'Administrator') {
    // import dynamique : évite la boucle api.js -> team.js -> store.js -> api.js
    const { load_team_members } = await import('./team')
    await load_team_members().catch(() => {})
  }
}
onSynced(prefetch)

export default api