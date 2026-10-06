import { ref } from 'vue'

export const loggedUserId = ref(Number(localStorage.getItem('userId')) || null)
export const role = ref(localStorage.getItem('role'))
export const xsrfToken = ref(localStorage.getItem('xsrfToken'))
export const username = ref(localStorage.getItem('username'))

export function saveSession(user, token)
{
  loggedUserId.value = user.id
  role.value = user.role
  xsrfToken.value = token
  username.value = user.username
  localStorage.setItem('userId', user.id)
  localStorage.setItem('username', user.username)
  localStorage.setItem('role', user.role)
  localStorage.setItem('xsrfToken', token)
}

export function clearSession()
{
  loggedUserId.value = null
  role.value = null
  xsrfToken.value = null
  username.value = null
  localStorage.removeItem('userId')
  localStorage.removeItem('username')
  localStorage.removeItem('role')
  localStorage.removeItem('xsrfToken')
}

export function hasRole(...roles)
{
  return role.value === 'Administrator' || roles.includes(role.value)
}

export function isManager()
{
  return hasRole('Manager')
}

export function isAdmin()
{
  return role.value === 'Administrator'
}
