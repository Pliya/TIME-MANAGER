# Tests de l'application mobile

L'application mobile (`Mobile/`) est une application **Cordova + Vue 3** pour Android. Elle affiche **les mêmes vues que le web** : elles sont importées directement depuis `Frontend/src`, sans copie et sans modifier `Frontend/`.

Les tests du mobile se font **à la main**, sur l'émulateur Android **ou sur un vrai téléphone**, en suivant les scénarios ci-dessous. Chaque scénario donne les actions à faire et le résultat attendu. Compter environ 40 minutes.

---

## 1. Préparer l'environnement

### L'API et les données de démonstration

```bash
docker-compose up -d --build        # ou "docker compose up -d --build", selon la version de Docker
docker exec time_manager_backend mix run priv/repo/demo_data.exs   # comptes de démo (voir GUIDE_TEST.md)
curl -i http://localhost:4000/api/users/me                          # doit répondre 401 : l'API tourne
```

Avant de tester le mobile, vérifier que le backend passe ses tests (dont les 4 tests de la connexion mobile) :

```bash
docker exec -e MIX_ENV=test -e DB_HOST=db time_manager_backend mix test   # attendu : 59 tests, 0 failures
```

Les comptes de démonstration sont décrits dans `GUIDE_TEST.md` (mot de passe : **`Gotham2026!`**) :

| Rôle | Email | Page d'accueil sur le mobile |
|---|---|---|
| Employé | `john.doe@gotham.gov` | Pointage |
| Manager | `gordon@gotham.gov` | Équipe |
| Administrateur / RH | `albert@gotham.gov` | Utilisateurs |

### L'émulateur

L'émulateur doit être en **Android 9 (API 28)**, comme demandé dans le bootstrap.

```bash
emulator -avd tm28 &              # 1. démarrer l'émulateur et attendre l'écran d'accueil
adb devices                       # 2. doit afficher "emulator-XXXX   device"
adb reverse tcp:4000 tcp:4000     # 3. tunnel vers l'API (voir ci-dessous)
cd Mobile
npm install
npm run build                     # 4. génère www/ (à refaire après chaque changement de code)
cordova run android               # 5. installe et lance l'application
```

**Pourquoi `adb reverse` ?** Pour l'émulateur, `localhost` désigne le téléphone lui-même. Cette commande relie le port 4000 du téléphone au port 4000 du PC, où tourne l'API. L'application et l'API restent ainsi toutes les deux sur `localhost`, ce qui permet au cookie de connexion (JWT) de passer. Le tunnel disparaît quand l'émulateur redémarre : il faut alors relancer la commande.

**Si quelque chose ne marche pas :**

| Symptôme | Cause | Solution |
|---|---|---|
| `adb: no devices/emulators found` | L'émulateur n'est pas encore démarré | Attendre l'écran d'accueil, puis relancer `adb reverse` |
| « Impossible de charger… » sur toutes les pages | Le tunnel n'est pas actif | `adb reverse --list` doit afficher `tcp:4000 tcp:4000` |
| Une modification du code n'apparaît pas | `www/` n'a pas été reconstruit | `npm run build` avant `cordova run android` |
| `MISSING_EXPORT` pendant le build | Un nom a changé dans `Frontend/` | Voir la section 2, « Les copies à garder à jour » |

### Sur un vrai téléphone, sans câble (en Wi-Fi)

Le téléphone utilise l'API qui tourne sur le PC. Le PC et le téléphone doivent être **sur le même Wi-Fi**.

**1. Trouver l'adresse du PC sur le Wi-Fi**

```bash
hostname -I
```

Prendre la première adresse, du type `192.168.x.x` (dans la suite : `IP_DU_PC`). Les adresses en `172.17…` ou `172.21…` sont les réseaux internes de Docker : ne pas les utiliser.

**2. Vérifier que le téléphone voit l'API**

