import axios from 'axios'

export const API_URL = import.meta.env.VITE_API_URL || 'http://92.4.131.118:4000/api'

const api = axios.create({ baseURL: API_URL })

export default api
