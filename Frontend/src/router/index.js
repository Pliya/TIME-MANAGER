import { createRouter, createWebHistory } from "vue-router"

import ClockManager from "../components/ClockManager.vue"

const router = createRouter({
  history: createWebHistory(),

  routes: [
    {
      path: "/clock/:userId",
      component: ClockManager,
    },
  ]
})


export default router