Sur le téléphone, ouvrir Chrome à l'adresse `http://IP_DU_PC:4000/api/users/me`. La page doit afficher :

```
{"errors":{"detail":"Authentification requise."}}
```

Si la page ne charge pas, ouvrir le port dans le pare-feu du PC (Fedora) : `sudo firewall-cmd --add-port=4000/tcp`.

**3. Construire l'APK avec l'adresse du PC**

```bash
cd Mobile
VITE_API_URL=http://IP_DU_PC:4000/api npm run build
cordova build android
```

L'APK de test est créé ici : `Mobile/platforms/android/app/build/outputs/apk/debug/app-debug.apk`.

**4. Mettre l'APK sur le téléphone**

Le plus simple est de le télécharger depuis le PC, puisque le téléphone le voit déjà :

```bash
cp platforms/android/app/build/outputs/apk/debug/app-debug.apk ~/time-manager.apk
cd ~
sudo firewall-cmd --add-port=8000/tcp
python3 -m http.server 8000
```

Sur le téléphone, ouvrir `http://IP_DU_PC:8000/time-manager.apk` dans Chrome, puis ouvrir le fichier téléchargé et **autoriser l'installation depuis des sources inconnues**. Arrêter ensuite le serveur avec `Ctrl + C` et refermer le port : `sudo firewall-cmd --remove-port=8000/tcp`.

Autres façons de transférer l'APK : Google Drive, ou WhatsApp en l'envoyant comme *document*. Gmail bloque les fichiers `.apk`.

**5. Se connecter** avec un compte de démonstration, puis suivre les scénarios de la section 4. Pour couper le réseau, désactiver **le Wi-Fi et les données mobiles** (ou activer le mode avion).

### Autres façons de tester sur un téléphone

| Méthode | Commandes | Quand l'utiliser |
|---|---|---|
| **Câble USB** | Activer le « débogage USB » sur le téléphone, puis `adb reverse tcp:4000 tcp:4000`, `npm run build`, `cordova run android --device` | Pas de Wi-Fi commun ; même fonctionnement que l'émulateur |
| **Serveur déployé** | `npm run build`, puis `cordova build android` | Pour que chacun installe l'APK sans le PC. `npm run build` cible automatiquement `https://gotham-manager.duckdns.org/api` (voir `.env.production`). Le serveur doit avoir le HTTPS en place et la version du backend avec la connexion mobile. |

