// La WebView d'Android 9 est un vieux Chrome : on ajoute ce qui peut lui manquer.
if (typeof globalThis === 'undefined') window.globalThis = window
if (!Array.prototype.flat) {
  Array.prototype.flat = function (depth = 1) {
    return this.reduce((acc, x) => acc.concat(Array.isArray(x) && depth > 0 ? x.flat(depth - 1) : x), [])
  }
}
if (!Array.prototype.flatMap) {
  Array.prototype.flatMap = function (fn, thisArg) {
    return this.map(fn, thisArg).flat(1)
  }
}
if (!Promise.allSettled) {
  Promise.allSettled = (promises) =>
    Promise.all(Array.from(promises, (p) =>
      Promise.resolve(p).then(
        (value) => ({ status: 'fulfilled', value }),
        (reason) => ({ status: 'rejected', reason }),
      ),
    ))
}
// "gap" dans un conteneur flex (Chrome 84+) : si absent, on le signale au CSS
// (voir old-webview-css.mjs : les marges remplacent alors le gap)
;(function detectFlexGap() {
  const box = document.createElement('div')
  box.style.cssText = 'display:flex;flex-direction:column;row-gap:1px;position:absolute;visibility:hidden'
  box.appendChild(document.createElement('div'))
  box.appendChild(document.createElement('div'))
  document.documentElement.appendChild(box)
  const supported = box.scrollHeight === 1
  box.remove()
  if (!supported) document.documentElement.classList.add('no-flex-gap')
})()