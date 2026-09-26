import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', name: 'home' },
  { path: '/clock', name: 'clock' },
  { path: '/working-times', name: 'working-times' },
  { path: '/profile', name: 'profile' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
