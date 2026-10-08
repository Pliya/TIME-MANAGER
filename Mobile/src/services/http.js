import axios from 'axios'
import { xsrf_token, clear_session } from '@/session'

// Même adresse qu'avant : l'émulateur atteint l'API via "adb reverse tcp:4000 tcp:4000"
const API_URL = 'http://localhost:4000/api'

export const http = axios.create({
  baseURL: API_URL,
  withCredentials: true,
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
})

http.interceptors.request.use((config) => {
  if (xsrf_token.value) config.headers['x-xsrf-token'] = xsrf_token.value
  return config
})

http.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && !error.config?.url?.includes('/users/sign_in')) {
      clear_session()
      window.location.hash = '#/sign_in'
    }
    return Promise.reject(error)
  },
)

// Pas de réponse du serveur = réseau coupé ou serveur injoignable
export const isNetworkError = (err) => !err.response && !axios.isCancel(err)