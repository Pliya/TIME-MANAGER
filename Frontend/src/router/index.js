import { createRouter, createWebHistory } from 'vue-router'
import HomeComponent from '../components/HomeComponent.vue'
import ClockManager from '../components/ClockManager.vue'
import ChartManager from '../components/ChartManager.vue'
import WorkingTimes from '../components/WorkingTimes.vue'
import ProfilePage from '../components/ProfilePage.vue'
import WorkingTime from '../components/WorkingTime.vue'
import Authentication from '../components/Authentication.vue'
import PlanningPage from '../components/PlanningPage.vue'
import AbsencesPage from '../components/AbsencesPage.vue'
import TeamPage from '../components/Manager_TeamPage.vue'
import AlertsPage from '../components/Manager_AlertsPage.vue'
import ValidationPage from '../components/Manager_ValidationPage.vue'
import TeamPlanningPage from '../components/Manager_TeamPlanningPage.vue'
import TeamStatsPage from '../components/Manager_TeamStatsPage.vue'
import UsersPage from '../components/UsersPage.vue'
import RulesPage from '../components/RulesPage.vue'
import PayrollPage from '../components/PayrollPage.vue'
import AdminAbsencesPage from '../components/AdminAbsencesPage.vue'
import { logged_user_id, role, is_manager, home_path } from '../session'
import { load_shared_data } from '../store'

const EMPLOYEE = ['Employee']
const MANAGER = ['Manager', 'Administrator']
const ADMIN = ['Administrator']
const EMPLOYEE_AND_MANAGER = ['Employee', 'Manager', 'Administrator']

const routes = [
  { path: '/sign_in', component: Authentication, meta: { title: 'Connexion', public: true } },
  { path: '/', component: HomeComponent, meta: { title: 'Dashboard', roles: EMPLOYEE_AND_MANAGER } },

  { path: '/clock/:userid', component: ClockManager, meta: { title: 'Pointage', roles: EMPLOYEE_AND_MANAGER } },
  { path: '/workingTimes/:userID', component: WorkingTimes, meta: { title: 'Mes temps', roles: EMPLOYEE_AND_MANAGER } },
  { path: '/chartManager/:userid', component: ChartManager, meta: { title: 'Statistiques', roles: EMPLOYEE_AND_MANAGER } },
  { path: '/planning', component: PlanningPage, meta: { title: 'Planning', roles: EMPLOYEE } },
  { path: '/absences', component: AbsencesPage, meta: { title: 'Absences', roles: EMPLOYEE } },

  { path: '/workingTime/:userid', component: WorkingTime, meta: { title: 'Nouveau temps de travail', roles: MANAGER } },
  { path: '/workingTime/:userid/:workingtimeid', component: WorkingTime, meta: { title: 'Modifier un temps de travail', roles: MANAGER } },
  { path: '/equipe', component: TeamPage, meta: { title: 'Équipe', roles: MANAGER } },
  { path: '/alertes', component: AlertsPage, meta: { title: 'Alertes', roles: MANAGER } },
  { path: '/validation', component: ValidationPage, meta: { title: 'Validation', roles: MANAGER } },
  { path: '/planning-equipe', component: TeamPlanningPage, meta: { title: 'Planning', roles: MANAGER } },
  { path: '/statistiques-equipe', component: TeamStatsPage, meta: { title: 'Statistiques', roles: MANAGER } },

  { path: '/utilisateurs', component: UsersPage, meta: { title: 'Utilisateurs', roles: ADMIN } },
  { path: '/regles', component: RulesPage, meta: { title: 'Règles', roles: ADMIN } },
  { path: '/paie', component: PayrollPage, meta: { title: 'Paie', roles: ADMIN } },
  { path: '/absences-rh', component: AdminAbsencesPage, meta: { title: 'Absences', roles: ADMIN } },

  { path: '/profil', component: ProfilePage, meta: { title: 'Mon profil' } },

  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(to =>
{
  if (to.meta.public)
    return logged_user_id.value ? home_path() : true

  if (!logged_user_id.value)
    return '/sign_in'

  if (to.meta.roles && !to.meta.roles.includes(role.value))
    return home_path()

  const id_in_url = Number(to.params.userid || to.params.userID)
  if (id_in_url && id_in_url !== logged_user_id.value && !is_manager())
    return home_path()
})

router.afterEach(() => load_shared_data())

export default router
