  import { createRouter, createWebHashHistory } from 'vue-router'
  import { logged_user_id, role, is_manager } from '@/session'
  import { homePath } from '../navigation'
  import { load_shared_data } from '@/store'

// Les vues sont celles du web (Frontend/src/components), importées telles quelles.
// Mêmes chemins, titres et rôles que Frontend/src/router/index.js,
// sauf les dashboards (/, /chartManager, /statistiques-equipe).

const EMPLOYEE = ['Employee']
const MANAGER = ['Manager', 'Administrator']
const ADMIN = ['Administrator']
const EMPLOYEE_AND_MANAGER = ['Employee', 'Manager', 'Administrator']

const routes = [
  { path: '/sign_in', component: () => import('@web/components/Authentication.vue'), meta: { title: 'Connexion', public: true } },
  { path: '/', redirect: () => homePath() },

  { path: '/clock/:userid', component: () => import('@web/components/ClockManager.vue'), meta: { title: 'Pointage', roles: EMPLOYEE } },
  { path: '/workingTimes/:userID', component: () => import('@web/components/WorkingTimes.vue'), meta: { title: 'Mes temps', roles: EMPLOYEE_AND_MANAGER } },
  { path: '/planning', component: () => import('@web/components/PlanningPage.vue'), meta: { title: 'Planning', roles: EMPLOYEE } },
  { path: '/absences', component: () => import('@web/components/AbsencesPage.vue'), meta: { title: 'Absences', roles: EMPLOYEE } },

  { path: '/workingTime/:userid', component: () => import('@web/components/WorkingTime.vue'), meta: { title: 'Nouveau temps de travail', roles: MANAGER } },
  { path: '/workingTime/:userid/:workingtimeid', component: () => import('@web/components/WorkingTime.vue'), meta: { title: 'Modifier un temps de travail', roles: MANAGER } },
  { path: '/equipe', component: () => import('@web/components/Manager_TeamPage.vue'), meta: { title: 'Équipe', roles: MANAGER } },
  { path: '/alertes', component: () => import('@web/components/Manager_AlertsPage.vue'), meta: { title: 'Alertes', roles: MANAGER } },
  { path: '/validation', component: () => import('@web/components/Manager_ValidationPage.vue'), meta: { title: 'Validation', roles: MANAGER } },
  { path: '/planning-equipe', component: () => import('@web/components/Manager_TeamPlanningPage.vue'), meta: { title: 'Planning', roles: MANAGER } },

  { path: '/utilisateurs', component: () => import('@web/components/UsersPage.vue'), meta: { title: 'Utilisateurs', roles: ADMIN } },
  { path: '/regles', component: () => import('@web/components/RulesPage.vue'), meta: { title: 'Règles', roles: ADMIN } },
  { path: '/paie', component: () => import('@web/components/PayrollPage.vue'), meta: { title: 'Paie', roles: ADMIN } },
  { path: '/absences-rh', component: () => import('@web/components/AdminAbsencesPage.vue'), meta: { title: 'Absences', roles: ADMIN } },

  { path: '/chartManager/:userid', component: () => import('@web/components/ChartManager.vue'), meta: { title: 'Statistiques', roles: EMPLOYEE_AND_MANAGER } },
  { path: '/statistiques-equipe', component: () => import('@web/components/Manager_TeamStatsPage.vue'), meta: { title: 'Statistiques', roles: MANAGER } },
  // Seule page propre au mobile : le reste du menu + déconnexion (onglet "Plus")
  { path: '/plus', component: () => import('../views/More.vue'), meta: { title: 'Plus' } },

  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  // Hash : l'appli Cordova est servie depuis un seul fichier index.html
  history: createWebHashHistory(),
  routes,
})

// Même garde que le web
router.beforeEach((to) => {
  if (to.meta.public) return logged_user_id.value ? homePath() : true

  if (!logged_user_id.value) return '/sign_in'

  if (to.meta.roles && !to.meta.roles.includes(role.value)) return homePath()

  const idInUrl = Number(to.params.userid || to.params.userID)
  if (idInUrl && idInUrl !== logged_user_id.value && !is_manager()) return homePath()
})

// Comme le web : on recharge les données partagées à chaque changement de page
router.afterEach(() => load_shared_data())

export default router