# 02 — État actuel du code (audit du 21 septembre 2026)

Légende : **RÉEL** = branché sur Appwrite et fonctionnel · **PARTIEL** =
fonctionne avec repli / données incomplètes · **SIMULÉ** = affiché mais pas
branché · **ABSENT** = n'existe pas.

Repo : `https://github.com/Archlord12345/Eco-respo` (branche `master`,
commit `23b44b6` et suivants). ~11 300 lignes Dart dans `shared/lib`.
CI verte sur 7 jobs (analyse/tests, Android, iOS, Linux, Windows, macOS, web).

## Ce qui est réel et vérifié

| Élément | Détail | Fichiers |
|---|---|---|
| Backend Appwrite Cloud | Projet `eco-responsable-cm`, base `eco_responsable_db`, 7 tables + index, 2 buckets, seeds (3 récompenses, 5 zones Yaoundé), 4 plateformes (Android, Apple, Linux, Windows) | `appwrite.config.json`, `tool/gen_appwrite_config.py`, `tool/appwrite_cli_init.sh` |
| Auth email + mot de passe | `Account.create` / `createEmailPasswordSession`, profil `users` créé à la volée | `shared/lib/features/auth/data/appwrite_auth_repository.dart` |
| Auth téléphone + code 6 chiffres | Sans SMS : email technique `<num>@phone.eco-responsable.cm` + mot de passe `sha256("eco-responsable|num|code")`, `updatePhone`. Testé en réel sur le Cloud (création, refus mauvais code, session). Changement de code dans Paramètres | idem + `register_phone_screen.dart`, `settings_screen.dart` |
| Cible d'app | `AppTarget` mobile / desktop / web injecté par `runEcoApp`, `homeFor(role)`, écran `/restricted` | `shared/lib/core/app/app_target.dart`, `bootstrap.dart`, `core/router/app_router.dart` |
| Signalement (création) | Photo → Storage `report_photos`, GPS `geolocator`, ligne `waste_reports` avec permissions propriétaire, file hors ligne Hive | `reporting/presentation/report_screen.dart`, `reporting/data/appwrite_report_repository.dart`, `core/offline/sync_queue.dart` |
| Détail signalement | Lecture, photo Storage (`StoragePhoto`), carte `MiniMap`, chronologie, Realtime par ligne | `reporting/presentation/report_detail_screen.dart` |
| Demande de collecte (création) | Position GPS, prix, ligne `collection_requests`, appel `matchCollector` (tolère l'absence de la Function) | `collection_request/presentation/collection_request_screen.dart` |
| Suivi de demande | Stream Realtime `rowChannel`, collecteur assigné (fiche `collectors`), appel téléphone, stepper | `collection_request/presentation/request_tracking_screen.dart` |
| Espace collecteur | Disponibilité (`collectors.isAvailable`), demandes `pending` par ville, accepter / démarrer / confirmer / annuler, preuve → `collection_proofs`, poids, points crédités **côté client** (repli), notification au citoyen, `interventionsCount++`, historique, revenus calculés depuis les collectes | `collector/presentation/collector_screens.dart`, `collector/data/collector_actions.dart` |
| Notifications in-app | Table `notifications`, stream Realtime, filtres, marquage lu, navigation via `refType/refId` | `notifications/presentation/notifications_screen.dart` |
| Récompenses | Catalogue `reward_items`, échange : tente `computeRewardPoints` puis **débit direct** dans `users.points` (repli), classement top 10 | `rewards/presentation/rewards_screen.dart`, repository |
| Back-office mairie | KPI calculés depuis `waste_reports` / `collection_requests`, carte de chaleur (pins colorés), courbes 30 j, camembert, table filtrable, affectation d'opérateur (`assignedOperatorId`), résolution, réouverture, export CSV (dialogue natif / presse-papiers), zones CRUD (centre + couleur + fréquence), affectation opérateurs par zone, campagnes → lignes `notifications` pour chaque citoyen ciblé | `dashboard_admin/presentation/admin_screens.dart` |
| Back-office entreprise | Dashboard, dispatch (`assign`), flotte (`upsert` collecteur), revenus | `company/presentation/company_screens.dart` |
| Carte citoyen | Vraie carte `flutter_map` OSM : position utilisateur (`geolocator`), cercle de rayon, points de collecte = `zones`, signalements ouverts filtrés type / distance, liste horizontale des points proches, itinéraire externe (Google Maps) | `map/presentation/map_screen.dart`, `core/widgets/mini_map.dart` |
| Thème / design | Material 3 complet, Poppins / Inter, palette des planches, `AssetImageBox` | `core/theme/`, `core/widgets/` |
| Icônes & branding | Icône générée depuis le logo pour toutes les plateformes ; affiches | `shared/assets/branding/`, `docs/marketing/` |
| CI | Workflow unique par dossier, artefacts nommés, release sur tag | `.github/workflows/ci.yml` |

## Ce qui est partiel ou simulé — à rendre réel

### Backend (aucune Function déployée aujourd'hui)

| Élément | État | Conséquence côté client aujourd'hui |
|---|---|---|
| Function `matchCollector` | **ABSENT** | La demande reste `pending` jusqu'à acceptation manuelle par un collecteur ou dispatch entreprise |
| Function `computeRewardPoints` | **ABSENT** | Points crédités / débités **par le client** (non autoritaire, falsifiable) |
| Function `paymentWebhook` (+ init paiement) | **ABSENT** | `AppwritePaymentService.startCheckout` retourne `'pending'` ; **aucun paiement Mobile Money réel** ; `amountPaid` est le prix estimé, pas un paiement |
| Function `generateAdminReport` | **ABSENT** | Repli : génération CSV côté client |
| Messaging (push FCM / APNs) | **ABSENT** | Notifications uniquement in-app (Realtime) |
| Permissions | **PARTIEL** : `read(any)` + `create/update/delete(users)` + row security ; aucune Team | N'importe quel utilisateur connecté peut modifier une ligne dont il a les permissions ; les rôles `admin` / `operator` sont **auto-déclarés** dans `users.role` (chip dans Paramètres) — pas de contrôle serveur |
| Position en direct des collecteurs | **ABSENT** (aucune table / colonne) | Suivi de demande sans position réelle ni ETA calculé |
| Reverse geocoding | **ABSENT** | L'adresse d'un signalement est saisie à la main ou vide |
| Itinéraires | **PARTIEL** | Polyline droite entre arrêts (`MiniMap(polyline: true)`), navigation externe via Google Maps |
| Points de collecte | **PARTIEL** | Utilise les centres des `zones` comme points de collecte ; pas de table dédiée (bacs, déchetteries, horaires) |
| Zones | **PARTIEL** | Centre + couleur ; pas de polygone |
| Plateforme Web Appwrite | **ABSENT** | Le build web sera bloqué par CORS tant que le nom d'hôte n'est pas déclaré |
| Seeds | **PARTIEL** | 3 récompenses, 5 zones Yaoundé ; rien pour Douala ; aucun collecteur / opérateur de démo |
| Monitoring / logs / backups | **ABSENT** | |

### Frontend (points communs au package `shared/`)

| Élément | État | Fichier |
|---|---|---|
| ETA du collecteur | **SIMULÉ** (texte calculé grossièrement, pas de position réelle) | `request_tracking_screen.dart` |
| Reçu / statut de paiement | **SIMULÉ** (« payé » = prix estimé) | `request_tracking_screen.dart`, `collection_request_screen.dart` |
| Avatar utilisateur | **SIMULÉ** (image placeholder ; `avatarFileId` existe mais aucun upload) | `eco_app_bar.dart`, `profile_screen.dart`, `rewards_screen.dart` |
| Revenus collecteur / entreprise | **PARTIEL** : calculés côté client à partir de `collection_requests.amountPaid` × taux ; pas de table `payouts`, pas de demande de versement réelle | `collector_screens.dart` (Earnings), `company_screens.dart` (Revenue) |
| Rapports mairie | **PARTIEL** : CSV local ; PDF attendu de la Function | `admin_screens.dart` |
| Campagnes | **PARTIEL** : in-app seulement, écriture d'une ligne par citoyen depuis le client (lent au-delà de quelques centaines) | `admin_screens.dart` |
| Tournée collecteur | **PARTIEL** : ordre = ordre des demandes, pas d'optimisation ni d'itinéraire routier | `collector_screens.dart` (Tour) |
| Localisation | **PARTIEL** : ARB fr / en présents, la majorité des chaînes sont en dur en français | `shared/lib/l10n/` |
| Tests | **PARTIEL** : 7 tests (widgets d'accueil, badge, fakes auth / report, mapping). Aucun test d'intégration | `shared/test/` |
| Preuve de collecte sans photo | Affiche `proof_placeholder.png` — acceptable comme état vide | `collector_screens.dart` |

### Frontend — spécifique mobile (`mobile/`)
- Icônes et permissions OK ; signature Android **debug** uniquement (pas de keystore de release).
- Aucun test sur appareil iOS réel (build CI sans signature seulement).
- Pas de gestion du refus de permission caméra / localisation (message générique).
- Deep links / notifications push : rien.

### Frontend — spécifique desktop (`desktop/`)
- Fenêtre, icône, titre OK. Aucun installeur (MSI / DMG / AppImage) : la CI livre `.zip` / `.tar.gz` / `.app` non signée.
- Le rôle back-office se choisit par un chip dans Paramètres (aucun contrôle) : à remplacer par les Teams.
- Pas de raccourcis clavier, pas de multi-fenêtres, pas de mise à jour automatique.

### Frontend — spécifique web (`web/`)
- Build OK, splash HTML, manifest PWA. **Plateforme Web non déclarée** dans Appwrite → CORS.
- Pas de service worker personnalisé (cache offline par défaut Flutter seulement).
- Pas de déploiement configuré (Appwrite Sites / Netlify / Nginx).
- `file_picker` et `image_picker` fonctionnent via l'input navigateur ; `geolocator` web nécessite HTTPS.

## Chiffres utiles

- Tables : `users`, `waste_reports`, `collection_requests`, `collectors`,
  `reward_items`, `zones`, `notifications` (détail dans `04`).
- Buckets : `report_photos`, `collection_proofs` (10 Mo, jpg/png/webp/heic).
- Constantes métier (`shared/lib/core/constants/app_constants.dart`) :
  `co2PerKg`, `pointsPerKg`, `collectorFeePerKg`, villes (`Yaoundé`, `Douala`…),
  centres géographiques par ville, préfixe `+237`.
- Providers Appwrite : `accountProvider`, `tablesProvider`, `storageProvider`,
  `realtimeProvider`, `functionsProvider` (`shared/lib/core/appwrite/appwrite_client.dart`).
