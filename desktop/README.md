# Profil desktop Éco-Responsable

Ce profil cible Linux, Windows et macOS. Il utilise le code partagé dans `lib/` avec la sidebar municipale, le dashboard et les écrans d'administration des planches desktop.

Lancement depuis la racine du projet :

```bash
flutter run -d linux \
  --dart-define=APPWRITE_ENDPOINT=https://appwrite.kernelforge.codes/v1 \
  --dart-define=APPWRITE_PROJECT_ID=6aad2f1a000a6a6de281
```

Les cibles Windows et macOS utilisent les mêmes defines Appwrite. L'interface admin exploite l'espace horizontal avec une sidebar.

Plateformes Appwrite : `flutter-linux`, `flutter-windows`, `flutter-macos`, package `com.eco.kf`.
