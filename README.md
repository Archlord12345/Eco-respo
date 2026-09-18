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

Pour une instance locale avec certificat autosigné, ajouter
`--dart-define=APPWRITE_SELF_SIGNED=true`.

Paquet mobile déclaré dans Appwrite : `com.eco.kf`.

## Configuration Appwrite mobile

La plateforme Flutter Android déclarée dans le projet Appwrite utilise :

- Endpoint : `https://appwrite.kernelforge.codes/v1`
- Project ID : `6aad2f1a000a6a6de281`
- Nom de plateforme : `eco-respo mobile`
- Package Android : `com.eco.kf`
- SDK Dart : `appwrite: ^13.0.0`

Initialisation attendue côté Flutter :

```dart
final client = Client()
  ..setEndpoint('https://appwrite.kernelforge.codes/v1')
  ..setProject('6aad2f1a000a6a6de281');
```

La clé API serveur n'est jamais utilisée dans Flutter. Elle doit être fournie
uniquement au script d'administration via `APPWRITE_API_KEY`.

## Configuration Appwrite desktop

Les plateformes Flutter desktop utilisent le même projet Appwrite et le même
identifiant applicatif :

| Plateforme | Nom Appwrite | Identifiant |
|---|---|---|
| Linux | `eco-respo linux` | `com.eco.kf` |
| macOS | `eco-respo macos` | `com.eco.kf` |
| Windows | `eco-respo windows` | `com.eco.kf` |

Exemples de lancement :

```bash
flutter run -d linux --dart-define=APPWRITE_ENDPOINT=https://appwrite.kernelforge.codes/v1 --dart-define=APPWRITE_PROJECT_ID=6aad2f1a000a6a6de281
flutter run -d macos --dart-define=APPWRITE_ENDPOINT=https://appwrite.kernelforge.codes/v1 --dart-define=APPWRITE_PROJECT_ID=6aad2f1a000a6a6de281
flutter run -d windows --dart-define=APPWRITE_ENDPOINT=https://appwrite.kernelforge.codes/v1 --dart-define=APPWRITE_PROJECT_ID=6aad2f1a000a6a6de281
```

Le desktop utilise le même SDK `appwrite: ^13.0.0` et la même initialisation
que le mobile. `setSelfSigned(true)` est réservé au développement local avec
certificat autosigné ; l'endpoint de production n'en a pas besoin.

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
