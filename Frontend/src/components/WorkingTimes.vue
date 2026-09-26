<template>
  <div class="dashboard-grid">
     <p class="subtitle">Gérez vos plages horaires de travail.</p>
     <div class="placeholder-card">
        <h3>Mes temps de travail</h3>
        <p>Composant <code>WorkingTimes.vue</code></p>
     </div>
  </div>
</template>

<style scoped>
.dashboard-grid {
  display: flex; flex-direction: column; gap: 24px;
}
.subtitle { color: #8a97b5; font-size: 15px; margin-top: -8px; margin-bottom: 4px; }
.placeholder-card {
  background: #fff; border-radius: 12px; padding: 32px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05); text-align: center;
}
.placeholder-card h3 { font-size: 17px; font-weight: 600; margin-bottom: 8px; }
.placeholder-card p { color: #8a97b5; font-size: 14px; }
.placeholder-card code { background: #f0f4fb; padding: 2px 6px; border-radius: 4px; font-size: 13px; color: #2563eb; }
</style>
