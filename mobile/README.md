# Éco-Responsable — application mobile

Cible **Android / iOS** pour les **citoyens** et les **collecteurs**
(`AppTarget.mobile`). Tout le code vient du package partagé
[`../shared`](../shared) (`eco_core`) ; ce dossier ne contient que
l'entrée `lib/main.dart`, la configuration native et les icônes.

```bash
flutter pub get
flutter run -d android \
  --dart-define=APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=eco-responsable-cm

flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
```

- Identifiant : `com.eco.kf` (plateformes Appwrite `eco-android`, `eco-apple`).
- Authentification : téléphone + code à 6 chiffres choisi par l'utilisateur
  (aucun SMS), ou email + mot de passe.
- Un compte mairie / entreprise se connecte mais est renvoyé vers l'accueil
  citoyen ; le back-office est réservé aux apps desktop et web.
- Icônes : `dart run flutter_launcher_icons` (source `../shared/assets/branding/`).
- Permissions déclarées : caméra, photos, localisation (`ios/Runner/Info.plist`,
  `android/app/src/main/AndroidManifest.xml`).
