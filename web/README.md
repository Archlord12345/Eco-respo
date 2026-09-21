# Éco-Responsable — application web

Cible **navigateur** (`AppTarget.web`) : tous les espaces (citoyen,
collecteur, mairie, entreprise) avec mise en page adaptative. Tout le code
vient du package partagé [`../shared`](../shared) (`eco_core`).

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=eco-responsable-cm

flutter build web --release --base-href /      # build/web/
```

Déploiement : copier `build/web/` sur n'importe quel hébergeur statique
(Appwrite Sites, Netlify, Nginx…). **Déclarer ensuite une plateforme Web dans
la console Appwrite avec le nom d'hôte** (sinon les requêtes sont bloquées
par CORS).

- PWA : `web/manifest.json` (nom, couleurs, icônes maskable), écran de
  chargement personnalisé dans `web/index.html`.
- Icônes / favicon : `dart run flutter_launcher_icons`.
- La caméra passe par le sélecteur de fichiers du navigateur ; la
  géolocalisation utilise l'API du navigateur (HTTPS requis).
