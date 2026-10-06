import axios from 'axios'
import { xsrfToken, clearSession } from './session'

export const api = axios.create({ baseURL: '/api', withCredentials: true })

api.interceptors.request.use(config =>
{
  config.headers['x-xsrf-token'] = xsrfToken.value
  return config
})

api.interceptors.response.use(
  response => response,
  error =>
  {
    if (error.response?.status === 401 && !error.config.url.includes('/users/sign_in')) {
      clearSession()
      window.location.assign('/sign_in')
    }
    return Promise.reject(error)
  },
)
