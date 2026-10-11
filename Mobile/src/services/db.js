import Loki from 'lokijs'

// Base NoSQL locale (LokiJS, sauvegardée dans le localStorage du téléphone).
//  - cache : dernière réponse du serveur pour chaque GET ({ url, body })
//    -> une seule copie par URL, pas de duplication.
//  - queue : requêtes d'écriture faites hors ligne, rejouées dans l'ordre (FIFO).
let db
export let cache
export let queue

// Avant initDb() (au chargement des modules), la base n'est pas encore prête
export function readCache(url) {
  return cache ? cache.by('url', url)?.body : undefined
}

export function writeCache(url, body) {
  if (!cache) return
  const doc = cache.by('url', url)
  if (doc) {
    doc.body = body
    doc.at = Date.now()
    cache.update(doc)
  } else {
    cache.insert({ url, body, at: Date.now() })
  }
}

// FIFO : ordre d'insertion ($loki croissant)
export const queuedItems = () => (queue ? queue.chain().simplesort('$loki').data() : [])

export function initDb() {
  return new Promise((resolve) => {
    db = new Loki('timemanager.db', {
      adapter: new Loki.LokiLocalStorageAdapter(),
      autoload: true,
      autosave: true,
      autosaveInterval: 1000,
      autoloadCallback: () => {
        cache = db.getCollection('cache') || db.addCollection('cache', { unique: ['url'] })
        queue = db.getCollection('queue') || db.addCollection('queue')
        // Anciennes collections de la première version mobile
        for (const name of ['clocks', 'workingtimes', 'users', 'teams']) {
          if (db.getCollection(name)) db.removeCollection(name)
        }
        resolve()
      },
    })
  })
}

export const flush = () => new Promise((resolve) => db.saveDatabase(() => resolve()))

export function clearLocalData() {
  cache.clear()
  queue.clear()
  return flush()
}