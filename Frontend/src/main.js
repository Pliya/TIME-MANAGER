import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { setup_accessibility } from './accessibility'
import { i18n } from './i18n'
import './translations'

setup_accessibility()
createApp(App).use(router).use(i18n).mount('#app')
