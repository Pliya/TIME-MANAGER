import axios from 'axios'
import { xsrf_token, clear_session } from './session'

export const api = axios.create({ baseURL: '/api', withCredentials: true })

api.interceptors.request.use(config =>
{
  config.headers['x-xsrf-token'] = xsrf_token.value
  return config
})

api.interceptors.response.use(
  response => response,
  error =>
  {
    if (error.response?.status === 401 && !error.config.url.includes('/users/sign_in')) {
      clear_session()
      window.location.assign('/sign_in')
    }
    return Promise.reject(error)
  },
)
