# Time Manager · Guide de test complet

Ce guide permet de tester toute l'application, rôle par rôle, avec des données de démonstration prêtes à l'emploi.
Compter environ 30 minutes.

---

## 1. Préparer l'environnement

### Backend (dossier `manager/`)

```bash
mix deps.get
mix ecto.migrate                     # crée / met à jour les tables
mix run priv/repo/seeds.exs          # rôles Administrator, Manager, Employee
mix run priv/repo/demo_data.exs      # comptes et données de démo (relançable à volonté)
mix phx.server                       # API sur http://localhost:4000
```

Base PostgreSQL attendue : `postgres` / `postgres`, base `manager_dev` (voir le README).

### Frontend (dossier `Frontend/`)

```bash
npm install
npm run dev -- --port 5174           # application sur http://localhost:5174
```

Le front appelle l'API par `/api` : Vite relaie ces appels vers `localhost:4000`.
Le front et l'API ont donc la même adresse, ce qui permet au cookie JWT (HttpOnly) de passer.

> Le planning, les absences, les demandes de correction, les justifications, les décisions sur les heures sup et les règles sont enregistrés dans l'API (`GET /api/data`, `PUT /api/data/:key`).
> On peut donc tester avec plusieurs navigateurs ou plusieurs appareils en même temps : par exemple l'employé sur un téléphone et le manager sur un PC.
> Les pages se mettent à jour à chaque changement de page, et toutes les 15 secondes.

---

## 2. Comptes de démonstration

Mot de passe de tous les comptes : **`Gotham2026!`**

| Rôle | Email | Ce qu'il voit |
|---|---|---|
| Administrateur / RH | `albert@gotham.gov` | Section Administrateur / RH ; arrive sur Utilisateurs |
| Manager | `gordon@gotham.gov` | Section Manager ; arrive sur Équipe (équipe « Brigade de nuit ») |
| Employé | `john.doe@gotham.gov` | Section Employé ; arrive sur le Dashboard |
| Employé | `selina.kyle@gotham.gov` | Section Employé |
| Employé | `renee.montoya@gotham.gov` | Section Employé |
| Employé hors équipe | `harvey.dent@gotham.gov` | Section Employé (sert à tester l'ajout dans une équipe) |

### Ce que contiennent les données

Le script crée environ 3 semaines de pointages, calculées à partir du jour où il est lancé :

| Agent | Situation préparée | Où la voir |
|---|---|---|
| John Doe | Journées 08:00–16:30, une nuit le mercredi. **Arrivée pointée hier à 20:00, jamais de sortie.** | Alerte « Pointage de sortie oublié », pointage « En cours » |
| Selina Kyle | Agent de nuit, **3 nuits d'affilée en début de mois** | Alerte « Trop de nuits », compteur de nuits |
| Renee Montoya | Longues journées, **une journée de 16 h hier** | Alerte « Durée inhabituelle », heures sup dans Validation et Paie |
| Harvey Dent | Journées régulières, **dans aucune équipe** | Ajout et retrait d'un membre |
| Jim Gordon | Manager de « Brigade de nuit » | Pages Manager |

---

## 3. Parcours de test (dans cet ordre)

L'ordre compte : le manager publie le planning avant que l'employé s'en serve, puis il traite ce que l'employé a envoyé.

### Étape 0 · Page de connexion (sans compte)

| # | Action | Résultat attendu |
|---|---|---|
| 0.1 | Ouvrir `http://localhost:5174` | Redirection vers `/sign_in` (page privée) |
| 0.2 | Ouvrir `/sign_up` | Redirection vers `/sign_in` : il n'y a pas d'inscription, seul l'administrateur crée les comptes |
| 0.3 | Se connecter avec un mauvais mot de passe | Message « Email ou mot de passe incorrect », on reste sur `/sign_in` |
| 0.4 | Cliquer sur l'œil du mot de passe | Le mot de passe s'affiche, puis se masque |
| 0.5 | Cliquer sur « Mot de passe oublié ? » | Message : contacter l'administrateur ou les RH |
| 0.6 | Cliquer sur « Contraste élevé » et « Texte A+ » | Textes plus foncés, tout grossit ; le réglage reste après rechargement |
| 0.7 | Cliquer sur « Lecture vocale », puis sur un champ avec Tab | Le navigateur lit le champ à voix haute |
| 0.8 | Cliquer sur « Première connexion ? Suivre le tutoriel » | 4 étapes, avec Précédent et Suivant |

Remettre Contraste et Texte A+ à zéro avant de continuer.

### Étape 1 · Manager : publier le planning (`gordon@gotham.gov`)

| # | Action | Résultat attendu |
|---|---|---|
| 1.1 | Se connecter | Arrivée sur **Équipe** ; le menu ne montre que la section **Manager** |
| 1.2 | **Planning** ; revenir à la semaine en cours avec la flèche ← | Tableau des 3 agents de l'équipe |
| 1.3 | Pour John Doe : « Jour » sur aujourd'hui et sur les jours de semaine | Les menus se colorent |
| 1.4 | Pour Selina : « Nuit » trois jours de suite, puis « Jour » le lendemain | Avertissements en rouge : « plus de 2 nuits d'affilée » et « pas de repos après la nuit » |
| 1.5 | Mettre « Astr. » à quelqu'un aujourd'hui | — |
| 1.6 | Cliquer sur **Publier** | « publié le … » ; avertissement si on publie moins de 14 jours avant (règle) |
| 1.7 | Bat-signal : saisir « Narrows », cliquer sur **Déclencher**, puis sur **Mobiliser l'équipe d'astreinte** | Le signal passe à « Actif », et l'agent d'astreinte du jour est listé |
| 1.8 | Se déconnecter | Retour sur `/sign_in` |

### Étape 2 · Employé (`john.doe@gotham.gov`)

| # | Action | Résultat attendu |
|---|---|---|
| 2.1 | Se connecter | Arrivée sur le **Dashboard** ; le menu ne montre que la section **Employé** |
| 2.2 | **Dashboard** | Chiffres de la semaine, carte de pointage « En cours » (session ouverte hier) |
| 2.3 | **Pointage** → **Pointer la sortie** | La session se ferme, et la carte passe à « Pas pointé » |
| 2.4 | **Pointer l'arrivée**, puis **Pause**, puis **Reprendre** | Pastille « En pause », puis retour à « En cours » |
| 2.5 | **Incident** : écrire « Route bloquée par Batman », puis **Envoyer au manager** | « Incident envoyé à ton manager » |
| 2.6 | **Trajet** | « Trajet déclaré à ton manager » |
| 2.7 | **Journée conforme au planning** | Un temps de travail 08:00–16:00 est créé pour aujourd'hui (grâce au planning de l'étape 1) |
| 2.8 | **Mes temps** : choisir une session, heure « 17:30 », motif « Réunion prolongée », puis **Envoyer la demande** | Statut « Correction en attente » ; compteur Corrections = 1 |
| 2.9 | **Planning** | La semaine publiée en 1.6 s'affiche avec ses compteurs |
| 2.10 | **Absences** → **Demander un congé** (2 jours), puis **Envoyer** | Demande « En attente » ; refus si plus de jours que le solde |
| 2.11 | **Statistiques** | 4 graphiques dont le type se change, et la fiche de paie estimée |
| 2.12 | Taper `/equipe`, `/utilisateurs`, `/paie` dans la barre d'adresse | Renvoyé vers `/` à chaque fois : pages réservées |
| 2.13 | Taper `/workingTimes/<id d'un collègue>` | Renvoyé vers `/` : un employé ne voit que ses données |
| 2.14 | Se déconnecter | Retour sur `/sign_in`, et le `localStorage` ne contient plus le jeton |

