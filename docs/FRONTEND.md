# Time Manager — Documentation du Frontend

Doc technique du dossier `Frontend/`, **fichier par fichier, fonction par fonction**, pour comprendre et expliquer le code en soutenance.

Stack : **Vue 3** (`<script setup>`) · **Vite** (dev + build) · **Tailwind CSS v4** · **axios** · **vue-router** · **Chart.js** (via vue-chartjs).

---

## 1. Démarrage de l'application

### `index.html`
La **coquille** de la SPA. Contient `<div id="app">` (vide au départ, l'app s'y injecte), charge la police Inter et le favicon, et lance `/src/main.js` en module.

### `src/main.js` — le point d'entrée
```js
setup_accessibility()
createApp(App).use(router).use(i18n).mount('#app')
```
- importe le CSS global, le composant racine `App.vue`, le routeur, l'i18n et le dictionnaire de traductions ;
- `setup_accessibility()` applique les préférences (contraste/texte/voix) sauvegardées ;
- `createApp(App)` crée l'app → `.use(router)` branche la navigation → `.use(i18n)` rend `$t()` dispo partout → `.mount('#app')` injecte tout dans le `<div id="app">`.

---

## 2. Fichiers cœur

### `src/session.js` — qui est connecté
État de connexion, gardé en `localStorage` pour survivre à un rechargement (concept **Web Storage** du bootstrap).

| Export | Rôle |
|---|---|
| `logged_user_id`, `role`, `xsrf_token`, `username` | refs réactives, initialisées depuis `localStorage` |
| `save_session(user, token)` | après connexion : remplit les refs **et** le `localStorage` |
| `clear_session()` | déconnexion : vide les refs et le `localStorage` |
| `has_role(...roles)` | `true` si l'utilisateur est **Administrator** (il peut tout) **ou** a l'un des rôles passés |
| `is_manager()` | raccourci `has_role('Manager')` (donc vrai aussi pour l'admin) |
| `is_admin()` | vrai seulement si rôle = `Administrator` |
| `home_path()` | page d'accueil selon le rôle : `/` (employé), `/equipe` (manager), `/utilisateurs` (admin) |

### `src/api.js` — le client HTTP (cœur de la sécurité)
```js
export const api = axios.create({ baseURL: '/api', withCredentials: true })
```
- **`baseURL: '/api'`** : chemin **relatif** → les appels suivent le domaine courant (le proxy nginx renvoie `/api` vers le back). C'est ce qui rend l'app indépendante du domaine.
- **`withCredentials: true`** : envoie le **cookie** (le JWT HttpOnly) à chaque requête.
- **Intercepteur de requête** : ajoute l'en-tête `x-xsrf-token` à **toutes** les requêtes (concept **XSRF** du bootstrap : le cookie contient le JWT, l'en-tête contient le token XSRF, et le back vérifie que les deux correspondent).
- **Intercepteur de réponse** : si le back répond **401** (sauf sur `/users/sign_in`), on déconnecte et on renvoie vers `/sign_in`.

### `src/store.js` — l'état partagé entre tous les utilisateurs
Un « store maison » réactif (`reactive`) qui contient toutes les données partagées : `rules`, `planning`, `published`, `corrections`, `justifications`, `absences`, `overtimeDecisions`, `validatedSheets`, `reminders`, `dismissedAlerts`, `pauses`, `batSignal`, `permissions`, `rightsHistory`.

