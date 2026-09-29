import { createRouter, createWebHistory } from 'vue-router'
import HomeComponent from '../components/HomeComponent.vue'
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import WorkingTime from '../components/WorkingTime.vue'
import UserComponent from '../components/UserComponent.vue'
import LoginPage from '../components/LoginPage.vue'
import { loggedUserId } from '../session'

const routes = [
  { path: '/login', component: LoginPage, meta: { title: 'Connexion', public: true } },
  { path: '/', component: HomeComponent, meta: { title: 'Dashboard' } },
  { path: '/clock/:userID?', component: ClockManager, meta: { title: 'Pointage' } },
  { path: '/charts', component: ChartManager, meta: { title: 'Statistiques' } },
  { path: '/chartManager/:userID?', component: ChartManager, meta: { title: 'Statistiques' } },
  { path: '/workingTimes/:userID?', component: WorkingTimes, meta: { title: 'Temps de travail' } },
  { path: '/workingTime/:userID?/:workingTimeId?', component: WorkingTime, meta: { title: 'Temps de travail' } },
  { path: '/profile', component: UserComponent, meta: { title: 'Profil' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(to => {
  if (!to.meta.public && !loggedUserId.value) return '/login'
  if (to.path === '/login' && loggedUserId.value) return '/'
})

export default router