### Étape 3 · Manager : traiter (`gordon@gotham.gov`)

| # | Action | Résultat attendu |
|---|---|---|
| 3.1 | **Équipe** | Présents, heures, heures sup, nuits ; **l'incident et le trajet de John** dans « Justifications reçues » |
| 3.2 | « Gérer les équipes » : ajouter **harvey_dent** à « Brigade de nuit » | Harvey apparaît dans l'équipe |
| 3.3 | Cliquer sur le × à côté de harvey_dent | Harvey est retiré |
| 3.4 | Créer une équipe « Patrouille Est » | L'équipe apparaît, avec Gordon comme manager |
| 3.5 | **Alertes** | Alertes « Trop de nuits · selina_kyle » et « Durée inhabituelle · renee_montoya » (et « sortie oubliée » si l'étape 2.3 n'a pas été faite) |
| 3.6 | Sur une alerte « Durée inhabituelle » : **Valider** | L'alerte disparaît |
| 3.7 | **Validation** → demande de John → **Accepter** | Le temps de travail passe à 17:30 dans l'API |
| 3.8 | Heures sup de Renee → **À récupérer** | La décision est enregistrée, et le solde « À récupérer » de Renee augmente |
| 3.9 | **Tout valider** | Les feuilles passent à « Validé » ; une nouvelle correction sur ce mois devient impossible |
| 3.10 | **Pointage d'équipe** | Arrivée pointée pour tous les absents (le bouton devient « Sortie d'équipe ») |
| 3.11 | Choisir un agent, puis **Ajouter un temps** | Formulaire de création d'un temps de travail (réservé au manager) |
| 3.12 | **Statistiques** | Graphiques de l'équipe ; un clic sur un agent ouvre ses statistiques |
| 3.13 | Taper `/utilisateurs`, `/`, `/absences` | Renvoyé vers `/equipe` : pages d'un autre rôle. Seuls les temps et statistiques d'un agent (`/workingTimes/<id>`, `/chartManager/<id>`) restent ouverts au manager |
| 3.14 | Se déconnecter | — |

