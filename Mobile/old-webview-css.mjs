// Rend le CSS de Tailwind v4 lisible par la WebView d'Android 9 (API 28, ~Chrome 66-69).
// Tailwind v4 génère du CSS moderne (Chrome 111+) : sans cette conversion, la vieille
// WebView ignore les blocs @layer, donc TOUT le style de l'appli.
import postcss from 'postcss'
import { transform } from 'lightningcss'

const TARGETS = { chrome: 66 << 16, android: 66 << 16 }

// Découpe "a, b(c, d)" en ["a", "b(c, d)"] (virgules de premier niveau seulement)
function splitTopLevel(text) {
  const parts = []
  let depth = 0
  let start = 0
  for (let i = 0; i < text.length; i++) {
    if (text[i] === '(') depth++
    else if (text[i] === ')') depth--
    else if (text[i] === ',' && depth === 0) {
      parts.push(text.slice(start, i).trim())
      start = i + 1
    }
  }
  parts.push(text.slice(start).trim())
  return parts
}

// ":where(a, b) c" -> ["a c", "b c"]   (:where n'existe qu'à partir de Chrome 88)
function expandWhere(selector) {
  const i = selector.indexOf(':where(')
  if (i === -1) return [selector]
  let depth = 0
  let end = i + 6
  for (; end < selector.length; end++) {
    if (selector[end] === '(') depth++
    else if (selector[end] === ')' && --depth === 0) break
  }
  const inner = selector.slice(i + 7, end)
  return splitTopLevel(inner).flatMap((part) =>
    expandWhere(selector.slice(0, i) + part + selector.slice(end + 1)),
  )
}

const LOGICAL = {
  'padding-inline': ['padding-left', 'padding-right'],
  'padding-block': ['padding-top', 'padding-bottom'],
  'margin-inline': ['margin-left', 'margin-right'],
  'margin-block': ['margin-top', 'margin-bottom'],
  'inset-inline': ['left', 'right'],
  'inset-block': ['top', 'bottom'],
}

// "gap" dans un conteneur flex n'existe qu'à partir de Chrome 84.
// Si le navigateur ne le gère pas, src/polyfills.js ajoute la classe "no-flex-gap"
// sur <html> et ces règles remplacent le gap par des marges entre les enfants.
function addFlexGapFallback(rule) {
  const match = /^\.(gap(?:-[xy])?-[\w.\\[\]-]+)$/.exec(rule.selector)
  if (!match || rule.parent.type !== 'root') return
  const cls = '.' + match[1]
  const value = (prop) => rule.nodes.find((d) => d.type === 'decl' && d.prop === prop)?.value
  const both = value('gap')
  const col = value('column-gap') || both
  const row = value('row-gap') || both
  const extra = []
  if (col) extra.push(postcss.rule({ selectors: [`.no-flex-gap .flex${cls}:not(.flex-col)>*+*`, `.no-flex-gap .inline-flex${cls}:not(.flex-col)>*+*`] }).append({ prop: 'margin-left', value: col }))
  if (row) extra.push(postcss.rule({ selector: `.no-flex-gap .flex-col${cls}>*+*` }).append({ prop: 'margin-top', value: row }))
  rule.after(extra)
}

const compat = {
  postcssPlugin: 'old-webview',
  AtRule: {
    // @layer (Chrome 99+) : on garde le contenu, dans le même ordre
    layer(at) {
      if (at.nodes) at.replaceWith(at.nodes)
      else at.remove()
    },
    // Valeurs par défaut des variables --tw-* : appliquées sans condition
    supports(at) {
      if (at.params.includes('margin-trim')) at.replaceWith(at.nodes)
    },
  },
  Rule(rule) {
    if (rule.selector.includes(':where(')) {
      rule.selectors = rule.selectors.flatMap(expandWhere)
    }
    addFlexGapFallback(rule)
  },
  Declaration(decl) {
    // 100dvh (Chrome 108+) : 100vh juste avant, comme valeur de secours
    if (decl.value.includes('dvh') && !decl.prev()?.value?.includes('vh')) {
      decl.cloneBefore({ value: decl.value.replace(/dvh/g, 'vh') })
    }
    // padding-inline, margin-block... (Chrome 87+) -> left/right, top/bottom
    const logical = LOGICAL[decl.prop]
    if (logical) {
      const [start, end = start] = postcss.list.space(decl.value)
      decl.cloneBefore({ prop: logical[0], value: start })
      decl.cloneBefore({ prop: logical[1], value: end })
      decl.remove()
      return
    }
    // filter: var(--tw-blur,) var(--tw-invert,)... n'est pas compris :
    // on écrit directement le filtre de la classe (ex. .invert -> invert(100%))
    if ((decl.prop === 'filter' || decl.prop === 'backdrop-filter') && decl.value.includes('var(--tw-')) {
      const own = decl.parent.nodes.filter((d) => d.type === 'decl' && /^--tw-(backdrop-)?(blur|brightness|contrast|grayscale|hue-rotate|invert|saturate|sepia|drop-shadow)$/.test(d.prop))
      if (own.length) decl.value = own.map((d) => d.value).join(' ')
    }
    // Dégradés : "to bottom in oklab" n'est pas compris, "to bottom" oui
    if (decl.prop === '--tw-gradient-position') {
      decl.value = decl.value.replace(/\s+in\s+oklab/, '')
    }
  },
}

export function toOldWebview(css) {
  const flat = postcss([compat]).process(css, { from: undefined }).css
  // Couleurs oklch, imbrication, media queries modernes, :is()... convertis pour Chrome 66
  const { code } = transform({
    filename: 'app.css',
    code: Buffer.from(flat),
    minify: true,
    targets: TARGETS,
  })
  return code
    .toString()
    // invert() sans argument n'est pas compris partout : invert(1)
    .replace(/\b(invert|grayscale|sepia|brightness|contrast|saturate)\(\)/g, '$1(1)')
}

// Plugin Vite : convertit les fichiers CSS générés par "npm run build"
export function oldWebviewCss() {
  return {
    name: 'old-webview-css',
    apply: 'build',
    enforce: 'post',
    generateBundle(_, bundle) {
      for (const file of Object.values(bundle)) {
        if (file.type === 'asset' && file.fileName.endsWith('.css')) {
          file.source = toOldWebview(String(file.source))
        }
      }
    },
  }
}