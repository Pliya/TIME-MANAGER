import { computed } from 'vue'
import { logged_user_id, role } from '@/session'

// Mêmes sections, libellés et icônes que la sidebar du web (Frontend/src/App.vue),
// sans les dashboards (Dashboard, Statistiques) exclus par le sujet mobile.
const SECTIONS = (id) => [
  {
    title: 'Employé',
    roles: ['Employee'],
    links: [
      { to: `/clock/${id}`, label: 'Pointage', logo: 'timetable' },
      { to: `/workingTimes/${id}`, label: 'Mes temps', logo: 'list' },
      { to: '/planning', label: 'Planning', logo: 'schedule' },
      { to: '/absences', label: 'Absences', logo: 'list-interface-symbol' },
            { to: `/chartManager/${id}`, label: 'Statistiques', logo: 'bar-chart' },
    ],
  },
  {
    title: 'Administrateur / RH',
    roles: ['Administrator'],
    links: [
      { to: '/utilisateurs', label: 'Utilisateurs', logo: 'data' },
      { to: '/regles', label: 'Règles', logo: 'work-plan' },
      { to: '/paie', label: 'Paie', logo: 'trend' },
      { to: '/absences-rh', label: 'Absences', logo: 'list-interface-symbol' },
    ],
  },
  {
    title: 'Manager',
    roles: ['Manager', 'Administrator'],
    links: [
      { to: `/clock/${id}`, label: 'Pointage', logo: 'timetable' },
      { to: '/equipe', label: 'Équipe', logo: 'monitor' },
      { to: '/alertes', label: 'Alertes', logo: 'increase' },
      { to: '/validation', label: 'Validation', logo: 'planning' },
      { to: '/planning-equipe', label: 'Planning', logo: 'schedule' },
      { to: '/statistiques-equipe', label: 'Statistiques', logo: 'chart' },
    ],
  },
]

export const sections = computed(() =>
  SECTIONS(logged_user_id.value).filter((s) => s.roles.includes(role.value)),
)

// Tab bar : les pages du rôle + l'onglet "Plus" (5 onglets maximum)
export const tabs = computed(() => [
  ...sections.value.flatMap((s) => s.links).slice(0, 4),
  { to: '/plus', label: 'Plus', logo: 'work-plan', more: true },
])

// Même règle que le web : on compare le premier segment de l'URL
export const isActive = (currentPath, to) => currentPath.split('/')[1] === to.split('/')[1]

export function homePath() {
  if (!logged_user_id.value) return '/sign_in'
  if (role.value === 'Manager') return '/equipe'
  if (role.value === 'Administrator') return '/utilisateurs'
  return `/clock/${logged_user_id.value}`
}