import { existsSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { oldWebviewCss } from './old-webview-css.mjs'

// Les vues sont partagées avec le frontend web : on les importe depuis
// ../Frontend/src sans jamais modifier ce dossier.
const webSrc = fileURLToPath(new URL('../Frontend/src', import.meta.url))
const mobileSrc = fileURLToPath(new URL('./src', import.meta.url))

const EXTENSIONS = ['', '.js', '.vue', '/index.js']
const findFile = (base) =>
  EXTENSIONS.map((ext) => base + ext).find((p) => existsSync(p) && statSync(p).isFile())

// "@/..." (utilisé partout dans les vues web) cherche d'abord dans Mobile/src,
// puis dans Frontend/src. Le mobile remplace donc seulement ce qu'il doit
// remplacer (src/api.js = API hors ligne, src/team.js) et réutilise tout le reste.
function mobileOverridesWeb() {
  return {
    name: 'mobile-overrides-web',
    enforce: 'pre',
    resolveId(source) {
      if (!source.startsWith('@/')) return null
      const rel = source.slice(2)
      return findFile(join(mobileSrc, rel)) || findFile(join(webSrc, rel)) || null
    },
  }
}

export default defineConfig({
  plugins: [mobileOverridesWeb(), vue(), tailwindcss(), oldWebviewCss()],
  base: './',
  resolve: {
    alias: [{ find: '@web', replacement: webSrc }],
    // Frontend/ n'a pas ses propres node_modules : les vues web utilisent
    // les dépendances installées dans Mobile/.
    dedupe: ['vue', 'vue-router', 'lucide-vue-next', 'axios', 'chart.js', 'vue-chartjs'],
  },
  server: {
    fs: { allow: ['..'] },
  },
  build: {
    target: 'es2015',
    cssTarget: 'chrome111',
    outDir: 'www',
    emptyOutDir: true,
  },
})