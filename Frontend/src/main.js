import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { setupAccessibility } from './accessibility'

setupAccessibility()
createApp(App).use(router).mount('#app')
