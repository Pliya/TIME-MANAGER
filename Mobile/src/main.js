import './polyfills'
import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { setup_accessibility } from '@/accessibility'
import { initDb } from './services/db'
import { startNetworkWatch, syncQueue, isOnline } from './services/offline'
import { prefetch } from './api'
import { load_shared_data } from '@/store'
import { homePath } from './navigation'
import { startTableLabels } from './services/tables'

function nativeFeatures() {
  // Bouton retour Android : page précédente, ou quitter depuis un onglet principal
  document.addEventListener('backbutton', () => {
    const path = router.currentRoute.value.path
    if (path === homePath() || path === '/sign_in') navigator.app?.exitApp()
    else router.back()
  }, false)

  // Les alert() des vues web deviennent des dialogues natifs
  if (navigator.notification?.alert) {
    window.alert = (message) => navigator.notification.alert(String(message), () => {}, 'Time Manager', 'OK')
  }
}

async function start() {
  await initDb()
  setup_accessibility()
  nativeFeatures()
  createApp(App).use(router).mount('#app')
  startTableLabels(document.getElementById('app'))
  startNetworkWatch()
  // À l'ouverture avec réseau : on envoie d'abord ce qui attend, puis on met
  // à jour les données locales depuis le serveur (le serveur fait foi).
  if (isOnline()) {
    await syncQueue()
    await prefetch()
  }
  // Données partagées (règles, planning, absences...) : serveur, ou cache si hors ligne
  load_shared_data()
}

// Dans Cordova on attend "deviceready" ; dans un navigateur (npm run dev) on démarre tout de suite
if (window.cordova) document.addEventListener('deviceready', start, false)
else start()