**Pour tester en local** (émulateur avec `adb reverse`, ou PC sur le même Wi-Fi), construire en forçant l'adresse locale, sinon l'app appellera le serveur déployé :
`VITE_API_URL=http://localhost:4000/api npm run build` (ou l'IP du PC à la place de `localhost`).

### Si quelque chose ne marche pas sur le téléphone

| Symptôme | Cause | Solution |
|---|---|---|
| L'étape 2 ne charge pas sur le téléphone | Le pare-feu du PC bloque le port 4000, ou le téléphone n'est pas sur le même Wi-Fi | `sudo firewall-cmd --add-port=4000/tcp` ; vérifier le Wi-Fi du téléphone |
| `adb install` installe sur l'émulateur, pas sur le téléphone | `adb` envoie vers l'émulateur s'il est ouvert | `adb devices`, puis `adb -s <numéro du téléphone> install -r …/app-debug.apk` |
| Connexion réussie, puis « Authentification requise » partout | Le backend n'a pas la connexion mobile (en-tête `Authorization`) | Reconstruire le backend (`docker-compose up -d --build`) ; vérifier que `mix test` passe |
| L'application ne joint plus l'API après un redémarrage de la box | L'adresse du PC a changé | `hostname -I`, puis reconstruire l'APK avec la nouvelle adresse |
| L'installation de l'APK est refusée | Une ancienne version est installée avec une autre signature | Désinstaller l'ancienne application, puis réinstaller |

---

## 2. Comment ça marche

### Le partage du code avec le web (`Mobile/vite.config.mjs`)

- `@web/...` désigne `Frontend/src/...` : c'est ainsi que le routeur mobile importe les vues du web.
- Dans les vues web, `@/...` cherche **d'abord dans `Mobile/src`, puis dans `Frontend/src`**. Le mobile ne remplace donc que les fichiers qu'il doit remplacer, et reprend tout le reste du web.
- `dedupe` : `Frontend/` n'a pas ses propres `node_modules`. Les vues web utilisent les dépendances de `Mobile/` (vue, vue-router, axios, chart.js…).

### Les fichiers propres au mobile

| Fichier | Rôle |
|---|---|
| `src/App.vue` | Même header que le web ; la sidebar devient une barre d'onglets en bas |
| `src/components/TabBar.vue` | 4 pages selon le rôle, plus l'onglet « Plus » |
| `src/views/More.vue` | Reste du menu, état de la synchronisation, déconnexion |
| `src/navigation.js` | Sections du menu, comme la sidebar du web (sans le Dashboard) |
| `src/router/index.js` | Mêmes chemins, rôles et garde que le web, en historique « hash » |
| `src/api.js` | **Remplace l'API du web** : même interface (`api.get/post/put/delete`), avec le mode hors ligne |
| `src/services/db.js` | Base locale LokiJS : `cache` (dernière réponse de chaque GET) et `queue` (file FIFO) |
| `src/services/offline.js` | Détection du réseau, file d'attente, synchronisation avec le spinner natif |
| `src/services/pending.js` | Affiche tout de suite les modifications en attente |
| `src/services/http.js` | Client axios : adresse de l'API (`VITE_API_URL` au build), en-têtes XSRF et `Authorization`, gestion du 401 |
| `src/services/tables.js` | Sur petit écran, transforme les tableaux en cartes |
| `src/polyfills.js` | Fonctions JavaScript absentes de la vieille WebView |
| `old-webview-css.mjs` | Convertit le CSS de Tailwind v4 pour la WebView d'Android 9 |

### Les copies à garder à jour

`src/team.js` et `src/store.js` sont des **copies** de `Frontend/src/team.js` et `Frontend/src/store.js`. La version web importe `./api` (l'API du web), alors que le mobile doit utiliser son API hors ligne. Si l'un de ces deux fichiers change dans le web, recréer la copie (depuis `Mobile/`) :

```bash
{ printf "// Copie de Frontend/src/team.js : la version web importe './api' (API web),\n// celle-ci doit utiliser l'API hors ligne du mobile. Garder les deux identiques.\n"; sed "s#from './store'#from '@/store'#; s#from './utils/kpi'#from '@/utils/kpi'#" ../Frontend/src/team.js; } > src/team.js
{ printf "// Copie de Frontend/src/store.js : la version web importe './api' (API web),\n// celle-ci doit utiliser l'API hors ligne du mobile. Garder les deux identiques.\n"; sed "s#from './session'#from '@/session'#" ../Frontend/src/store.js; } > src/store.js
```

### Le mode hors ligne

1. **Lecture (GET)** : on interroge d'abord le serveur (priorité au serveur), puis on enregistre la réponse dans LokiJS. Sans réseau, la vue reçoit la dernière réponse enregistrée.
2. **Écriture (POST, PUT, DELETE)** : sans réseau, la requête est ajoutée à la **file FIFO**. La vue reçoit une réponse immédiate, et la modification apparaît tout de suite dans les listes, avec un identifiant temporaire négatif.
3. **Retour du réseau** : le spinner natif s'affiche et les requêtes partent **dans l'ordre**. Quand le serveur crée un objet (une équipe, par exemple), son vrai identifiant remplace l'identifiant temporaire dans les requêtes suivantes.
4. **Refus du serveur** : si une requête est refusée (erreur 4xx autre que 401), **toute la file est annulée** et l'application recharge les données du serveur. Le serveur fait foi.
5. **Pointage** : comme sur le web, l'heure du clic est envoyée (`clock.time`, au format `AAAA-MM-JJ hh:mm:ss`). Le serveur l'enregistre donc à l'heure du pointage, et non à l'heure de la synchronisation.

### La connexion du mobile (jeton dans l'en-tête `Authorization`)

Le web garde son jeton de connexion (JWT) dans un cookie `SameSite=Lax`. L'application mobile est servie depuis `http://localhost` : quand l'API est sur une autre adresse (le PC en Wi-Fi, ou le serveur), le téléphone **n'envoie pas** ce cookie. Le mobile utilise donc un en-tête :

1. Le mobile ajoute `x-client: mobile` à ses requêtes.
2. Seulement dans ce cas, `POST /api/users/sign_in` renvoie aussi le JWT dans sa réponse (`data.token`). Le web ne le reçoit jamais.
3. Le mobile garde ce jeton et l'envoie dans `Authorization: Bearer <jwt>`. Le jeton XSRF (`x-xsrf-token`) reste obligatoire.
4. Côté API, `AuthPlug` lit le jeton dans l'en-tête `Authorization` s'il est présent, sinon dans le cookie.

Tests correspondants dans `manager/test/manager_web/controllers/user_controller_test.exs` : jeton renvoyé seulement au mobile, accès avec l'en-tête sans cookie, refus sans jeton XSRF (403), refus d'un faux jeton (401).

---

## 3. Les outils pour tester

| Outil | Comment |
|---|---|
| **Couper le réseau** | Glisser depuis le haut de l'écran et activer le **mode avion**. Sur un vrai téléphone, vérifier que le Wi-Fi est bien coupé aussi. |
| **Inspecter l'application** | Dans Chrome sur le PC, ouvrir `chrome://inspect`, puis cliquer sur **inspect** sous `com.timemanager.app`. On obtient la console, les requêtes (onglet Network) et le stockage. Marche aussi pour un vrai téléphone branché en USB (débogage USB activé). |
| **Voir la base locale** | Dans l'inspecteur : **Application → Local Storage → `timemanager.db`**. On y trouve le cache des GET et la file d'attente (`queue`). |
| **Repartir de zéro** | `adb shell pm clear com.timemanager.app` efface les données de l'application (session, cache, file d'attente) |
| **Comparer avec le web** | Ouvrir `http://localhost:5174` sur le PC avec le même compte |

---

## 4. Scénarios de test

Faire les étapes dans l'ordre. Avant de commencer, l'émulateur est **connecté** (mode avion désactivé).

### Étape 1 · Lancement et connexion

| # | Action | Résultat attendu |
|---|---|---|
| 1.1 | Lancer l'application | Page de connexion du web : sceau et photo de Gotham, carte « Connexion · Espace agent » |
| 1.2 | Vérifier l'affichage | Le style est appliqué (couleurs, marges, icônes blanches sur fond bleu). Si les liens sont bleus et soulignés, voir l'étape 11. |
| 1.3 | Se connecter avec un mauvais mot de passe | « Email ou mot de passe incorrect » |
| 1.4 | Se connecter avec `john.doe@gotham.gov` | Arrivée sur **Pointage**, avec la barre d'onglets en bas |
| 1.5 | Fermer puis rouvrir l'application | Toujours connecté : la session est gardée dans le `localStorage` |

### Étape 2 · Navigation selon le rôle

| # | Action | Résultat attendu |
|---|---|---|
| 2.1 | Employé : regarder la barre d'onglets | Pointage · Mes temps · Planning · Absences · Plus |
| 2.2 | Onglet **Plus** | Section Employé (avec **Statistiques**), carte Synchronisation, bouton Se déconnecter |
| 2.3 | Se reconnecter en manager (`gordon@gotham.gov`) | Arrivée sur **Équipe** ; onglets Équipe · Alertes · Validation · Planning · Plus |
| 2.4 | Manager : Plus → **Statistiques** | Statistiques de l'équipe, avec le choix « Toute l'équipe » ou un agent |
| 2.5 | Se reconnecter en admin (`albert@gotham.gov`) | Arrivée sur **Utilisateurs** ; onglets Utilisateurs · Règles · Paie · Absences · Plus |
| 2.6 | Admin : onglet **Plus** | Sections Administrateur / RH **et** Manager, comme dans la sidebar du web |
| 2.7 | Ouvrir une sous-page (Équipe → cliquer sur un agent) | Ses temps de travail, avec une flèche **←** dans le header |
| 2.8 | Appuyer sur le **bouton retour d'Android** | Retour à la page précédente |
| 2.9 | Bouton retour d'Android sur la page d'accueil du rôle | L'application se ferme |

### Étape 3 · Même affichage que le web

Ouvrir la même page sur le web (`http://localhost:5174`) et sur le mobile, avec le même compte.

| # | Page | Résultat attendu sur le mobile |
|---|---|---|
| 3.1 | Pointage | Même chrono, mêmes boutons (Pause, Trajet, Incident, Journée conforme), même « Objectif du jour » |
| 3.2 | Mes temps | Mêmes compteurs, même formulaire « Demander une correction », mêmes sessions |
| 3.3 | Planning, Absences | Mêmes cartes, mêmes compteurs |
| 3.4 | Équipe (manager) | Mêmes compteurs, même liste, même gestion des équipes |
| 3.5 | Header | Titre de la page, accessibilité, aide, menu utilisateur (comme le web) |
| 3.6 | Accessibilité (icône en haut) : « Contraste élevé » et « Texte A+ » | Même effet que sur le web |

### Étape 4 · Petit écran

| # | Action | Résultat attendu |
|---|---|---|
| 4.1 | Admin → **Utilisateurs** | Chaque utilisateur est une **carte** : Email, Rôle, Valider les heures, Modifier le planning, Consulter |
| 4.2 | Changer le rôle d'un employé en Manager | Le rôle change ; la ligne apparaît dans « Historique des droits » |
| 4.3 | Activer « Valider les heures » pour un employé | L'interrupteur bascule |
| 4.4 | Manager → Équipe → « Gérer les équipes » | La liste « Ajouter un agent… » et le bouton **Ajouter** restent dans la carte |
| 4.5 | Faire défiler chaque page | Aucune page ne défile horizontalement |

### Étape 5 · Hors ligne : consulter

Se connecter en employé (`john.doe@gotham.gov`), ouvrir une fois **Pointage**, **Mes temps**, **Planning** et **Absences**, puis activer le **mode avion**.

| # | Action | Résultat attendu |
|---|---|---|
| 5.1 | Regarder le header | Bandeau orange **« Hors ligne »** |
| 5.2 | Ouvrir Mes temps, Planning, Absences | Les pages s'affichent avec les dernières données (cache LokiJS) |
| 5.3 | Fermer puis rouvrir l'application, toujours en mode avion | Toujours connecté, pages toujours lisibles |

### Étape 6 · Hors ligne : pointer (cas principal du sujet)

Toujours en employé et en mode avion.

| # | Action | Résultat attendu |
|---|---|---|
| 6.1 | Noter l'heure, puis **Pointer l'arrivée** | Le chrono démarre, pastille « En cours » |
| 6.2 | Regarder le header et l'onglet Plus | « Hors ligne · 1 modification(s) en attente » ; pastille orange « 1 » sur l'onglet Plus |
| 6.3 | Inspecteur (section 3) : `timemanager.db` | La file `queue` contient `POST /clocks/<id>` avec l'heure du pointage |
| 6.4 | Attendre 2 à 3 minutes, puis désactiver le mode avion | **Spinner natif** « Synchronisation… », puis « 1 modification(s) synchronisée(s) » |
| 6.5 | Regarder le bandeau | Le bandeau disparaît : plus rien en attente |
| 6.6 | Web : Pointage de John Doe | L'arrivée est enregistrée à l'heure **du pointage** (6.1), et non à l'heure de la synchronisation (6.4) |

### Étape 7 · Hors ligne : plusieurs actions dans l'ordre (file FIFO)

Se connecter en manager (`gordon@gotham.gov`), ouvrir **Équipe**, puis activer le **mode avion**.

| # | Action | Résultat attendu |
|---|---|---|
| 7.1 | « Gérer les équipes » : créer l'équipe « Patrouille Est » | L'équipe apparaît tout de suite dans la liste |
| 7.2 | Dans « Patrouille Est », ajouter **Harvey Dent** | Harvey apparaît dans l'équipe |
| 7.3 | Regarder le bandeau | « Hors ligne · 2 modification(s) en attente » |
| 7.4 | Désactiver le mode avion | Spinner, puis « 2 modification(s) synchronisée(s) » |
| 7.5 | Web, en manager : Équipe | « Patrouille Est » existe **et** contient Harvey Dent |

Ce test vérifie l'ordre FIFO : l'équipe est créée **avant** l'ajout du membre. Il vérifie aussi le remplacement de l'identifiant : l'ajout utilisait l'identifiant temporaire de l'équipe, remplacé à l'envoi par celui donné par le serveur.

### Étape 8 · Refus du serveur

Toujours en manager, en **mode avion**.

| # | Action | Résultat attendu |
|---|---|---|
| 8.1 | Créer une équipe avec un nom qui existe déjà : « Brigade de nuit » | L'équipe apparaît en double, en attente |
| 8.2 | Désactiver le mode avion | Le serveur refuse (nom déjà pris, 422). Message : « Le serveur a refusé une modification : les changements locaux ont été annulés. » |
| 8.3 | Regarder la liste des équipes | Le doublon a disparu : l'application a repris les données du serveur |

### Étape 9 · Modification faite sur le web pendant que le mobile est hors ligne

C'est la question posée à la fin du bootstrap : *« que se passe-t-il si des modifications sont faites sur le site avant la mise à jour des actions du mobile ? »*

| # | Action | Résultat attendu |
|---|---|---|
| 9.1 | Mobile, manager, **mode avion** : ajouter Harvey Dent dans « Patrouille Est » (le retirer avant si besoin) | Ajout en attente |
| 9.2 | Web, en manager : **supprimer** l'équipe « Patrouille Est » | L'équipe disparaît sur le web |
| 9.3 | Mobile : désactiver le mode avion | L'ajout part vers une équipe qui n'existe plus : le serveur répond **404**. Toute la file est annulée, avec le message de refus. |
| 9.4 | Mobile : Équipe | « Patrouille Est » n'apparaît plus : le mobile a repris l'état du serveur |

**Réponse :** le serveur fait foi. Une action du mobile qui n'a plus de sens est refusée, la file locale est vidée, et le mobile se recale sur les données du serveur. Rien n'est écrit à moitié, puisque les requêtes partent dans l'ordre et que tout s'arrête au premier refus.

### Étape 10 · Données partagées hors ligne (règles, planning, absences…)

Ces données passent par `GET /api/data` et `PUT /api/data/:clé`.

| # | Action | Résultat attendu |
|---|---|---|
| 10.1 | Admin, **mode avion** : Règles → désactiver « Heures tardives » | L'interrupteur reste désactivé (il ne revient pas à sa valeur par défaut) ; « 1 modification(s) en attente » |
| 10.2 | Désactiver le mode avion | Synchronisation ; sur le web, Règles → « Heures tardives » est désactivé |
| 10.3 | Employé, **mode avion** : Absences → Demander un congé → Envoyer | La demande apparaît « En attente » |
| 10.4 | Désactiver le mode avion, puis web en admin : Absences | La demande de l'employé est là |

### Étape 11 · Vieille WebView (Android 9)

La WebView d'Android 9 est un vieux Chrome (version 66 à 69). Tailwind v4 génère du CSS pour Chrome 111 et plus : `old-webview-css.mjs` le convertit au moment de `npm run build`.

| # | Action | Résultat attendu |
|---|---|---|
| 11.1 | `chrome://inspect` sur le PC | La version de la WebView s'affiche à côté de l'appareil (ex. `Chrome/69…`) |
| 11.2 | Regarder la page de connexion | Styles appliqués : couleurs, marges à gauche du texte, coches espacées du texte |
| 11.3 | Regarder les icônes de la barre d'onglets | Blanches (le filtre `invert` fonctionne) |
| 11.4 | Ouvrir **Statistiques** | Les graphiques (Chart.js) s'affichent |

### Étape 12 · Déconnexion

| # | Action | Résultat attendu |
|---|---|---|
| 12.1 | Employé, **mode avion** : pointer, puis Plus → **Se déconnecter** | **Dialogue natif** : « 1 modification(s) n'ont pas encore été envoyées au serveur et seront perdues. Se déconnecter quand même ? » |
| 12.2 | Répondre **Annuler** | On reste connecté, la modification est toujours en attente |
| 12.3 | Désactiver le mode avion, attendre la synchro, puis Se déconnecter | Pas de dialogue ; retour à la page de connexion |
| 12.4 | Inspecteur : `timemanager.db` | Cache et file vidés : un autre agent peut utiliser le téléphone |

### Étape 13 · Vrai téléphone, sans câble

Suivre « Sur un vrai téléphone, sans câble » (section 1), puis :

| # | Action | Résultat attendu |
|---|---|---|
| 13.1 | Chrome du téléphone : `http://IP_DU_PC:4000/api/users/me` | `{"errors":{"detail":"Authentification requise."}}` : le téléphone atteint l'API |
| 13.2 | Installer l'APK, ouvrir **Time Manager**, se connecter avec `john.doe@gotham.gov` | Arrivée sur Pointage ; les pages suivantes se chargent (le jeton passe dans l'en-tête `Authorization`) |
| 13.3 | Ouvrir Mes temps, Planning, Absences | Données du serveur affichées |
| 13.4 | Couper le Wi-Fi et les données, puis **Pointer l'arrivée** | Bandeau orange « Hors ligne · 1 modification(s) en attente » |
| 13.5 | Rallumer le Wi-Fi | Spinner, puis « 1 modification(s) synchronisée(s) » ; sur le web, l'arrivée est à l'heure du clic |
| 13.6 | Comparer l'affichage avec l'émulateur | Même rendu : le téléphone récent utilise le CSS normal, l'émulateur Android 9 le CSS converti |

