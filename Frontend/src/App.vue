<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import ClockManager from './components/ClockManager.vue'
import ChartManager from './components/ChartManager.vue'

const route = useRoute()
const userId = ref(1)

// Titre dynamique basé sur la route
const pageTitle = computed(() => {
  const path = route.path
  if (path === '/working-times') return 'Mes temps de travail'
  if (path === '/profile') return 'Profil'
  if (path === '/clock') return 'Clock Manager'
  return 'Accueil'
})
</script>

<template>
  <div class="layout">
    <!-- ── Sidebar ── -->
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
          <span>Accueil</span>
        </router-link>

        <router-link to="/clock" class="nav-item" :class="{ active: route.path === '/clock' }">
          <span class="nav-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          </span>
          <span>Clock Manager</span>
        </router-link>

        <router-link to="/working-times" class="nav-item" :class="{ active: route.path === '/working-times' }">
          <span class="nav-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          </span>
          <span>Mes temps de travail</span>
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

    <!-- ── Right panel ── -->
    <div class="main-wrapper">
      <header class="topbar">
        <h2 class="page-title">{{ pageTitle }}</h2>
        <div class="user-badge">
          <div class="avatar">H</div>
          <div class="user-info">
            <span class="user-name">Hilton</span>
            <span class="user-email">hilton@gmail.com</span>
          </div>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>
        </div>
      </header>

      <main class="main-content">
        <!-- 🏠 ACCUEIL SECTION -->
        <div v-show="route.path === '/'" class="dashboard-grid">
           <div class="welcome-card">
              <div>
                <p class="welcome-date">Aujourd'hui</p>
                <h1 class="welcome-title">Bonjour, Hilton</h1>
              </div>
           </div>
        </div>

        <!-- ⏱ CLOCK MANAGER SECTION -->
        <div v-show="route.path === '/clock'" class="dashboard-grid">
           <p class="subtitle">Déclarez vos heures de travail en un clic.</p>
           
           <ClockManager :userId="userId" />
           
           <div class="chart-section">
             <h3>Mes statistiques</h3>
             <p class="chart-subtitle">Suivez votre activité et vos heures de travail.</p>
             <ChartManager :userId="userId" />
           </div>
        </div>
        
        <!-- 📅 WORKING TIMES SECTION -->
        <div v-show="route.path === '/working-times'" class="dashboard-grid">
           <p class="subtitle">Gérez vos plages horaires de travail.</p>
           <div class="placeholder-card">
              <h3>Mes temps de travail</h3>
              <p>Placez le composant <code>WorkingTimes.vue</code> existant ici.</p>
           </div>
        </div>

        <!-- 👤 PROFILE SECTION -->
        <div v-show="route.path === '/profile'" class="dashboard-grid">
           <p class="subtitle">Gérez vos informations personnelles.</p>
           <div class="placeholder-card">
              <h3>Mon Profil</h3>
              <p>Placez le composant <code>UserComponent.vue</code> existant ici.</p>
           </div>
        </div>
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

/* ── Sidebar ── */
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

/* ── Main ── */
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

/* ── Dashboard Content ── */
.dashboard-grid {
  display: flex; flex-direction: column; gap: 24px;
}

.welcome-card {
  background: #1d4ed8;
  border-radius: 12px;
  padding: 28px 32px;
  color: #fff;
}
.welcome-date { font-size: 13px; color: rgba(255,255,255,0.8); margin-bottom: 6px; }
.welcome-title { font-size: 22px; font-weight: 700; }

.subtitle { color: #8a97b5; font-size: 15px; margin-top: -8px; margin-bottom: 4px; }

.chart-section {
  margin-top: 24px;
}
.chart-section h3 { font-size: 18px; font-weight: 700; color: #1e2a4a; margin-bottom: 4px; }
.chart-subtitle { color: #8a97b5; font-size: 14px; margin-bottom: 20px; }

.placeholder-card {
  background: #fff; border-radius: 12px; padding: 32px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05); text-align: center;
}
.placeholder-card h3 { font-size: 17px; font-weight: 600; margin-bottom: 8px; }
.placeholder-card p { color: #8a97b5; font-size: 14px; }
.placeholder-card code { background: #f0f4fb; padding: 2px 6px; border-radius: 4px; font-size: 13px; color: #2563eb; }
</style>
