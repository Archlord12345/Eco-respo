# Éco-Responsable

Plateforme citoyenne de gestion des déchets pour le Cameroun : signalement de
décharges sauvages, collecte à domicile payée en Mobile Money, tri incitatif
avec points et récompenses, application collecteur et back-office municipal.

Application Flutter unique (Android, iOS, Linux, Windows, macOS) branchée sur
**Appwrite Cloud** — endpoint `https://fra.cloud.appwrite.io/v1`, projet
`eco-responsable-cm`.

| | |
|---|---|
| Flutter / Dart | 3.47.1 stable / SDK ^3.13 |
| Backend | Appwrite Cloud (région `fra`), SDK Dart `appwrite ^26.2` (API TablesDB) |
| État | Riverpod 3 · Navigation go_router 18 · Cartes flutter_map 8 |
| Design | Planches dans [`docs/design/`](docs/design/) · thème `lib/core/theme/` |
| CI | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) — 7 sous-workflows |

---

## Sommaire

1. [Fonctionnalités](#1-fonctionnalités)
2. [Démarrage rapide](#2-démarrage-rapide)
3. [Configuration Appwrite](#3-configuration-appwrite)
4. [Architecture du code](#4-architecture-du-code)
5. [Design system et visuels](#5-design-system-et-visuels)
6. [Backend : schéma, outils, état](#6-backend--schéma-outils-état)
7. [Intégration continue et livraison](#7-intégration-continue-et-livraison)
8. [Tests et qualité](#8-tests-et-qualité)
9. [Feuille de route](#9-feuille-de-route)

---

## 1. Fonctionnalités

### Profil citoyen (mobile)

| Écran | Rôle | Planche |
|---|---|---|
| Onboarding (3 slides) → connexion / inscription | Découverte, compte Appwrite (email + mot de passe), choix de la ville | 1 |
| Accueil | Impact de la semaine (points, kg triés, CO₂), objectif mensuel, raccourcis, notifications récentes | 1 |
| Signaler une décharge | Photo (caméra ou fichier), géolocalisation, catégorie, urgence → table `waste_reports` + bucket `report_photos` | 2 |
| Demander une collecte | Type de déchet, volume, créneau, récurrence, paiement MTN MoMo / Orange Money / Afriland → `collection_requests` + Function `matchCollector` | 2 |
| Carte | Points de collecte et signalements autour de soi (flutter_map / OSM) | 2 |
| Récompenses | Solde de points, niveaux Bronze / Argent / Or, catalogue `reward_items`, échange via Function `computeRewardPoints` | 3 |
| Profil et historique | Informations, langue, notifications, historique des signalements et collectes | 3 |
| Suivi et notifications | Détail d’un signalement, statut temps réel (Realtime), fil de notifications | 7 |

### Profil collecteur (mobile)

Disponibilité en ligne / hors ligne, demandes à proximité, tournée du jour,
confirmation de collecte avec photo de preuve (`collection_proofs`) et poids,
historique des interventions, revenus (planches 5 et 6).

### Back-office municipal (desktop, > 1024 px)

Tableau de bord (taux de résolution, délais, volumes, carte de chaleur),
gestion des signalements avec affectation d’opérateur, zones et opérateurs,
rapports et campagnes (planche 4). Même code, même Appwrite : la navigation
bascule sur une `NavigationRail` / sidebar selon la largeur.

### Hors ligne

Les signalements créés sans réseau sont mis en file (`core/offline/sync_queue.dart`,
Hive) et rejoués à la reconnexion.

---

## 2. Démarrage rapide

Prérequis : Flutter 3.47 stable, et pour Android un JDK 21 (AGP 9.1 / Gradle 9.3).

```bash
git clone https://github.com/Archlord12345/Eco-respo.git
cd Eco-respo
flutter pub get

# Les identifiants projet passent en --dart-define (valeurs par défaut identiques).
flutter run -d linux \
  --dart-define=APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=eco-responsable-cm

flutter run -d android   # paquet com.eco.kf
flutter run -d macos
flutter run -d windows
```

Builds release :

```bash
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release
flutter build linux --release      # build/linux/x64/release/bundle/
flutter build windows --release
flutter build macos --release
flutter build ios --release --no-codesign
```

Instance locale avec certificat autosigné : ajouter
`--dart-define=APPWRITE_SELF_SIGNED=true`. À ne jamais activer sur le Cloud.

---

## 3. Configuration Appwrite

### Côté client (Flutter)

`lib/core/appwrite/appwrite_config.dart` lit `APPWRITE_ENDPOINT`,
`APPWRITE_PROJECT_ID`, `APPWRITE_SELF_SIGNED` via `String.fromEnvironment` et
expose les identifiants de base, tables, buckets et Functions.
`appwrite_client.dart` fournit les providers Riverpod `accountProvider`,
`tablesProvider`, `storageProvider`, `realtimeProvider`, `functionsProvider`.

```dart
final client = Client()
  ..setEndpoint('https://fra.cloud.appwrite.io/v1')
  ..setProject('eco-responsable-cm');
final tables = TablesDB(client);
```

**La clé API serveur n’est jamais embarquée dans l’application.** Le client
n’utilise que la session utilisateur et les permissions par ligne.

### Plateformes déclarées

| Plateforme | ID Appwrite | Nom | Identifiant |
|---|---|---|---|
| Android | `eco-android` | `eco-respo mobile` | `com.eco.kf` |
| iOS + macOS | `eco-apple` | `eco-respo apple` | `com.eco.kf` |
| Linux | `eco-linux` | `eco-respo linux` | `com.eco.kf` |
| Windows | `eco-windows` | `eco-respo windows` | `com.eco.kf` |

### Côté administration

```bash
npm i -g appwrite-cli
appwrite login                # compte Appwrite Cloud
tool/appwrite_cli_init.sh     # idempotent : projet, plateformes, tables, buckets, seed
```

Le schéma est déclaré dans `tool/gen_appwrite_config.py` (source de vérité),
rendu dans `appwrite.config.json` et poussé avec `appwrite push table --all -f`
/ `appwrite push bucket --all -f`. Détails : [`appwrite/README.md`](appwrite/README.md).

Pour des appels REST ponctuels, `tool/appwrite.sh` (curl) lit `.env`
(voir `.env.example`) avec une clé « standard » créée dans la console Cloud :

```bash
tool/appwrite.sh tables
tool/appwrite.sh rows reward_items
tool/appwrite.sh get /users
```

---

## 4. Architecture du code

```
lib/
├── main.dart, app.dart          # bootstrap Hive + intl, MaterialApp.router
├── core/
│   ├── appwrite/                # config + providers Client / TablesDB / Storage / Realtime / Functions
│   ├── constants/               # AppAssets (chemins + liste des photos), AppConstants
│   ├── error/                   # AuthFailure, NetworkFailure…
│   ├── offline/                 # SyncQueue (Hive) pour le mode hors ligne
│   ├── router/                  # go_router, redirections auth / rôle
│   ├── theme/                   # AppColors, AppTheme, AppTextStyles
│   ├── utils/                   # ResponsiveHelper (mobile / desktop)
│   └── widgets/                 # AppScaffold, EcoAppBar, PrimaryButton, StatusBadge, AssetImageBox…
├── features/<feature>/
│   ├── data/                    # implémentations Appwrite des repositories
│   ├── domain/repositories/     # interfaces
│   └── presentation/            # écrans + contrôleurs Riverpod
│   (auth, home, reporting, collection_request, map, rewards, profile, collector, dashboard_admin)
├── shared/models/               # AppUser, WasteReport, CollectionRequest, Collector, RewardItem, Zone… (1:1 avec les tables)
└── l10n/                        # ARB fr / en + AppLocalizations générées
```

Principes :

- **Une feature = data / domain / presentation.** Les écrans ne parlent qu’aux
  interfaces (`ReportRepository`, `AuthRepository`…) via Riverpod ; les
  implémentations Appwrite sont interchangeables (tests avec fakes/mocks).
- **Modèles 1:1 avec les tables** : `fromMap` / `toMap` sur `Row.data`, id
  porté par `$id`.
- **Realtime** : `AppwriteConfig.rowsChannel(table)` construit le canal
  `tablesdb.<db>.tables.<table>.rows` avec le helper `Channel` du SDK.
- **Valkey / logique lourde côté serveur** : jamais appelé depuis Flutter.
  Matching collecteur, points, paiements et rapports passent par
  `Functions.createExecution`. En l’absence de Function déployée, l’app
  dégrade proprement (classement lu dans `users`, paiement `pending`).

---

## 5. Design system et visuels

Les sept planches de référence sont dans [`docs/design/`](docs/design/).

| Jeton | Valeur | Usage |
|---|---|---|
| Vert principal | `#2E7D32` | actions, app bar, sélection |
| Vert clair | `#A5D6A7` / pâle `#E8F5E9` | fonds de cartes, indicateurs |
| Terre / ocre | `#D9A441` | accents, Mobile Money, niveau Or |
| Fond | `#F8F7F1` | scaffold |
| Texte | `#212121` titres · `#4A4A4A` corps · `#8A8A8A` secondaire | |
| Typographie | **Poppins** titres/labels · **Inter** corps (google_fonts) | |
| Rayons | 20 cartes · 16 champs · 12 chips · boutons pill | |

Tout est centralisé dans `AppTheme.light()` (boutons, champs, cartes, chips,
segmented, nav bar, FAB, switch, snackbar, dialogs, bottom sheets). Règle :
**ne pas styler localement**, utiliser le thème et les widgets `core/widgets`.

### Images

Les visuels de `assets/images/` sont générés pour le projet et référencés par
nom dans `AppAssets`. Deux familles :

- **Photos / illustrations pleines** (`AppAssets.photos`) : héros et slides
  d’onboarding, avatars, photos de décharge et camion, aperçus de carte →
  affichées en `BoxFit.cover`.
- **Icônes et illustrations à fond transparent** (logo, badges, récompenses,
  catégories de signalement, notifications, paiements) → `BoxFit.contain`,
  jamais rognées.

Le widget `AssetImageBox` choisit automatiquement l’ajustement selon
`AppAssets.isPhoto`, accepte `fit` / `alignment` / `padding` pour forcer un
recadrage, et borne le décodage à la taille du cadre (`cacheWidth`). Pour
remplacer un visuel, **garder le même nom de fichier** ; pour en ajouter un,
déclarer la constante dans `AppAssets` (et l’ajouter à `photos` si c’est une
photo).

---

## 6. Backend : schéma, outils, état

Base `eco_responsable_db`, sept tables (`users`, `waste_reports`,
`collection_requests`, `collectors`, `reward_items`, `zones`,
`notifications`), deux buckets (`report_photos`, `collection_proofs`).
Permissions MVP : `read(any)`, `create/update/delete(users)` + sécurité par
ligne ; les lignes créées par l’app portent en plus des permissions propriétaire.

Schéma détaillé, colonnes, index, Functions : [`appwrite/README.md`](appwrite/README.md).

| Outil | Rôle |
|---|---|
| `tool/gen_appwrite_config.py` | Source de vérité du schéma → `appwrite.config.json` |
| `tool/appwrite_cli_init.sh` | Provisionnement idempotent complet (CLI officielle) + données de départ |
| `tool/appwrite.sh` | Client REST curl (`.env`, clé serveur) pour vérifications ponctuelles |
| `tool/setup_appwrite.py` | Ancien provisionnement de l’instance auto-hébergée (API Databases, conservé pour référence) |
| `tool/build_all_assets.py`, `tool/make_placeholders.py` | Anciens scripts de préparation des assets |

État au 21 septembre 2026 : base, tables, index, buckets et données de départ
(3 récompenses, 5 zones de Yaoundé) en place et lisibles publiquement.
Restent à déployer les Functions `matchCollector`, `computeRewardPoints`,
`paymentWebhook`, `generateAdminReport` et un provider Messaging (FCM / APNs).

---

## 7. Intégration continue et livraison

Un seul workflow, [`.github/workflows/ci.yml`](.github/workflows/ci.yml),
découpé en sous-workflows chaînés :

| # | Job | Contenu | Déclencheur |
|---|---|---|---|
| 1 | `qualite` | `flutter pub get`, `gen-l10n`, `analyze --fatal-infos`, `test --coverage` | toujours, bloquant |
| 2 | `android` | APK + AAB release (`--dart-define` Appwrite), JDK 21, cache Gradle | toujours |
| 3 | `linux` | bundle x64 → `.tar.gz` | toujours |
| 4 | `windows` | runner Release → `.zip` | push `master`, tag, manuel |
| 5 | `macos` | `.app` non signée → `.zip` | push `master`, tag, manuel |
| 6 | `ios` | `Runner.app` sans signature → `.zip` | push `master`, tag, manuel |
| 7 | `publication` | release GitHub avec tous les artefacts + `SHA256SUMS.txt` | tag `v*` |

- Flutter épinglé à `3.47.1` (`FLUTTER_VERSION`), cache activé.
- Les variables de dépôt `APPWRITE_ENDPOINT` / `APPWRITE_PROJECT_ID`
  (Settings → Secrets and variables → Variables) surchargent les valeurs Cloud
  par défaut.
- Sur pull request, seuls les jobs 1 à 3 tournent. `workflow_dispatch` permet
  de désactiver Windows / macOS / iOS.
- Publier une version :

```bash
git tag v1.0.0 && git push --tags
```

La signature Android utilise la clé debug (APK installable, non publiable sur
le Play Store) ; pour une signature de production, ajouter un keystore en
secret et un `signingConfigs.release` dans `android/app/build.gradle.kts`.

---

## 8. Tests et qualité

```bash
flutter analyze --fatal-infos
flutter test
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
```

- `test/widget_test.dart` : écran d’accueil (CTA « Commencer »), `StatusBadge`.
- `test/features/auth/auth_repository_test.dart` : `AuthRepository` factice.
- `test/features/reporting/report_repository_test.dart` : `ReportRepository` factice.
- `test/shared/waste_report_test.dart` : mapping `WasteReport.fromMap` depuis une ligne Appwrite.

Lints : `flutter_lints ^6` (`analysis_options.yaml`). L’analyse doit rester à
zéro info pour que la CI passe.

---

## 9. Feuille de route

- Déployer les Functions Appwrite (Node/Dart) et le provider Messaging.
- Authentification téléphone + OTP (planche 1) en complément de l’email.
- Durcir les permissions avec des Teams `admins` / `collectors`.
- Signature Android de production et distribution TestFlight.
- Tests d’intégration (`integration_test/`) sur le parcours signalement → résolution.
