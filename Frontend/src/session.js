import { ref } from 'vue'

export const logged_user_id = ref(Number(localStorage.getItem('userId')) || null)
export const role = ref(localStorage.getItem('role'))
export const xsrf_token = ref(localStorage.getItem('xsrfToken'))
export const username = ref(localStorage.getItem('username'))

export function save_session(user, token)
{
  logged_user_id.value = user.id
  role.value = user.role
  xsrf_token.value = token
  username.value = user.username
  localStorage.setItem('userId', user.id)
  localStorage.setItem('username', user.username)
  localStorage.setItem('role', user.role)
  localStorage.setItem('xsrfToken', token)
}

export function clear_session()
{
  logged_user_id.value = null
  role.value = null
  xsrf_token.value = null
  username.value = null
  localStorage.removeItem('userId')
  localStorage.removeItem('username')
  localStorage.removeItem('role')
  localStorage.removeItem('xsrfToken')
}

export function has_role(...roles)
{
  return role.value === 'Administrator' || roles.includes(role.value)
}

export function is_manager()
{
  return has_role('Manager')
}

export function is_admin()
{
  return role.value === 'Administrator'
}

const HOME = { Employee: '/', Manager: '/equipe', Administrator: '/utilisateurs' }

export function home_path()
{
  return HOME[role.value] || '/'
}
