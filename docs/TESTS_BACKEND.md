# Tests du back-end

Les tests sont dans `manager/test/`. Ils vérifient automatiquement que l'API fonctionne, sans avoir à cliquer dans l'application.

## Lancer les tests

En local (Postgres doit tourner) :

```bash
cd manager
MIX_ENV=test mix test
```

Résultat attendu : `55 tests, 0 failures`.

Sur Travis, le stage **Test** lance les mêmes tests dans Docker, avec une base Postgres neuve. Si un test échoue, l'image n'est pas construite et rien n'est déployé.

## Comment ça marche

### La base de test

- Les tests utilisent une base séparée, `manager_test`. Ils ne touchent jamais aux vraies données.
- Avant chaque lancement, `mix test` crée la base si besoin et applique les migrations.
- Chaque test tourne dans une **transaction annulée à la fin** (le « sandbox » d'Ecto). Un test ne voit donc jamais les données d'un autre test.

### Les fichiers d'aide (`test/support/` et `test/test_helper.exs`)

| Fichier | Rôle |
|---|---|
| `test_helper.exs` | Démarre les tests et crée les 3 rôles (Administrator, Manager, Employee). Sans eux, impossible de créer un utilisateur sur une base neuve. |
| `support/data_case.ex` | Base des tests qui appellent directement les fonctions du back (sans HTTP). |
| `support/conn_case.ex` | Base des tests qui envoient de vraies requêtes HTTP à l'API. |
| `support/fixtures/` | Fonctions qui créent rapidement des données de test : `user_fixture()`, `clock_fixture(user_id)`, `working_time_fixture(user_id)`. |

### La connexion dans les tests HTTP

Toutes les routes de l'API demandent d'être connecté. `conn_case.ex` fait donc la même chose que le front :

- **`log_in(conn, user_id, role)`** fabrique un JWT, le met dans le cookie `time_manager_token`, et envoie le token XSRF dans l'en-tête `x-xsrf-token`. Par défaut, chaque test est connecté en **Administrator**, qui a accès à tout.
- **`again(conn)`** sert quand un test enchaîne deux requêtes (par exemple : créer, puis relire). Il garde le cookie et l'en-tête XSRF pour la requête suivante.

## Ce qui est testé

### 1. Utilisateurs — `manager/account_test.exs` (11 tests)

Teste les fonctions de `Account`, sans passer par HTTP.

| Test | Ce qu'il vérifie |
|---|---|
| `list_users/0` | Renvoie tous les utilisateurs. |
| `list_users/1` | Filtre par email et par nom ; aucun résultat si les deux ne correspondent pas. |
| `get_user/1` | Renvoie l'utilisateur, ou `nil` s'il n'existe pas. |
| `create_user/1` valide | Crée l'utilisateur avec les bonnes valeurs. |
| `create_user/1` invalide | Refuse un nom ou un email vide. |
| Email mal formé | Refuse un email sans `@`. |
| Email en double | Refuse deux comptes avec le même email. |
| `update_user/2` valide / invalide | Modifie l'utilisateur, ou refuse des données vides. |
| `delete_user/1` | Supprime l'utilisateur **et** ses pointages et temps de travail. |
| `change_user/1` | Renvoie un formulaire (changeset) Ecto. |

### 2. Pointages — `manager/attendance_test.exs` (11 tests)

| Test | Ce qu'il vérifie |
|---|---|
| `list_clocks/1` | Renvoie seulement les pointages de l'utilisateur, **triés par heure**. |
| `get_clock!/1` | Renvoie le bon pointage. |
| Premier pointage | C'est une **arrivée** (`status: true`). |
| Pointages suivants | Alternent arrivée / sortie. |
| Heure envoyée par le front | L'heure enregistrée est celle envoyée, pas celle du serveur (évite le décalage UTC). |
| Arrivée seule | Ne crée **pas** de temps de travail. |
| Sortie | Crée un temps de travail de l'heure d'arrivée à l'heure de sortie. |
| `update_clock/2` invalide | Refuse des données invalides. |
| `delete_clock/1` | Supprime le pointage. |
| `change_clock/1` | Renvoie un changeset. |

### 3. Temps de travail — `manager/work_duration_test.exs` (9 tests)

| Test | Ce qu'il vérifie |
|---|---|
| Liste d'un utilisateur | Ne renvoie que ses temps de travail. |
| Filtre `start` / `end` | Ne garde que les temps dans la période demandée. |
| Lecture | Vérifie que le temps appartient bien à l'utilisateur demandé. |
| Création valide | Crée le temps de travail. |
| Champs manquants | Refusés. |
| Fin avant le début | Refusée. |
| Utilisateur inconnu | Refusé. |
| Modification / suppression | Fonctionnent. |

### 4. API des utilisateurs — `manager_web/controllers/user_controller_test.exs` (10 tests)

Envoie de vraies requêtes HTTP sur `/api/users`.

| Requête | Ce qui est vérifié |
|---|---|
| `GET /api/users` | Liste tous les utilisateurs, avec filtres email / nom. |
| `POST /api/users` | Crée un utilisateur (201) puis le relit ; renvoie 422 si les données sont invalides. |
| `GET /api/users/:id` | Renvoie 404 si l'utilisateur n'existe pas. |
| `PUT /api/users/:id` | Modifie l'utilisateur (200) ; 422 si invalide. |
| `DELETE /api/users/:id` | Supprime (204), puis la relecture renvoie 404 ; marche aussi s'il a des pointages et des temps de travail. |

### 5. API des temps de travail — `manager_web/controllers/working_time_controller_test.exs` (8 tests)

| Requête | Ce qui est vérifié |
|---|---|
| `GET /api/workingtime/:userID` | Liste les temps de l'utilisateur, avec filtre par dates. |
| `POST /api/workingtime/:userID` | Crée un temps (201) ; 422 si la fin est avant le début. |
| `GET /api/workingtime/:userID/:id` | 404 si le temps appartient à un autre utilisateur. |
| `PUT /api/workingtime/:id` | Modifie (200) ; 422 si invalide. |
| `DELETE /api/workingtime/:id` | Supprime (204), puis la relecture renvoie 404. |

### 6. API des pointages — `manager_web/controllers/clock_controller_test.exs` (5 tests)

| Requête | Ce qui est vérifié |
|---|---|
| `GET /api/clocks/:userID` | Liste les pointages ; 404 si l'utilisateur n'existe pas. |
| `POST /api/clocks/:userID` | Crée une arrivée, au format `AAAA-MM-JJ hh:mm:ss`. |
| Arrivée puis sortie | Avec les heures envoyées par le front : un temps de travail est créé avec ces heures exactes. |
| Utilisateur inconnu | 404. |

### 7. Erreurs — `manager_web/controllers/error_json_test.exs` (2 tests)

Vérifie que les erreurs 404 et 500 renvoient bien un JSON (`{"errors": {"detail": ...}}`).

## Ajouter un test

Exemple dans un fichier de `manager_web/controllers/` :

```elixir
test "le manager ne peut pas changer un rôle" do
  user = user_fixture()
  conn = log_in(build_conn(), 0, "Manager")
  conn = put(conn, ~p"/api/users/#{user.id}/role", role: "Administrator")
  assert json_response(conn, 403)
end
```

- `log_in(..., "Manager")` connecte la requête avec un autre rôle que l'administrateur.
- `assert` fait échouer le test si la condition est fausse.

## Ce qui n'est pas encore testé

- Les droits par rôle (un employé ou un manager qui appelle une route interdite).
- La connexion elle-même (`/api/users/sign_in`, `/sign_out`) et le refus d'un mauvais token XSRF.
- Les équipes (`/api/teams`) et les données partagées (`/api/data`).
