# Time Manager · Ville de Gotham

> Gestion du temps de travail pour l'administration de Gotham City : pointage, planning (nuits & astreintes), absences, validation, paie et statistiques — web **et** mobile.

Application full-stack développée dans le cadre du projet **Piscine (Master 1, Epitech)**. Le thème « Gotham » habille un vrai outil RH : pointer en un geste, suivre ses heures, gérer les plannings de nuit, valider les feuilles du mois et exporter la paie.

**Stack :** Vue 3 (Vite) · Phoenix / Elixir · PostgreSQL · Cordova (Android) · Docker · nginx

---

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Architecture](#architecture)
- [Structure du dépôt](#structure-du-dépôt)
- [Démarrage rapide (Docker)](#démarrage-rapide-docker)
- [Développement sans Docker](#développement-sans-docker)
- [Variables d'environnement](#variables-denvironnement)
- [Application mobile](#application-mobile)
- [Sécurité](#sécurité)
- [API & documentation](#api--documentation)
- [Tests](#tests)
- [Production & déploiement](#production--déploiement)
- [Documentation du projet](#documentation-du-projet)

---

## Fonctionnalités

Trois rôles, chacun avec son espace. L'**administrateur** peut tout faire (il accède aussi aux pages manager).

### 👷 Employé
- **Pointage** en un geste (arrivée / sortie), avec pause, trajet et bouton « Incident ». Fonctionne hors-ligne (le pointage est gardé sur l'appareil). Mode borne : « Journée conforme au planning » en un clic.
- **Dashboard** : heures de la semaine, jours travaillés, dernières sessions.
- **Mes temps** : consultation en lecture seule + **demande de correction** (le manager décide sous 48 h, refus motivé).
- **Planning** publié à l'avance (nuits, astreintes, repos), compteur de nuits avec plafond.
- **Absences** : congés, arrêts maladie, récupérations — zéro papier.
- **Statistiques** personnelles + fiche de paie estimée. *Aucune comparaison entre collègues.*
- **Accessibilité** : contraste élevé, texte agrandi, lecture vocale, bilingue FR/EN — dès la connexion.

### 👔 Manager / Chef de service
- **Équipe** : vue d'ensemble (présents, heures, heures sup, nuits), gestion des équipes.
- **Alertes** : pointage oublié, trop de nuits, durée inhabituelle, heures sup élevées.
- **Validation** : corrections, décisions sur les heures sup (payées ou récupérées), feuilles du mois.
- **Planning d'équipe** : grille éditable, répartition des nuits, publication, Bat-signal (astreinte).
- **Statistiques d'équipe** (par équipe ou globales).

### 🛡️ Administrateur / RH
- **Utilisateurs** : rôles, permissions fines, suppression, historique des droits.
- **Règles** : seuils heures sup, plage de nuit, pauses/trajets, préavis planning…
- **Paie** : heures normales / nuit ×1,5 / sup ×2 / récupération, **export CSV** pour la comptabilité.
- **Absences (RH)** : validation des demandes, calendrier global d'équipe.

---

## Architecture

```
  Navigateur / APK                nginx (prod)              Phoenix API            PostgreSQL
 ┌───────────────┐   HTTPS   ┌──────────────────┐   /api   ┌──────────────┐   SQL   ┌──────────┐
 │  Vue 3 (SPA)  │ ────────▶ │  sert le build + │ ───────▶ │  Elixir /    │ ──────▶ │  Postgres│
 │  Vite build   │           │  proxy /api      │          │  Ecto        │         │          │
 └───────────────┘           └──────────────────┘          └──────────────┘         └──────────┘
```

- Le frontend appelle l'API en **chemin relatif** `/api` → suit le domaine courant (le proxy nginx renvoie vers le back).
- Authentification par **JWT** en **cookie HttpOnly** + **token XSRF** en en-tête (voir [Sécurité](#sécurité)).
- État partagé synchronisé via `/api/data` (règles, planning, absences, corrections…).

---

## Structure du dépôt

```
TIME-MANAGER/
├── Frontend/            Application web — Vue 3 + Vite + Tailwind v4
│   └── src/             components/, router/, store.js, api.js, session.js, i18n.js, utils/
├── manager/             API — Phoenix / Elixir + Ecto (PostgreSQL)
│   ├── lib/             contrôleurs, plugs (Auth, Role, RateLimit), schémas
│   ├── config/          dev.exs, prod.exs, runtime.exs, test.exs
│   └── Dockerfile
├── Mobile/              Application mobile — Cordova (Android) qui embarque le front
│   └── releases/        time-manager.apk (build prêt à installer)
├── maquettes/           Maquettes (web + mobile) et visuel PNG
├── docs/                Rapports & documentation (voir plus bas)
├── docker-compose.yml           Environnement de dev (db + back + front)
├── docker-compose.prod.yml      Environnement de production
├── .travis.yml          CI/CD (build images + déploiement)
└── README.md
```

---

## Démarrage rapide (Docker)

Pré-requis : **Docker** + **Docker Compose**.

1. Crée un fichier `.env` à la racine :

   ```env
   PGHOST=db
   PGPORT=5432
   PGUSER=postgres
   PGPASSWORD=postgres
   PGDATABASE=manager_dev
   ```

2. Lance tout :

   ```bash
   docker compose up --build
   ```

3. Accès :
   - **Frontend** → http://localhost:5174
   - **API** → http://localhost:4000/api
   - **Swagger** → http://localhost:4000/swagger/swaggerui

La base PostgreSQL 16 est lancée automatiquement (volume `postgres_data` persistant), le backend attend qu'elle soit saine avant de démarrer.

---

## Développement sans Docker

### Backend (Phoenix / Elixir)

Pré-requis : **Elixir / Erlang** + **PostgreSQL**.

```bash
cd manager
mix deps.get
mix ecto.setup        # crée la base + migrations + seeds
mix phx.server        # API sur http://localhost:4000
```

### Frontend (Vue 3 / Vite)

Pré-requis : **Node ≥ 22.18**.

```bash
cd Frontend
npm install
npm run dev           # http://localhost:5173, proxy /api → :4000
```

Scripts : `npm run dev` (dev), `npm run build` (génère `dist/`), `npm run preview`.

---

## Variables d'environnement

| Variable          | Rôle                                                     | Dev            |
|-------------------|----------------------------------------------------------|----------------|
| `PGHOST`          | Hôte PostgreSQL                                          | `db`           |
| `PGPORT`          | Port PostgreSQL                                         | `5432`         |
| `PGUSER`          | Utilisateur DB                                          | `postgres`     |
| `PGPASSWORD`      | Mot de passe DB                                        | `postgres`     |
| `PGDATABASE`      | Nom de la base                                          | `manager_dev`  |
| `DATABASE_URL`    | (prod) prioritaire sur les `PG*`                        | —              |
| `SECRET_KEY_BASE` | (prod) secret Phoenix — `mix phx.gen.secret`            | —              |
| `PHX_HOST`        | (prod) hôte pour les URL générées (Swagger)             | —              |
| `COOKIE_SECURE`   | (prod) `true` pour forcer le cookie JWT en HTTPS        | —              |
| `VITE_API_URL`    | URL de l'API fixée **au build** du front (via CI)       | voir `.env.example` |

---

## Application mobile

L'app mobile (dossier `Mobile/`) est une **application Cordova (Android)** qui embarque la même interface Vue, adaptée au téléphone (navigation par **tab-bar** + écran « Plus »), avec gestion **hors-ligne** du pointage.

- **APK prête à installer** : [`Mobile/releases/time-manager.apk`](Mobile/releases/time-manager.apk)
- Build : `cd Mobile && npm install && npm run build` puis `cordova build android`.

> Sur le téléphone, autoriser l'installation depuis une source inconnue, puis ouvrir l'APK. L'app pointe vers l'API de production.

---

## Sécurité

L'app a fait l'objet d'un audit (pentest) — voir [`docs/RAPPORT_SECURITE.pdf`](docs/RAPPORT_SECURITE.pdf). Mesures en place :

- **JWT** signé (Joken) stocké dans un **cookie HttpOnly** → inaccessible au JavaScript.
- **Protection XSRF** : un token renvoyé à la connexion est envoyé dans l'en-tête `x-xsrf-token` à chaque requête ; le back vérifie la correspondance cookie ↔ en-tête.
- **Mots de passe** hachés avec **bcrypt** (`bcrypt_elixir`).
- **Rate-limiting** sur la connexion (anti-force-brute) → réponse **429** au-delà du seuil.
- **Contrôle d'accès par rôle** côté serveur (`AuthPlug` / `RolePlug`) — le garde `beforeEach` du front n'est qu'une première barrière UX.
- **HTTPS** en production (cookie `Secure` via `COOKIE_SECURE`).
- **CORS** maîtrisé (`corsica`).

> ⚠️ Pense à changer les mots de passe de démonstration avant toute mise en ligne.

---

## API & documentation

- Spécification **OpenAPI** via `open_api_spex`.
- **Swagger UI** : http://localhost:4000/swagger/swaggerui (en dev).

Principales routes (`/api`) : `/users/sign_in`, `/users/me`, `/users/:id`, `/users/:id/role`, `/teams`, `/clocks/:userID`, `/workingtime/:userID`, `/data`.

---

## Tests

```bash
cd manager
mix test
```

Le détail du stage de test et des cas couverts est dans [`docs/GUIDE_TEST.md`](docs/GUIDE_TEST.md).

---

## Production & déploiement

- `docker-compose.prod.yml` utilise les images publiées par **Travis CI** (backend en `MIX_ENV=prod`, frontend compilé et servi par **nginx** en HTTPS).
- Le `.env` du serveur doit contenir, en plus des `PG*` : `SECRET_KEY_BASE`, `PHX_HOST`, `COOKIE_SECURE=true`.
- L'URL de l'API utilisée par le front est fixée **au build** via `VITE_API_URL` (définie dans `.travis.yml`).

Déploiement (schéma) : push → Travis build + tests → images Docker → déploiement sur le serveur → `docker compose -f docker-compose.prod.yml up -d`.

> En cas d'erreur « no space left on device » au déploiement : `docker system prune -af` sur le serveur (conserve les volumes/DB nommés), puis relancer.

---

## Documentation du projet

| Document | Contenu |
|---|---|
| [`docs/FRONTEND_DETAIL.md`](docs/FRONTEND_DETAIL.md) | Explication du frontend **ligne par ligne, fichier par fichier** |
| [`docs/FRONTEND.md`](docs/FRONTEND.md) | Vue d'ensemble du frontend (tableaux récap) |
| [`docs/RAPPORT_SECURITE.pdf`](docs/RAPPORT_SECURITE.pdf) | Rapport de sécurité / pentest |
| [`docs/GUIDE_TEST.md`](docs/GUIDE_TEST.md) | Guide des tests backend |
| [`docs/CHANGE_RESISTANCE.pdf`](docs/CHANGE_RESISTANCE.pdf) | Cartographie des parties prenantes & besoins |
| [`docs/TESTS_MOBILE.md`](docs/TESTS_MOBILE.md) | Tests de l'application mobile |
| [`maquettes/`](maquettes/) | Maquettes web + mobile |

---

<p align="center"><sub>Time Manager · Ville de Gotham — Projet Master 1 (Epitech)</sub></p>
