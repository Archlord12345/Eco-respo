# 03 — Architecture technique

## Monorepo

```
ECo/
├── shared/                      package Dart `eco_core` — TOUT le code applicatif
│   ├── lib/
│   │   ├── eco_core.dart        exports publics (runEcoApp, AppTarget…)
│   │   ├── bootstrap.dart       Hive.initFlutter, intl fr, ProviderScope(appTargetProvider)
│   │   ├── app.dart             MaterialApp.router + AppTheme
│   │   ├── core/
│   │   │   ├── app/app_target.dart         enum AppTarget {mobile, desktop, web} + homeFor(role)
│   │   │   ├── appwrite/appwrite_config.dart   endpoint/projectId (dart-define), ids tables/buckets/functions, rowsChannel(), rowChannel(), fileViewUrl()
│   │   │   ├── appwrite/appwrite_client.dart   providers Client/Account/TablesDB/Storage/Realtime/Functions
│   │   │   ├── constants/       AppAssets, AppConstants
│   │   │   ├── error/           AppFailure, AuthFailure, NetworkFailure
│   │   │   ├── offline/sync_queue.dart   file Hive rejouée à la reconnexion
│   │   │   ├── router/          app_router.dart (go_router), route_names.dart
│   │   │   ├── theme/           AppColors, AppTheme, AppTextStyles
│   │   │   ├── utils/           ResponsiveHelper, PhotoPicker
│   │   │   └── widgets/         CitizenShell, CollectorShell, AdminShell, CompanyShell, BackOfficeHeader, EcoAppBar, MiniMap, StatusBadge, AssetImageBox, PrimaryButton…
│   │   ├── features/<feature>/{data,domain,presentation}/
│   │   │   auth, home, reporting, collection_request, map, rewards, profile,
│   │   │   notifications, settings, collector, dashboard_admin, company
│   │   ├── shared/models/       AppUser, WasteReport, CollectionRequest, Collector, RewardItem, Zone, AppNotification, enums
│   │   └── l10n/                ARB fr/en (flutter gen-l10n)
│   ├── assets/images/…          visuels de l'app ; assets/branding/ icônes
│   └── test/
├── mobile/    main.dart = runEcoApp(AppTarget.mobile)  + android/ ios/
├── desktop/   main.dart = runEcoApp(AppTarget.desktop) + linux/ windows/ macos/
├── web/       main.dart = runEcoApp(AppTarget.web)     + web/ (index.html, manifest.json)
├── appwrite.config.json          schéma déclaratif Appwrite (généré)
├── tool/                         gen_appwrite_config.py, appwrite_cli_init.sh, appwrite.sh
└── .github/workflows/ci.yml      workflow unique
```

Les apps dépendent de `eco_core` par `path: ../shared`. Les assets du
package sont chargés avec `package: 'eco_core'` (`AppAssets.image()`).

## Stack et versions

| Couche | Choix | Version |
|---|---|---|
| UI | Flutter / Dart | 3.47.1 / ^3.13 |
| État | flutter_riverpod (Notifier, FutureProvider, StreamProvider, `.family`) | ^3.4 |
| Navigation | go_router (`StatefulShellRoute` par espace, `ShellRoute` back-office, `redirect` auth/rôle/cible) | ^18 |
| Backend SDK | appwrite (Dart, API **TablesDB** : `listRows/getRow/createRow/updateRow/upsertRow`) | ^26.2 |
| Cartes | flutter_map + latlong2 (tuiles OSM `tile.openstreetmap.org`) | ^8.1 |
| Localisation GPS | geolocator | ^14 |
| Médias | image_picker, file_picker (camera/galerie/fichier selon plateforme) | |
| Graphiques | fl_chart | ^1.2 |
| Hors ligne | hive_flutter | |
| Divers | google_fonts (Poppins/Inter), intl, url_launcher, package_info_plus, crypto (dérivation code 6 chiffres), flutter_web_auth_2, device_info_plus | |

## Patterns

- **Feature = data / domain / presentation.** Les écrans dépendent
  d'interfaces (`AuthRepository`, `ReportRepository`, `CollectionRequestRepository`,
  `CollectorRepository`, `RewardRepository`, `ZoneRepository`,
  `NotificationRepository`, `PaymentService`) définies dans
  `features/reporting/domain/repositories/report_repository.dart` et
  `features/auth/domain/repositories/auth_repository.dart`. Implémentations
  Appwrite dans `features/*/data/`. Providers : `authRepositoryProvider`,
  `reportRepositoryProvider`, `requestRepositoryProvider`,
  `collectorRepositoryProvider`, `rewardRepositoryProvider`,
  `zoneRepositoryProvider`, `notificationRepositoryProvider`,
  `paymentServiceProvider`, `storageUploaderProvider`.
