# TIME-MANAGER
Pool Project on Elixir

## Structure

- `manager/` : API Phoenix (Elixir) + PostgreSQL — doc Swagger sur `/swagger/swaggerui`
- `Frontend/` : application Vue 3 (Vite)

## Lancer en local (Docker)

Créer un fichier `.env` à la racine :

```
PGHOST=db
PGPORT=5432
PGUSER=postgres
PGPASSWORD=postgres
PGDATABASE=manager_dev
```

Puis `docker compose up --build`. L'API répond sur `http://localhost:4000/api`,
le frontend sur `http://localhost:5174`.

## Production

`docker-compose.prod.yml` utilise les images publiées par Travis
(backend en `MIX_ENV=prod`, frontend compilé et servi par nginx).

Le `.env` du serveur doit contenir, en plus des variables `PG*` :

```
SECRET_KEY_BASE=...   # généré avec `mix phx.gen.secret`
PHX_HOST=92.4.131.118 # optionnel, utilisé pour les URL générées (Swagger)
```

L'URL de l'API utilisée par le frontend est fixée au build via `VITE_API_URL`
(définie dans `.travis.yml`, voir `Frontend/.env.example` pour le local).

## Tests

```
cd manager && mix test
```
