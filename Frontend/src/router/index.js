import { createRouter, createWebHistory } from 'vue-router'
import HomeComponent from '../components/HomeComponent.vue'
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import WorkingTime from '../components/WorkingTime.vue'
import LoginPage from '../components/LoginPage.vue'
import { loggedUserId } from '../session'

const routes = [
  { path: '/login', component: LoginPage, meta: { title: 'Connexion', public: true } },
  { path: '/', component: HomeComponent, meta: { title: 'Dashboard' } },
  { path: '/clock/:userid', component: ClockManager, meta: { title: 'Pointage' } },
  { path: '/workingTimes/:userID', component: WorkingTimes, meta: { title: 'Temps de travail' } },
  { path: '/workingTime/:userid', component: WorkingTime, meta: { title: 'Nouveau temps de travail' } },
  { path: '/workingTime/:userid/:workingtimeid', component: WorkingTime, meta: { title: 'Modifier un temps de travail' } },
  { path: '/chartManager/:userid', component: ChartManager, meta: { title: 'Statistiques' } },
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
