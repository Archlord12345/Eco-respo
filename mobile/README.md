# Profil mobile Éco-Responsable

Ce profil cible Android et iOS. Il utilise le code partagé dans `lib/` avec la navigation citoyenne, les écrans des planches mobiles et les repositories Appwrite.

Lancement depuis la racine du projet :

```bash
flutter run -d android \
  --dart-define=APPWRITE_ENDPOINT=https://appwrite.kernelforge.codes/v1 \
  --dart-define=APPWRITE_PROJECT_ID=6aad2f1a000a6a6de281
```

Authentification : nom, email et mot de passe via Appwrite Account. Aucun OTP n'est requis.

Plateforme Appwrite : `flutter-android`, package `com.eco.kf`.
