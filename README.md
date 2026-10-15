# Time Manager · City of Gotham

> Working-time management for the Gotham City administration: clock-in, scheduling (night shifts & on-call), leave, validation, payroll and statistics — web **and** mobile.

A full-stack application built as part of the Piscine project (Master 1, Epitech). The "Gotham" theme wraps a real HR tool: clock in with one gesture, track your hours, manage night schedules, validate the monthly sheets and export payroll.

**Stack:** Vue 3 (Vite) · Phoenix / Elixir · PostgreSQL · Cordova (Android) · Docker · nginx

---

## Table of contents

- [Features](#features)
- [Architecture](#architecture)
- [Repository structure](#repository-structure)
- [Quick start (Docker)](#quick-start-docker)
- [Development without Docker](#development-without-docker)
- [Environment variables](#environment-variables)
- [Mobile application](#mobile-application)
- [Security](#security)
- [API & documentation](#api--documentation)
- [Tests](#tests)
- [Production & deployment](#production--deployment)
- [Project documentation](#project-documentation)

---

## Features

Three roles, each with its own space. The **administrator** can do everything (they also have access to the manager pages).

### Employee
- **Clock-in** with one gesture (in / out), with break, travel and an "Incident" button. Works offline (the clock-in is kept on the device). Kiosk mode: "Day matches the schedule" in one click.
- **Dashboard**: hours this week, days worked, latest sessions.
- **My times**: read-only view + **correction request** (the manager decides within 48 h, a refusal must be justified).
- **Schedule** published in advance (nights, on-call, rest), with a night counter and a cap.
- **Leave**: paid leave, sick leave, time-off in lieu — paperless.
- **Statistics**: personal, plus an estimated payslip. *No comparison between colleagues.*
- **Accessibility**: high contrast, enlarged text, voice readout, bilingual FR/EN — from the login screen.

### Manager / Team lead
- **Team**: overview (present, hours, overtime, nights), team management.
- **Alerts**: missed clock-out, too many nights, unusual duration, high overtime.
- **Validation**: corrections, overtime decisions (paid or recovered), monthly sheets.
- **Team schedule**: editable grid, night distribution, publishing, Bat-signal (on-call).
- **Team statistics** (per team or global).

### Administrator / HR
- **Users**: roles, fine-grained permissions, deletion, rights history.
- **Rules**: overtime thresholds, night window, breaks/travel, schedule notice period, etc.
- **Payroll**: regular hours / night x1.5 / overtime x2 / time-off in lieu, **CSV export** for accounting.
- **Leave (HR)**: approval of requests, global team calendar.

---

## Architecture

```
  Browser / APK                  nginx (prod)              Phoenix API            PostgreSQL
 ┌───────────────┐   HTTPS   ┌──────────────────┐   /api   ┌──────────────┐   SQL   ┌──────────┐
 │  Vue 3 (SPA)  │ ────────▶ │  serves build +  │ ───────▶ │  Elixir /    │ ──────▶ │  Postgres│
 │  Vite build   │           │  proxies /api    │          │  Ecto        │         │          │
 └───────────────┘           └──────────────────┘          └──────────────┘         └──────────┘
```

- The frontend calls the API via a **relative path** `/api` → it follows the current domain (the nginx proxy forwards to the back end).
- Authentication with a **JWT** in an **HttpOnly cookie** + an **XSRF token** in a header (see [Security](#security)).
- Shared state is synchronized through `/api/data` (rules, schedule, leave, corrections, etc.).

---

## Repository structure

```
TIME-MANAGER/
├── Frontend/            Web application — Vue 3 + Vite + Tailwind v4
│   └── src/             components/, router/, store.js, api.js, session.js, i18n.js, utils/
├── manager/             API — Phoenix / Elixir + Ecto (PostgreSQL)
│   ├── lib/             controllers, plugs (Auth, Role, RateLimit), schemas
│   ├── config/          dev.exs, prod.exs, runtime.exs, test.exs
│   └── Dockerfile
├── Mobile/              Mobile application — Cordova (Android) embedding the front end
│   └── releases/        time-manager.apk (ready-to-install build)
├── maquettes/           Mockups (web + mobile) and PNG preview
├── docs/                Reports & documentation (see below)
├── docker-compose.yml           Dev environment (db + back + front)
├── docker-compose.prod.yml      Production environment
├── .travis.yml          CI/CD (build images + deploy)
└── README.md
```

---

## Quick start (Docker)

Requirements: **Docker** + **Docker Compose**.

1. Create a `.env` file at the root:

   ```env
   PGHOST=db
   PGPORT=5432
   PGUSER=postgres
   PGPASSWORD=postgres
   PGDATABASE=manager_dev
   ```

2. Start everything:

   ```bash
   docker compose up --build
   ```

3. Access:
   - **Frontend** → http://localhost:5174
   - **API** → http://localhost:4000/api
   - **Swagger** → http://localhost:4000/swagger/swaggerui

PostgreSQL 16 is started automatically (persistent `postgres_data` volume); the back end waits until the database is healthy before starting.

---

## Development without Docker

### Back end (Phoenix / Elixir)

Requirements: **Elixir / Erlang** + **PostgreSQL**.

```bash
cd manager
mix deps.get
mix ecto.setup        # creates the database + migrations + seeds
mix phx.server        # API on http://localhost:4000
```

### Front end (Vue 3 / Vite)

Requirements: **Node >= 22.18**.

```bash
cd Frontend
npm install
npm run dev           # http://localhost:5173, proxies /api -> :4000
```

Scripts: `npm run dev` (dev), `npm run build` (generates `dist/`), `npm run preview`.

---

## Environment variables

| Variable          | Role                                                     | Dev            |
|-------------------|----------------------------------------------------------|----------------|
| `PGHOST`          | PostgreSQL host                                          | `db`           |
| `PGPORT`          | PostgreSQL port                                          | `5432`         |
| `PGUSER`          | DB user                                                  | `postgres`     |
| `PGPASSWORD`      | DB password                                              | `postgres`     |
| `PGDATABASE`      | Database name                                            | `manager_dev`  |
| `DATABASE_URL`    | (prod) takes precedence over the `PG*` variables         | —              |
| `SECRET_KEY_BASE` | (prod) Phoenix secret — `mix phx.gen.secret`             | —              |
| `PHX_HOST`        | (prod) host used for generated URLs (Swagger)            | —              |
| `COOKIE_SECURE`   | (prod) `true` to force the JWT cookie over HTTPS         | —              |
| `VITE_API_URL`    | API URL fixed **at build time** of the front (via CI)    | see `.env.example` |

---

## Mobile application

The mobile app (`Mobile/` folder) is a **Cordova (Android) application** that embeds the same Vue interface, adapted for phones (bottom **tab-bar** navigation + a "More" screen), with **offline** clock-in handling.

- **Ready-to-install APK**: [`Mobile/releases/time-manager.apk`](Mobile/releases/time-manager.apk)
- Build: `cd Mobile && npm install && npm run build` then `cordova build android`.

> On the phone, allow installation from an unknown source, then open the APK. The app points to the production API.

---

## Security

The app underwent a security audit (pentest) — see [`docs/RAPPORT_SECURITE.pdf`](docs/RAPPORT_SECURITE.pdf). Measures in place:

- **JWT** signed (Joken), stored in an **HttpOnly cookie** → not readable by JavaScript.
- **XSRF protection**: a token returned at login is sent in the `x-xsrf-token` header on every request; the back end checks the cookie / header match.
- **Passwords** hashed with **bcrypt** (`bcrypt_elixir`).
- **Rate-limiting** on login (anti brute-force) → **429** response past the threshold.
- **Role-based access control** on the server (`AuthPlug` / `RolePlug`) — the front-end `beforeEach` guard is only a first UX barrier.
- **HTTPS** in production (`Secure` cookie via `COOKIE_SECURE`).
- **CORS** controlled (`corsica`).

> Note: remember to change the demo passwords before going live.

---

## API & documentation

- **OpenAPI** specification via `open_api_spex`.
- **Swagger UI**: http://localhost:4000/swagger/swaggerui (in dev).

Main routes (`/api`): `/users/sign_in`, `/users/me`, `/users/:id`, `/users/:id/role`, `/teams`, `/clocks/:userID`, `/workingtime/:userID`, `/data`.

---

## Tests

```bash
cd manager
mix test
```

Details of the test stage and the covered cases are in [`docs/GUIDE_TEST.md`](docs/GUIDE_TEST.md).

---

## Production & deployment

- `docker-compose.prod.yml` uses the images published by **Travis CI** (back end in `MIX_ENV=prod`, front end built and served by **nginx** over HTTPS).
- The server `.env` must contain, in addition to the `PG*` variables: `SECRET_KEY_BASE`, `PHX_HOST`, `COOKIE_SECURE=true`.
- The API URL used by the front end is fixed **at build time** via `VITE_API_URL` (defined in `.travis.yml`).

Deployment (overview): push → Travis build + tests → Docker images → deploy to the server → `docker compose -f docker-compose.prod.yml up -d`.

> Note: if deployment fails with "no space left on device", run `docker system prune -af` on the server (keeps named volumes/DB), then restart.

---

## Project documentation

| Document | Content |
|---|---|
| [`docs/FRONTEND_DETAIL.md`](docs/FRONTEND_DETAIL.md) | Frontend explained **line by line, file by file** |
| [`docs/FRONTEND.md`](docs/FRONTEND.md) | Frontend overview (summary tables) |
| [`docs/RAPPORT_SECURITE.pdf`](docs/RAPPORT_SECURITE.pdf) | Security / pentest report |
| [`docs/GUIDE_TEST.md`](docs/GUIDE_TEST.md) | Back-end test guide |
| [`docs/CHANGE_RESISTANCE.pdf`](docs/CHANGE_RESISTANCE.pdf) | Stakeholder mapping & needs |
| [`docs/TESTS_MOBILE.md`](docs/TESTS_MOBILE.md) | Mobile application tests |
| [`maquettes/`](maquettes/) | Web + mobile mockups |

---

<p align="center"><sub>Time Manager · City of Gotham — Master 1 project (Epitech)</sub></p>
