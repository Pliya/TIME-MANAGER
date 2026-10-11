import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { setup_accessibility } from './accessibility'

setup_accessibility()
createApp(App).use(router).mount('#app')