- **Modèles 1:1 avec les tables** : `fromMap(Map, {id})` / `toMap()`, id =
  `$id` de la ligne, dates ISO 8601 en `varchar`/`datetime`.
- **Realtime** : `Realtime.subscribe([AppwriteConfig.rowsChannel('table')])`
  ou `rowChannel(table, id)` → `StreamController` qui recharge la liste
  (voir `watchMine`, `watchOne`). Format canal SDK 26 :
  `tablesdb.<db>.tables.<table>.rows[.<id>]`.
- **Functions** : appelées avec `Functions.createExecution(functionId, body: json)`,
  résultat lu dans `responseBody` ; **toujours** avec repli client si la
  Function n'existe pas (à supprimer progressivement quand elles seront
  déployées et rendues autoritaires).
- **Permissions** : les lignes créées par l'app portent
  `read(user:<id>)`, `update(user:<id>)`, `read(users)` (voir
  `_ownerPermissions` / `_rowPermissions`).
- **Cible d'app** : `appTargetProvider` (override dans `runEcoApp`),
  `AppTargetX.hasCitizenSpace / hasCollectorSpace / hasBackOffice / homeFor(role)`.
- **Thème** : tout dans `AppTheme.light()`, aucun style local.

## Flux de données principaux

```
Citoyen signale        report_screen ─► StorageUploader.uploadReportPhoto ─► waste_reports.createRow
                        (hors ligne : SyncQueue.enqueue → rejoué)
Mairie affecte         admin_screens ─► updateStatus(id, 'inProgress', operatorId) ─► notifications.createRow(auteur)
Citoyen suit           report_detail_screen ◄─ Realtime rowChannel(waste_reports, id)

Citoyen demande        collection_request_screen ─► collection_requests.createRow ─► Functions.matchCollector (absent → pending)
                                                  ─► PaymentService.startCheckout (absent → 'pending')
Collecteur accepte     CollectorActions.accept ─► updateRow(status=matched, assignedCollectorId) ─► notification
Collecteur confirme    CollectorActions.confirm ─► uploadProof ─► updateRow(status=collected, weightKg, proofFileId)
                                                ─► Functions.computeRewardPoints (absent → users.points += kg*pointsPerKg côté client)
                                                ─► collectors.interventionsCount++ ─► notification
Citoyen suit           request_tracking_screen ◄─ Realtime rowChannel(collection_requests, id) + collectors.getRow(assignedCollectorId)
```

## Configuration et environnements

- `--dart-define=APPWRITE_ENDPOINT=…`, `APPWRITE_PROJECT_ID=…`,
  `APPWRITE_SELF_SIGNED=true|false`. Valeurs par défaut = Cloud.
- Un seul projet Appwrite aujourd'hui (`eco-responsable-cm`). **Recommandé** :
  créer un projet `eco-responsable-staging` pour les Functions en cours et
  paramétrer la CI avec les variables de dépôt `APPWRITE_ENDPOINT` /
  `APPWRITE_PROJECT_ID`.
- CLI : `appwrite login`, `tool/appwrite_cli_init.sh` (idempotent),
  `appwrite push table --all -f`, `appwrite push bucket --all -f`,
  `appwrite push function`. Schéma source : `tool/gen_appwrite_config.py`
  (régénérer puis pousser).
- Secrets : `.env` (ignoré) pour `tool/appwrite.sh` ; jamais de clé serveur
  dans Flutter.

## CI (`.github/workflows/ci.yml`)

Jobs : `qualite` (shared : gen-l10n, analyze --fatal-infos, test --coverage ;
analyze des 3 apps) → `android` (APK + AAB), `ios` (no-codesign), `linux`
(.tar.gz), `windows` (.zip), `macos` (.app.zip), `web` (.tar.gz) →
`publication` (release GitHub sur tag `v*`). iOS / Windows / macOS ne
tournent pas sur pull request. Flutter épinglé `3.47.1`.

## Commandes de développement

```bash
cd shared  && flutter pub get && flutter gen-l10n && flutter analyze --fatal-infos && flutter test
cd mobile  && flutter run -d android
cd desktop && flutter run -d linux
cd web     && flutter run -d chrome
for a in mobile desktop web; do (cd $a && dart run flutter_launcher_icons); done
python3 tool/gen_appwrite_config.py && appwrite push table --all -f
```

Dépendances Linux : `clang cmake ninja-build pkg-config libgtk-3-dev
libsecret-1-dev libwebkit2gtk-4.1-dev`. Android : JDK 21.
