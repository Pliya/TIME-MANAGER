import { createRouter, createWebHistory } from 'vue-router'
import HomeComponent from '../components/HomeComponent.vue'
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import WorkingTime from '../components/WorkingTime.vue'
import UserComponent from '../components/UserComponent.vue'

const routes = [
  { path: '/', name: 'dashboard', component: HomeComponent },
  { path: '/clock', name: 'clock', component: ClockManager },
  { path: '/clock/:user_id', name: 'clock-user', component: ClockManager },
  { path: '/charts', name: 'charts', component: ChartManager },
  { path: '/chartManager', name: 'chart-manager', component: ChartManager },
  { path: '/chartManager/:user_id', name: 'chart-manager-user', component: ChartManager },
  { path: '/workingTimes', name: 'working-times-list', component: WorkingTimes },
  { path: '/workingTimes/:user_id', name: 'working-times-user', component: WorkingTimes },
  { path: '/workingTime', name: 'working-time-new', component: WorkingTime },
  { path: '/workingTime/:user_id', name: 'working-time-create', component: WorkingTime },
  { path: '/workingTime/:user_id/:working_time_id', name: 'working-time-edit', component: WorkingTime },
  { path: '/profile', name: 'profile', component: UserComponent },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