### Étape 4 · Employé : vérifier les retours (`john.doe@gotham.gov`)

| # | Action | Résultat attendu |
|---|---|---|
| 4.1 | **Mes temps** | Session marquée « Corrigée par jim_gordon », et l'historique indique la sortie fixée à 17:30 |
| 4.2 | Se déconnecter | — |

### Étape 5 · Administrateur / RH (`albert@gotham.gov`)

| # | Action | Résultat attendu |
|---|---|---|
| 5.1 | Se connecter | Arrivée sur **Utilisateurs** ; le menu ne montre que la section **Administrateur / RH**. Taper `/equipe` ou `/` renvoie vers `/utilisateurs` |
| 5.2 | **Utilisateurs** → **Ajouter un utilisateur** (nom, email, mot de passe d'au moins 8 caractères) | Le compte apparaît dans la liste ; il peut se connecter |
| 5.3 | Rôle de john_doe : **Manager**, puis **Employé** | Rôle changé dans l'API ; les deux changements apparaissent dans « Historique des droits » |
| 5.4 | Retirer le droit « Modifier le planning » à jim_gordon | Ligne ajoutée à l'historique |
| 5.5 | Vérifier qu'aucun menu ne permet de nommer un administrateur | Les administrateurs affichent un rôle fixe (l'API refuse cette promotion) |
| 5.6 | **Règles** → seuil hebdomadaire à **1 h** | Se reconnecter en manager → **Alertes** : des alertes « Heures sup élevées » apparaissent. **Remettre ensuite 40 h** avec l'administrateur |
| 5.7 | **Paie** | Heures normales, nuit, heures sup payées et récupération de chaque agent |
| 5.8 | **Exporter pour la comptabilité** | Téléchargement de `paie-AAAA-MM.csv` |
| 5.9 | **Absences** (RH) | Le congé de John (étape 2.10) → **Valider** ; il apparaît dans le calendrier du mois |
| 5.10 | Se déconnecter | — |

---

## 4. Vérifications de sécurité (thème 5, Authentification)

À faire avec les outils de développement du navigateur (F12).

| # | Vérification | Où regarder | Attendu |
|---|---|---|---|
| S.1 | Après connexion, le Web Storage contient `xsrfToken`, `userId` et `role` | Application → Local Storage | Le jeton XSRF fait 50 caractères |
| S.2 | Le JWT n'est **pas** lisible par le front | Application → Cookies | Cookie `time_manager_token` marqué **HttpOnly** ; absent du Local Storage |
| S.3 | Chaque requête envoie l'en-tête `x-xsrf-token` | Réseau → une requête `/api/...` → En-têtes | `x-xsrf-token: <le jeton>` |
| S.4 | Une requête sans cet en-tête est refusée | Console : `fetch('/api/users/me').then(r => r.status)` | `403` |
| S.5 | Session expirée | Supprimer le cookie `time_manager_token`, puis changer de page | Retour automatique sur `/sign_in` et `localStorage` vidé |
| S.6 | Déconnexion | Bouton « Se déconnecter » | Appel `POST /api/users/sign_out`, cookie supprimé, `localStorage` vidé |
| S.7 | Routes protégées par `beforeEach` | Taper les adresses à la main | Publique : `/sign_in`. Employé : `/`, `/clock/...`, `/planning`, `/absences`. Employé et manager : `/workingTimes/...`, `/chartManager/...`. Manager : `/equipe`, `/alertes`, `/validation`, `/planning-equipe`, `/statistiques-equipe`, `/workingTime/...`. Administration : `/utilisateurs`, `/regles`, `/paie`, `/absences-rh`. Une page d'un autre rôle renvoie vers la page d'accueil du rôle |
| S.8 | Fonctions masquées par `v-if` (jamais `v-show`) | Inspecter le menu d'un employé | Les liens Manager et Admin ne sont pas dans le HTML |

---

## 5. Remettre à zéro

- Relancer `mix run priv/repo/demo_data.exs` : les comptes de démo et leurs pointages sont recréés, et les données partagées (planning, absences, corrections, justificatifs, règles…) sont effacées.

---

## 6. Limites connues

| Sujet | État |
|---|---|
| Mot de passe envoyé en clair | Le bootstrap du thème 5 demande de ne jamais l'envoyer en clair. Le hacher dans le front demande une décision commune avec le back, sinon les comptes existants ne peuvent plus se connecter. **À trancher en équipe.** |
| Heure des pointages | L'API enregistre l'heure du serveur (UTC), ce qui donne un décalage d'une heure en France. Un correctif côté back (utiliser l'heure envoyée par le front) est prêt dans un stash de la branche `DevOpsCi-Cd`. |
| Nommer un administrateur | Impossible depuis l'API, par choix de sécurité : seuls Employé et Manager s'attribuent. |
| Inscription | Pas de page `/sign_up` : l'administrateur crée les comptes, à la demande de la direction (contrôle des droits). |
