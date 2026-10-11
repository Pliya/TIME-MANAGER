# Passage en HTTPS avec le domaine DuckDNS

Domaine : `gotham-manager.duckdns.org` → IP `35.208.70.76`

L'application utilise maintenant ce domaine en HTTPS. Le front appelle l'API
en chemin relatif (`/api`), donc tout suit automatiquement le domaine et le
HTTPS : aucun changement de code à prévoir pour un futur changement de domaine.

Ce qui suit se fait **une seule fois sur le serveur** (Google Cloud).

## 1. Ouvrir les ports 80 et 443 (pare-feu Google Cloud)

Dans la console Google Cloud → **VPC Network → Firewall** : autoriser le
trafic entrant sur les ports **80** et **443**.

Fermer le port **5174** et le port **4000** au public (ils ne sont plus
exposés : le front écoute sur 80/443 et le back reste interne à Docker).

## 2. Obtenir le certificat HTTPS (Let's Encrypt)

```bash
sudo apt update && sudo apt install -y certbot

# Libérer le port 80 pour la première génération
cd ~/time-manager
docker compose down

# Générer le certificat pour le domaine
sudo certbot certonly --standalone -d gotham-manager.duckdns.org

# Dossier du webroot pour les renouvellements sans coupure
sudo mkdir -p /var/www/certbot
```

Le certificat est créé dans `/etc/letsencrypt/live/gotham-manager.duckdns.org/`.
Ce dossier est monté dans le conteneur front (voir `docker-compose.yml`).

## 3. Mettre à jour le fichier `.env` du serveur

Dans `~/time-manager/.env`, ajouter (ou vérifier) :

```
PHX_HOST=gotham-manager.duckdns.org
PHX_SCHEME=https
PHX_URL_PORT=443
COOKIE_SECURE=true
CORS_ORIGINS=https://gotham-manager.duckdns.org
```

- `COOKIE_SECURE=true` : le cookie JWT n'est plus envoyé qu'en HTTPS.
- `CORS_ORIGINS` : seule l'origine HTTPS du domaine est autorisée.

En local (développement), ne pas définir ces variables : le cookie reste en
HTTP et CORS autorise `localhost:5174`.

## 4. Démarrer l'application

```bash
cd ~/time-manager
docker compose pull
docker compose up -d
```

Vérifier : ouvrir `https://gotham-manager.duckdns.org` dans le navigateur.
Le cadenas doit apparaître, et `http://...` doit rediriger vers `https://...`.

## 5. Renouvellement automatique du certificat (tous les 90 jours)

Le certificat expire au bout de 90 jours. Ajouter une tâche cron :

```bash
sudo crontab -e
```

Ajouter la ligne :

```
0 3 * * * certbot renew --webroot -w /var/www/certbot --quiet && docker exec time_manager_frontend nginx -s reload
```

Elle renouvelle le certificat si besoin et recharge Nginx, sans coupure.

## Résumé des changements dans le dépôt

| Fichier | Changement |
|---|---|
| `Frontend/nginx.conf` | Écoute en 443 (SSL), redirige 80→443, en-tête HSTS |
| `docker-compose.prod.yml` | Front publie 80 et 443, monte les certificats |
| `manager/.../user_controller.ex` | Cookie `secure` piloté par `COOKIE_SECURE` |
| `manager/.../endpoint.ex` | Origines CORS pilotées par `CORS_ORIGINS` |
| `.travis.yml`, `Dockerfile`, `.env.example` | URL mise à jour vers le domaine HTTPS |

