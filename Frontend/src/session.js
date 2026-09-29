import { ref } from 'vue'

function readStoredUserId() {
  try {
    return Number(localStorage.getItem('userId')) || null
  } catch {
    return null
  }
}

export const loggedUserId = ref(readStoredUserId())

export function login(userId) {
  loggedUserId.value = userId
  try {
    localStorage.setItem('userId', userId)
  } catch {}
}

export function logout() {
  loggedUserId.value = null
  try {
    localStorage.removeItem('userId')
  } catch {}
}
