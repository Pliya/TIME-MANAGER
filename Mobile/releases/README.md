# APK Time Manager (Android)

`time-manager.apk` — version de test (debug) de l'application mobile.

## Installer sur un téléphone

1. Copier `time-manager.apk` sur le téléphone (câble, mail, Drive...).
2. L'ouvrir depuis le gestionnaire de fichiers.
3. Autoriser « Installer des applications inconnues » pour cette source.
4. Installer. L'application « Time Manager » apparaît dans le menu.

Ou, téléphone branché en USB avec le débogage activé :

```bash
adb install -r Mobile/releases/time-manager.apk
```

## Important

L'application appelle `https://gotham-manager.duckdns.org/api`.
Elle ne fonctionne que si le serveur est en HTTPS (voir `docs/HTTPS_DEPLOIEMENT.md`)
et que le backend a la version avec la connexion mobile.

## Reconstruire l'APK

Voir `docs/TESTS_MOBILE.md`. En résumé, depuis `Mobile/` :

```bash
npm install
npm run build
npx cordova build android
# APK : platforms/android/app/build/outputs/apk/debug/app-debug.apk
```
