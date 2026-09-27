<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'

const route = useRoute()
const user_id = ref(1)
const current_user = ref(null)

const page_title = computed(() => {
  if (route.path.startsWith('/workingTimes')) return 'Working Times'
  if (route.path.startsWith('/workingTime')) return 'Working Time'
  if (route.path.startsWith('/charts') || route.path.startsWith('/chartManager')) return 'Chart Manager'
  if (route.path.startsWith('/clock')) return 'Clock Manager'
  if (route.path === '/profile') return 'Profil'
  return 'Dashboard'
})

async function fetch_current_user() {
  if (!user_id.value) return
  try {
    const { data } = await axios.get(`http://localhost:4000/api/users/${user_id.value}`)
    current_user.value = data.data || null
  } catch (err) {
    console.error('Erreur chargement user topbar:', err)
  }
}

function handle_user_updated(updated_user) {
  current_user.value = updated_user
}

onMounted(fetch_current_user)
</script>

<template>
  <div class="layout">
    <aside class="sidebar">
      <div class="sidebar-brand">
        <div class="brand-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <span class="brand-name">Time Manager</span>
      </div>

      <nav class="sidebar-nav">
        <router-link to="/" class="nav-item" :class="{ active: route.path === '/' }">
          <span class="nav-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          </span>
          <span>Dashboard</span>
        </router-link>

        <router-link to="/clock" class="nav-item" :class="{ active: route.path.startsWith('/clock') }">
          <span class="nav-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          </span>
          <span>Clock</span>
        </router-link>

        <router-link to="/charts" class="nav-item" :class="{ active: route.path.startsWith('/charts') || route.path.startsWith('/chartManager') }">
          <span class="nav-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
          </span>
          <span>Charts</span>
        </router-link>

        <router-link to="/workingTimes" class="nav-item" :class="{ active: route.path.startsWith('/workingTimes') || route.path.startsWith('/workingTime') }">
          <span class="nav-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          </span>
          <span>Working Times</span>
        </router-link>

        <router-link to="/profile" class="nav-item" :class="{ active: route.path === '/profile' }">
          <span class="nav-icon">
             <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          </span>
          <span>Profil</span>
        </router-link>
      </nav>

      <div class="sidebar-footer">
        <a href="#" class="nav-item logout">
          <span class="nav-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          </span>
          <span>Déconnexion</span>
        </a>
      </div>
    </aside>

    <div class="main-wrapper">
      <header class="topbar">
        <h2 class="page-title">{{ page_title }}</h2>
        <div class="user-badge">
          <div class="avatar">
            {{ current_user?.username ? current_user.username.charAt(0).toUpperCase() : 'H' }}
          </div>
          <div class="user-info">
            <span class="user-name">{{ current_user?.username || 'Hilton' }}</span>
            <span class="user-email">{{ current_user?.email || 'hilton@email.com' }}</span>
          </div>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>
        </div>
      </header>

      <main class="main-content">
        <router-view v-slot="{ Component }">
          <component
            :is="Component"
            :userId="user_id"
            @user-updated="handle_user_updated"
          />
        </router-view>
      </main>
    </div>
  </div>
</template>

<style>
.layout {
  display: flex;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
}

.sidebar {
  width: 240px;
  min-width: 240px;
  height: 100vh;
  background: #0d1b3e;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 24px 20px 22px;
  border-bottom: 1px solid rgba(255,255,255,0.07);
}

.brand-icon {
  width: 34px; height: 34px;
  background: #1d4ed8;
  border-radius: 8px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}

.brand-name {
  font-size: 15px; font-weight: 700;
  color: #fff; letter-spacing: -0.01em;
}

.sidebar-nav {
  flex: 1;
  padding: 16px 12px;
  display: flex; flex-direction: column; gap: 2px;
}

.nav-item {
  display: flex; align-items: center; gap: 12px;
  padding: 11px 14px;
  border-radius: 8px;
  color: rgba(255,255,255,0.55);
  font-size: 13.5px; font-weight: 500;
  text-decoration: none; cursor: pointer;
  transition: background 0.12s, color 0.12s;
}

.nav-item:hover { background: rgba(255,255,255,0.07); color: rgba(255,255,255,0.9); }
.nav-item.active { background: #1d4ed8; color: #fff; }

.nav-icon {
  display: flex; align-items: center; flex-shrink: 0; color: inherit;
}

.sidebar-footer {
  padding: 12px 12px 28px;
  border-top: 1px solid rgba(255,255,255,0.07);
}

.logout:hover { background: rgba(239,68,68,0.15); color: #fca5a5; }

.main-wrapper {
  flex: 1;
  min-width: 0;
  display: flex; flex-direction: column;
  height: 100vh;
  overflow: hidden;
}

.topbar {
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 32px;
  height: 62px;
  min-height: 62px;
  background: #fff;
  border-bottom: 1px solid #e2e8f0;
  flex-shrink: 0;
}

.page-title { font-size: 16px; font-weight: 700; color: #1e2a4a; }

.user-badge {
  display: flex; align-items: center; gap: 10px;
  padding: 6px 12px; border-radius: 8px; cursor: pointer;
  transition: background 0.12s;
}
.user-badge:hover { background: #f4f6fb; }

.avatar {
  width: 32px; height: 32px;
  background: #1d4ed8; border-radius: 50%;
  color: #fff; font-weight: 700; font-size: 13px;
  display: flex; align-items: center; justify-content: center;
}

.user-info { display: flex; flex-direction: column; line-height: 1.3; }
.user-name  { font-size: 13px; font-weight: 600; color: #1e2a4a; }
.user-email { font-size: 11px; color: #94a3b8; }

.main-content {
  flex: 1;
  overflow-y: auto;
  padding: 28px 32px;
  background: #f0f4fb;
}
</style>
