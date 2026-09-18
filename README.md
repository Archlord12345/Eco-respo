# Éco-Responsable

Plateforme citoyenne de gestion des déchets (Cameroun) : signalements, collectes à domicile, récompenses et tableau de bord municipal.

Cible : **Android, iOS, Linux, Windows, macOS**. Backend : **Appwrite** (`https://appwrite.kernelforge.codes/v1`, projet `6aad2f1a000a6a6de281`).

## Lancement

Les identifiants projet se passent en `--dart-define` (jamais la clé API serveur dans le client Flutter).

```bash
flutter pub get

# Linux
flutter run -d linux \
  --dart-define=APPWRITE_ENDPOINT=https://appwrite.kernelforge.codes/v1 \
  --dart-define=APPWRITE_PROJECT_ID=6aad2f1a000a6a6de281

# Android (paquet com.eco.kf)
flutter run -d android \
  --dart-define=APPWRITE_ENDPOINT=https://appwrite.kernelforge.codes/v1 \
  --dart-define=APPWRITE_PROJECT_ID=6aad2f1a000a6a6de281
```

Paquet mobile déclaré dans Appwrite : `com.eco.kf`.

## Images à remplacer

Tous les visuels sont des PNG de couleur unie dans `assets/images/`. Conservez **le même nom de fichier** quand vous les remplacez. Liste : `lib/core/constants/app_assets.dart`.

## Structure

- `lib/core/` — Appwrite, thème, router, widgets
- `lib/features/` — auth, reporting, collecte, carte, récompenses, profil, collecteur, admin
- `lib/shared/models/` — documents 1:1 avec les collections Appwrite

Navigation : barre du bas sur mobile, `NavigationRail` / sidebar admin sur desktop (> 1024 px).

## Valkey

Valkey n’est **jamais** appelé depuis Flutter. Le classement et le matching collecteur passent par les Functions Appwrite (`computeRewardPoints`, `matchCollector`).

## Schéma Appwrite

Voir `appwrite/README.md`. Provisionnement (clé serveur, hors client) :

```bash
APPWRITE_API_KEY=... python3 tool/setup_appwrite.py
```

## Tests

```bash
flutter test
```
