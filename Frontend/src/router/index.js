import { createRouter, createWebHistory } from 'vue-router'
import WorkingTimes from '../components/WorkingTimes.vue'
import WorkingTime from '../components/WorkingTime.vue'
import ClockManager from '../components/ClockManager.vue'

const routes = [
  { path: '/', name: 'home' },
  { path: '/clock', name: 'clock', component: ClockManager },
  { path: '/clock/:userId', name: 'clock-user', component: ClockManager },

  { path: '/workingTimes/:userID', name: 'working-times-user', component: WorkingTimes, props: true },
  { path: '/workingtimes/:userID', redirect: to => `/workingTimes/${to.params.userID}` },
  { path: '/working-times', name: 'working-times', component: WorkingTimes },

  { path: '/workingTime/:userid', name: 'working-time-create', component: WorkingTime, props: true },
  { path: '/workingtime/:userid', redirect: to => `/workingTime/${to.params.userid}` },

  { path: '/workingTime/:userid/:workingtimeid', name: 'working-time-edit', component: WorkingTime, props: true },
  { path: '/workingtime/:userid/:workingtimeid', redirect: to => `/workingTime/${to.params.userid}/${to.params.workingtimeid}` },

  { path: '/profile', name: 'profile' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router