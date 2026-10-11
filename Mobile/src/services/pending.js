// Mises à jour "optimistes" : tant qu'une écriture attend dans la file,
// on l'applique par-dessus la réponse en cache des GET concernés.
// Le cache, lui, reste toujours la copie exacte du serveur (le serveur fait foi).

const parts = (url) => url.split('?')[0].split('/').filter(Boolean)
const same = (a, b) => String(a) === String(b)
const clone = (x) => (x === undefined ? x : JSON.parse(JSON.stringify(x)))
const byTime = (a, b) => (a.time < b.time ? -1 : a.time > b.time ? 1 : 0)

// URL de la liste qui contient l'objet créé par une requête POST
export function listUrlOf(item) {
  const [res, a] = parts(item.url)
  if (res === 'clocks' || res === 'workingtime') return `/${res}/${a}`
  if (res === 'users' || res === 'teams') return `/${res}`
  return null
}

function applyOne(getUrl, body, it, ctx) {
  const g = parts(getUrl)
  const [res, a, b, c] = parts(it.url)
  const m = it.method
  const list = Array.isArray(body?.data) ? body.data : null
  const one = body?.data && !Array.isArray(body.data) ? body.data : null

  if (res === 'clocks' && m === 'post') {
    // Le serveur alterne arrivée/sortie : le statut est l'inverse du dernier pointage
    if (list && g[0] === 'clocks' && same(g[1], a)) {
      const last = [...list].sort(byTime).pop()
      list.push({ id: it.tempId, time: it.data?.clock?.time || it.at, status: !last?.status, user_id: Number(a), pending: true })
    }
  }

  if (res === 'workingtime') {
    const wt = it.data?.working_time || {}
    if (m === 'post' && list && g[0] === 'workingtime' && g.length === 2 && same(g[1], a)) {
      list.push({ id: it.tempId, ...wt, user_id: Number(a), pending: true })
    }
    if (m === 'put' && g[0] === 'workingtime') {
      if (list) list.forEach((x, i) => { if (same(x.id, a)) list[i] = { ...x, ...wt, pending: true } })
      if (one && same(one.id, a)) body.data = { ...one, ...wt, pending: true }
    }
    if (m === 'delete' && list && g[0] === 'workingtime') {
      body.data = list.filter((x) => !same(x.id, a))
    }
  }

  if (res === 'users') {
    const u = it.data?.user || {}
    if (m === 'post' && !a && list && g[0] === 'users' && g.length === 1) {
      list.push({ id: it.tempId, username: u.username, email: u.email, role: 'Employee', pending: true })
    }
    if (m === 'put' && a) {
      const fields = b === 'role' ? { role: u.role } : { username: u.username, email: u.email }
      if (list && g[0] === 'users') list.forEach((x, i) => { if (same(x.id, a)) list[i] = { ...x, ...fields } })
      const isThisUser = g[0] === 'users' && (same(g[1], a) || (g[1] === 'me' && same(ctx.loggedUserId, a)))
      if (one && isThisUser) body.data = { ...one, ...fields }
    }
    if (m === 'delete' && a) {
      if (list && g[0] === 'users') body.data = list.filter((x) => !same(x.id, a))
      if (list && g[0] === 'teams') list.forEach((t) => { t.users = (t.users || []).filter((x) => !same(x.id, a)) })
    }
  }

  if (res === 'teams' && list && g[0] === 'teams' && g.length === 1) {
    if (m === 'post' && !a) {
      const t = it.data?.team || {}
      list.push({ id: it.tempId, name: t.name, manager_id: t.manager_id, users: [], pending: true })
    }
    if (m === 'delete' && a && !b) body.data = list.filter((t) => !same(t.id, a))
    if (b === 'users' && c) {
      const team = list.find((t) => same(t.id, a))
      if (team && m === 'delete') team.users = team.users.filter((x) => !same(x.id, c))
      if (team && m === 'post' && !team.users.some((x) => same(x.id, c))) {
        const user = ctx.findUser(c)
        team.users.push({ id: Number(c), username: user?.username || '…', email: user?.email || '' })
      }
    }
  }

  // Données partagées (règles, planning, absences...) : PUT /data/:clé
  if (res === 'data' && m === 'put' && a && g[0] === 'data' && g.length === 1 && one) {
    body.data = { ...one, [a]: it.data?.value }
  }

  return body
}

export function applyPending(getUrl, body, items, ctx) {
  let out = clone(body)
  for (const it of items) out = applyOne(getUrl, out, it, ctx)
  return out
}

// Réponse "fausse" renvoyée à la vue quand sa requête a été mise en file
export function entityFor(item, ctx) {
  const [res, a, b] = parts(item.url)
  const listUrl = listUrlOf(item)

  if (item.method === 'post' && listUrl && !b) {
    const listBody = ctx.view(listUrl) || { data: [] }
    const found = (listBody.data || []).find((x) => same(x.id, item.tempId))
    if (found) return found
  }
  if (item.method === 'put' && res === 'users') {
    const base = ctx.findUser(a) || { id: Number(a) }
    const u = item.data?.user || {}
    return b === 'role' ? { ...base, role: u.role } : { ...base, ...u }
  }
  if (item.method === 'put' && res === 'data') {
    return item.data?.value
  }
  if (item.method === 'put' && res === 'workingtime') {
    return { id: Number(a), ...(item.data?.working_time || {}), pending: true }
  }
  if (item.method === 'post') {
    const payload = Object.values(item.data || {})[0] || {}
    return { id: item.tempId, ...payload, pending: true }
  }
  return null
}