---

## 5. Ce qui n'est pas testé automatiquement

- Le mobile n'a pas de tests automatiques dans le dépôt : tous les scénarios ci-dessus se font à la main.
- Seule la partie serveur de la connexion mobile est testée automatiquement : 4 tests dans `user_controller_test.exs` (59 tests au total pour le backend).
- Une piste possible : des tests de bout en bout avec **Playwright**. Ils lanceraient le build (`npm run build` puis `vite preview`) dans un navigateur en taille téléphone, avec une fausse API. Playwright sait couper le réseau (`context.setOffline(true)`), ce qui permet de rejouer automatiquement les étapes 5 à 10.
- La vraie vieille WebView (étape 11) ne peut se vérifier que sur l'émulateur Android 9 ou sur un vrai téléphone.

## 6. Limites connues

| Limite | Détail |
|---|---|
| Espacement icône + texte | Sur une WebView sans `gap` en flex (avant Chrome 84), l'espace entre une icône et un texte seul est un peu plus petit que sur le web |
| Première ouverture sans réseau | Une page jamais ouverte avec réseau n'a pas de cache : elle affiche une erreur tant qu'on n'est pas reconnecté |
| Dashboard | Absent du mobile, comme le demande le sujet. La page Pointage sert d'accueil pour l'employé. |
