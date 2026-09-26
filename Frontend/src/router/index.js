import { createRouter, createWebHistory } from 'vue-router'
import HomeComponent from '../components/HomeComponent.vue'
import ClockManager from '../components/ClockManager.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import UserComponent from '../components/UserComponent.vue'

const routes = [
  { path: '/', name: 'home', component: HomeComponent },
  { path: '/clock', name: 'clock', component: ClockManager },
  { path: '/working-times', name: 'working-times', component: WorkingTimes },
  { path: '/profile', name: 'profile', component: UserComponent },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
