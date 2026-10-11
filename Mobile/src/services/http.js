import axios from 'axios'
import { watch } from 'vue'
import { xsrf_token, clear_session, logged_user_id } from '@/session'

// Adresse de l'API, choisie au moment du build :
//   npm run build   -> https://gotham-manager.duckdns.org/api  (valeur de .env.production)
//   npm run dev     -> http://localhost:4000/api               (émulateur/USB + "adb reverse tcp:4000 tcp:4000")
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api'

// Le cookie de connexion (SameSite=Lax) n'est pas envoyé quand l'API n'est pas
// sur localhost. Le mobile garde donc le JWT et l'envoie dans l'en-tête
// "Authorization: Bearer". L'API ne le donne qu'aux requêtes "x-client: mobile".
const TOKEN_KEY = 'authToken'
let authToken = localStorage.getItem(TOKEN_KEY)

function setAuthToken(token) {
  authToken = token || null
  if (authToken) localStorage.setItem(TOKEN_KEY, authToken)
  else localStorage.removeItem(TOKEN_KEY)
}

// Déconnexion (quelle que soit la page qui la déclenche) : on oublie le jeton
watch(logged_user_id, (id) => {
  if (!id) setAuthToken(null)
})

export const http = axios.create({
  baseURL: API_URL,
  withCredentials: true,
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
})

http.interceptors.request.use((config) => {
  config.headers['x-client'] = 'mobile'
  if (xsrf_token.value) config.headers['x-xsrf-token'] = xsrf_token.value
  if (authToken) config.headers.Authorization = `Bearer ${authToken}`
  return config
})

http.interceptors.response.use(
  (response) => {
    // Connexion réussie : l'API renvoie le JWT pour le mobile
    if (response.config?.url?.includes('/users/sign_in')) setAuthToken(response.data?.data?.token)
    return response
  },
  (error) => {
    if (error.response?.status === 401 && !error.config?.url?.includes('/users/sign_in')) {
      clear_session()
      setAuthToken(null)
      window.location.hash = '#/sign_in'
    }
    return Promise.reject(error)
  },
)

// Pas de réponse du serveur = réseau coupé ou serveur injoignable
export const isNetworkError = (err) => !err.response && !axios.isCancel(err)