| Élément | Rôle |
|---|---|
| `defaults` | valeurs par défaut (dont `rules`, les règles de l'entreprise) |
| `store` | l'objet réactif, copie des defaults |
| `assign(key, value)` | remplace une clé dans le store et mémorise sa version (`synced`) |
| `load_shared_data()` | `GET /api/data` ; met à jour chaque clé **seulement si elle a changé** (évite les re-rendus inutiles) et **pas** pendant une sauvegarde en cours (`pending`) |
| `save(key)` | `PUT /api/data/:key` quand une clé change (déclenché par un `watch` **debouncé 300 ms**) |
| `watch` par clé | observe `store[key]` en profondeur ; à chaque modif locale → programme un `save` |
| `watch(logged_user_id)` | à la connexion → charge les données ; à la déconnexion → remet les defaults |
| `setInterval(load_shared_data, 4000)` | rafraîchit toutes les 4 s (synchro entre appareils) |
| `new_id()` | génère un id unique (timestamp + aléatoire) pour les nouveaux éléments |

### `src/i18n.js` — la traduction (système maison)
| Export | Rôle |
|---|---|
| `locale` | langue courante (`'fr'`/`'en'`), gardée en `localStorage` |
| `setLocale(v)` / `toggleLocale()` | change la langue |
| `addMessages(map)` | ajoute des entrées au dictionnaire `en` |
| `t(fr, params)` | renvoie la traduction anglaise si `locale === 'en'` (sinon le français) ; remplace les `{param}` |
| `i18n` (plugin) | installe `$t` dans tous les templates (`app.use(i18n)`) |
| `dateLocale()` | `'en-US'` ou `'fr-FR'` pour formater les dates selon la langue |

Principe : **la clé = le texte français**. Si une traduction manque, on retombe sur le français (jamais de case vide).

### `src/translations.js`
Le **dictionnaire** français → anglais (des centaines d'entrées), chargé au démarrage via `addMessages(...)`.

### `src/accessibility.js` — l'accessibilité
| Export/fonction | Rôle |
|---|---|
| `accessibility` | état réactif `{ contrast, largeText, voice }`, chargé du `localStorage` |
| `speak(text)` | lit un texte à voix haute (SpeechSynthesis, voix FR) |
| `text_of(el)` / `read_focused(e)` | si « lecture vocale » est active, lit l'élément qui reçoit le focus |
| `apply()` | ajoute/retire les classes `high-contrast` / `large-text` sur `<html>` + sauvegarde |
| `setup_accessibility()` | applique au démarrage, observe les changements, écoute le focus |

### `src/router/index.js` — la navigation et les rôles (bootstrap)
Déclare toutes les routes avec un `meta` : `title`, `public` (accessible sans connexion) et `roles` (qui peut y accéder).

Constantes de rôles :
```js
const EMPLOYEE = ['Employee']
const MANAGER = ['Manager', 'Administrator']
const ADMIN = ['Administrator']
const EMPLOYEE_AND_MANAGER = ['Employee', 'Manager', 'Administrator']
```

**Le garde `router.beforeEach(to => …)`** — exécuté **avant chaque changement de page** (le `beforeEach` imposé par le bootstrap). Logique :
1. Route **publique** (`/sign_in`) → si déjà connecté, redirige vers `home_path()` ; sinon laisse passer.
2. Pas connecté → redirige vers `/sign_in` (routes **privées**).
3. Route avec `roles` et le rôle courant n'y est pas → redirige vers `home_path()` (routes **administration**).
4. URL contenant un id d'un **autre** utilisateur, alors qu'on n'est pas manager/admin → redirige (un employé ne voit que ses propres données).

`router.afterEach(() => load_shared_data())` : à chaque navigation, on recharge les données partagées (pour qu'elles soient fraîches).

---

## 3. Logique métier (`src/utils/` et `team.js`)

### `src/utils/kpi.js` — calculs de temps
| Fonction | Rôle |
|---|---|
| `to_date(time)` | convertit `"2026-10-09 08:00:00"` en objet `Date` |
| `sort_by_time(list, key)` | trie une liste par une clé date (puis par id) |
| `hours_of(wt)` | durée d'un temps de travail en heures (fin − début) |
| `hours_to_text(h)` | formate `8.5` → `"8h 30m"` |
| `date_key(date)` | `"AAAA-MM-JJ"` |
| `now_text()` | date+heure locale `"AAAA-MM-JJ hh:mm:ss"` (pour pointer à l'heure réelle) |
| `month_key(date)` | `"AAAA-MM"` |
| `add_days(date, n)` | ajoute n jours |
| `start_of_week(date)` | le lundi de la semaine |
| `is_night(time)` | vrai si l'heure est dans la plage de nuit (selon `rules.nightStart/nightEnd`) |
| `in_week(times)` / `in_month(times)` | filtre les temps de la semaine / du mois |
| `summarize(times)` | renvoie `{ total, night, nights, overtime, normal }` (heures sup = au-delà de `rules.weekHours` par semaine) |
| `max_consecutive_nights(times)` | plus longue série de nuits consécutives |
| `compute_kpi(times)` | KPI d'un employé : heures totales, jours travaillés, moyenne/jour |

### `src/utils/absences.js` — congés et récupérations
| Fonction | Rôle |
|---|---|
| `LEAVE_DAYS_PER_YEAR` | 25 (quota de congés annuel) |
| `working_days(start, end)` | nb de jours ouvrés entre deux dates (hors week-end) |
| `recovery_balance(user_id)` | solde d'heures à récupérer (gagnées en heures sup − déjà prises) |
| `leave_taken(user_id)` | jours de congés validés pris cette année |
| `period_text(a)` | affiche la période (« 12 – 16 oct. ») selon la langue |
| `length_text(a)` | durée (« 5 jours » ou « 6h 30m » pour une récup.) |
| `status_color(status)` | couleur du statut (vert/rouge/gris) |
| `absence_on(user_id, day)` | l'absence **validée** d'un agent un jour donné (pour le planning) |
| `ABSENCE_SHORT` | libellés courts (Congé → Congé, Arrêt maladie → Arrêt…) |

### `src/utils/planning.js` — le planning et les shifts
| Élément | Rôle |
|---|---|
| `SHIFTS` | les créneaux : `J` (Jour), `N` (Nuit), `A` (Astreinte), `R` (Repos), avec heures |
| `DAY_NAMES` | `['Lun'…'Dim']` |
| `shift_of(user_id, date)` | le shift prévu pour un agent un jour donné |
| `set_shift(user_id, date, shift)` | pose un shift dans `store.planning` |
| `week_days(monday)` | les 7 dates de la semaine |
| `planned_nights(user_id, month)` | nb de nuits prévues dans le mois |
| `planning_warnings(user_id, monday, name)` | alertes (trop de nuits d'affilée, pas de repos après une nuit, plafond mensuel dépassé) |
| `planned_hours(user_id, monday)` | total d'heures prévues sur la semaine |
| `shift_times(shift, date)` | les horaires réels d'un shift (gère le passage à minuit pour la nuit) |

### `src/team.js` — chargement des agents
| Fonction | Rôle |
|---|---|
| `with_data(user)` | enrichit un utilisateur avec ses pointages et temps (via l'API), et son statut présent/absent |
| `load_team_members()` | tous les membres des équipes de l'utilisateur (fusionnées) |
| `load_teams()` | les équipes **avec leurs membres** (pour le sélecteur de stats par équipe) |
| `load_all_users()` | tous les utilisateurs (admin) |
| `team_average(members, day, exclude)` | moyenne d'heures de l'équipe un jour donné |
| `compute_alerts(members)` | génère les alertes manager (oubli de pointage, trop de nuits, heures sup élevées, durée inhabituelle), en ignorant celles déjà écartées |

---

## 4. Composants — layout et réutilisables

### `src/App.vue` — le cadre commun
- Si la route est publique (`/sign_in`) → affiche juste `<router-view>`.
- Sinon : **splash screen** au lancement (sceau + TIME MANAGER, 1,8 s), **sidebar** (menu par rôle), **en-tête** (titre de page + `UserComponent`), et `<main>` avec `<router-view>` (la page du moment).
- `all_sections` : les sections du menu par rôle (Employé / Mon espace / Administrateur-RH / Manager). `navigation` : filtre selon le rôle.
- `disconnect()` : appelle `/users/sign_out`, `clear_session()`, redirige.

### Composants réutilisables
| Composant | Rôle |
|---|---|
| `StatCard.vue` | une carte KPI (bandeau bleu + icône + grande valeur + indice). `label`/`hint` traduits via `$t`. |
| `Chip.vue` | une pastille colorée (gray/dark/red/green/outline) ; contenu via `<slot>` |
| `Toggle.vue` | un interrupteur on/off (`v-model` via `defineModel`) |
| `LogoIcon.vue` | affiche une icône PNG de `assets/logo/` par son `name` |
| `DataTable.vue` | un tableau générique (`head` + `rows`) ; une cellule `{chip, color}` devient une pastille |
| `ChartInterface.vue` | enveloppe Chart.js (via vue-chartjs) ; prend `type`, `chartData`, `chartOptions` |
| `UserComponent.vue` | le badge utilisateur en haut à droite (avatar, menu déroulant, lien « Mon profil », création d'utilisateur pour l'admin) |
| `AccessibilityPanel.vue` | le panneau Accessibilité (contraste/texte/voix) + le **sélecteur de langue FR/EN** |

---

## 5. Composants — pages Employé

### `Authentication.vue` — la connexion (bootstrap auth)
- Formulaire email + mot de passe. `sign_in()` fait `POST /api/users/sign_in`, puis `save_session(...)` et redirige.
- Gère l'affichage/masquage du mot de passe, « mot de passe oublié », et un **tutoriel** en étapes.
- Design : image de Gotham + sceau, panneau Accessibilité.

### `HomeComponent.vue` — le dashboard
KPI de la semaine (heures, jours, moyenne, dernier temps), carte **Pointage** (état + bouton), graphique des heures de la semaine, dernières sessions.

### `ClockManager.vue` — le pointage
- Charge les pointages (`GET /clocks/:id`), détermine si l'agent est **pointé** ou non (dernier clock).
- `clock()` : `POST /clocks/:id` avec l'heure réelle (`now_text()`) → arrivée/sortie en alternance.
- **Pause** locale (ne crée pas de session) : fige le minuteur, reprend sans repartir à 0.
- Boutons Trajet, Incident, « Journée conforme au planning ». `goal_message` : objectif du jour.

### `WorkingTimes.vue` — « Mes temps »
- KPI (`compute_kpi`), liste des sessions (lecture seule).
- Formulaire **demande de correction** + **historique** — affichés **seulement pour le propriétaire** (`is_owner`). Un manager/admin qui consulte un autre agent voit un **bouton Retour** et pas le formulaire.

### `WorkingTime.vue` — créer/modifier un temps (manager)
Formulaire de création/édition d'un temps de travail (dates/heures), avec **bouton Retour** et suppression en mode édition.

### `PlanningPage.vue` — planning de l'employé
Affiche la semaine publiée par le manager ; navigation entre semaines ; si non publié, propose les semaines disponibles ; KPI nuits/astreintes/heures prévues.

### `AbsencesPage.vue` — absences de l'employé
- KPI (congés restants, récup., arrêts, demandes en attente).
- `send()` : crée une demande (Congé/Arrêt/Récupération) avec contrôles (quota, dates) et l'ajoute à `store.absences`.
- Tableau « Mes demandes » (filtré sur `logged_user_id`).

### `ChartManager.vue` — statistiques de l'agent
Graphiques configurables (horaires de pointage, fréquence, durée/jour, répartition) ; fiche de paie estimée. **Bouton Retour** quand un manager/admin consulte un autre agent.

### `ProfilePage.vue` — mon profil
- `GET /users/me` pour pré-remplir, `PUT /users/me` pour modifier (nom, email, mot de passe), `DELETE /users/me` pour supprimer son compte.
- Accessible à **tous** (route sans `roles`).

---

## 6. Composants — pages Manager

| Composant | Rôle |
|---|---|
| `Manager_TeamPage.vue` | « Équipe » : KPI, tableau de l'équipe, justifications reçues, **gestion des équipes** (créer/supprimer, ajouter/retirer des agents) |
| `Manager_AlertsPage.vue` | « Alertes » : liste les alertes (`compute_alerts`) avec actions (corriger, relancer, vérifier) |
| `Manager_ValidationPage.vue` | « Validation » : demandes de correction (accepter/refuser), heures sup à décider (payées/récupérées), **demandes d'absence de l'équipe (lecture seule)**, feuilles du mois |
| `Manager_TeamPlanningPage.vue` | « Planning » : grille éditable des shifts, Bat-signal, répartition des nuits, publication du planning, pastille « Congé » pour les absences validées |
| `Manager_TeamStatsPage.vue` | « Statistiques » : **sélecteur d'équipe** (quand plusieurs), stats agrégées, puis clic sur un agent pour son détail |

---

## 7. Composants — pages Administrateur / RH

| Composant | Rôle |
|---|---|
| `UsersPage.vue` | « Utilisateurs » : liste, recherche, **changement de rôle** (`PUT /users/:id/role`), permissions (toggles), liens Temps/Statistiques, **suppression** d'un utilisateur, historique des droits |
| `RulesPage.vue` | « Règles » : paramètres (heures sup, nuit, pauses, suivi) stockés dans `store.rules`, édités via toggles et champs |
| `PayrollPage.vue` | « Paie » : KPI (normales, nuit ×1.5, sup ×2, à récupérer), détail par agent, **export CSV** |
| `AdminAbsencesPage.vue` | « Absences » : demandes à traiter avec **décision** (valider/refuser, justificatif reçu), calendrier des absences |

---

## 8. Build & déploiement (rappel)

- **Vite** : `npm run dev` (serveur local avec proxy `/api` → `localhost:4000`), `npm run build` (génère `dist/`).
- **nginx** (`nginx.conf`) : sert le `dist/`, renvoie `/api` vers le back, écoute en **HTTPS (443)**.
- **Docker** : l'image frontend = nginx + le build. Déployée via Travis sur Google Cloud.
- L'app appelle `/api` en **relatif** → suit le domaine (`gotham-manager.duckdns.org`).

---

## 9. Les thèmes des bootstraps (pour la soutenance)

**Bootstrap Authentication** — tout ce qui touche la connexion :
- **JWT** (cookie **HttpOnly**) + **XSRF** (en-tête) vérifiés à chaque requête — voir `api.js` et le back.
- **bcrypt** pour hacher les mots de passe (back).
- **`beforeEach()`** du routeur = le garde par rôle (`router/index.js`).
- **localStorage** pour id/rôle/token (`session.js`).
- Routes **public / private / administration**.

**Bootstrap Security** — le pentest :
- Pour chaque faille : *c'est quoi ? comment la détecter ? comment s'en protéger ?*
- Outils : dirb, nmap, sqlmap, nikto, John the Ripper, Wireshark.
- Voir `docs/RAPPORT_SECURITE.md`.
