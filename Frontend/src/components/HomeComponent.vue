<template>
  <div class="dashboard-grid">
     <div class="welcome-card">
        <div>
          <p class="welcome-date">Aujourd'hui</p>
          <h1 class="welcome-title">Bonjour, Hilton</h1>
        </div>
     </div>
  </div>
</template>

<style scoped>
.dashboard-grid {
  display: flex;
  flex-direction: column;
  gap: 24px;
}
.welcome-card {
  background: #1d4ed8;
  border-radius: 12px;
  padding: 28px 32px;
  color: #fff;
}
.welcome-date {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 6px;
}
.welcome-title {
  font-size: 22px;
  font-weight: 700;
}
</style>
