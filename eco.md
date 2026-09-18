# Prompt Android Studio — Génération du projet Flutter complet
## Éco-Responsable — Mobile (Android/iOS) + Desktop (Windows/Linux/macOS) — Backend Appwrite

> À coller tel quel dans l'assistant IA d'Android Studio (Gemini Code Assist ou équivalent) pour générer le projet Flutter complet, dossier par dossier.

---

## PROMPT

Tu es un développeur Flutter senior. Génère un projet Flutter **complet, fonctionnel et compilable**, structuré selon les spécifications ci-dessous. Le projet doit cibler **Android, iOS, Windows, Linux et macOS** à partir d'une base de code unique (mobile + desktop), avec une UI responsive qui s'adapte à la taille d'écran, et se connecter à un backend **Appwrite** auto-hébergé.

### 1. Contexte du projet

**Nom** : Éco-Responsable
**Description** : Plateforme participative de gestion des déchets pour les villes camerounaises. Elle connecte trois profils d'utilisateurs — Citoyen, Collecteur, Administrateur municipal — autour du signalement de décharges sauvages, de la demande de collecte à domicile, du tri incitatif (récompenses) et du suivi statistique pour les municipalités.

### 2. Contraintes techniques obligatoires

- **Flutter** (dernière version stable) avec support multi-plateforme activé : `flutter create --platforms=android,ios,windows,linux,macos`
- **Architecture** : Clean Architecture (couches `presentation`, `domain`, `data`) avec séparation stricte par feature (feature-first)
- **Gestion d'état** : Riverpod
- **Navigation** : `go_router`, avec routes nommées et guards d'authentification basés sur la session Appwrite
- **Backend** : **Appwrite** (BaaS auto-hébergé) via le package officiel `appwrite` (Dart SDK) — voir section 4 pour le détail des services utilisés
- **Persistance locale / offline-first** : `hive` pour la mise en cache locale des signalements/demandes créés hors-ligne, avec file de synchronisation vers Appwrite dès reconnexion
- **Responsive design** : `LayoutBuilder`/`MediaQuery` avec breakpoints distincts mobile (< 600px), tablette (600–1024px), desktop (> 1024px) — navigation par bottom bar sur mobile, par rail/sidebar sur desktop
- **Multilingue** : `flutter_localizations` + fichiers `.arb` pour français (par défaut) et anglais
- **Thème** : `ThemeData` clair avec palette écologique définie en section 6, `ColorScheme.fromSeed` en vert principal
- **Cartographie** : `flutter_map` (OpenStreetMap) pour compatibilité desktop
- **Paiement Mobile Money** : couche d'abstraction `PaymentService`, appelée via une **Appwrite Function** dédiée (webhook Orange Money/MTN MoMo côté serveur, jamais de clé de paiement côté client)
- **Tests** : au moins un test unitaire par repository (avec mock du client Appwrite) et un test de widget par écran principal

### 3. Configuration Appwrite attendue

Génère un fichier `lib/core/appwrite/appwrite_config.dart` centralisant :
```dart
class AppwriteConfig {
  static const endpoint = String.fromEnvironment('APPWRITE_ENDPOINT', defaultValue: 'https://<TON_ENDPOINT>/v1');
  static const projectId = String.fromEnvironment('APPWRITE_PROJECT_ID');
  static const databaseId = 'eco_responsable_db';

  // Collections
  static const usersCollection = 'users';
  static const reportsCollection = 'waste_reports';
  static const requestsCollection = 'collection_requests';
  static const collectorsCollection = 'collectors';
  static const rewardsCollection = 'reward_items';
  static const zonesCollection = 'zones';

  // Storage buckets
  static const reportPhotosBucket = 'report_photos';
  static const collectionProofsBucket = 'collection_proofs';
}
```
Passe les valeurs sensibles (`endpoint`, `projectId`) via `--dart-define` au lancement, jamais en dur dans le code versionné.

### 4. Services Appwrite à intégrer par feature

| Service Appwrite | Usage dans le projet |
|---|---|
| **Account (Auth)** | Inscription/connexion par téléphone + OTP (`account.createPhoneSession` / `updatePhoneSession`), gestion de session, rôles via Teams ou attribut `role` en préférences utilisateur |
| **Databases** | Collections `waste_reports`, `collection_requests`, `collectors`, `reward_items`, `zones`, `users` — avec permissions par document (un citoyen ne voit que ses propres signalements/demandes ; un collecteur voit les demandes de sa zone ; un admin voit tout) |
| **Storage** | Bucket `report_photos` (photos de signalement), bucket `collection_proofs` (preuves de collecte) |
| **Realtime** | Abonnement aux changements sur `waste_reports` (suivi de statut en direct côté citoyen) et sur `collection_requests` (position/statut du collecteur en direct) |
| **Functions** | `matchCollector` (assignation automatique du collecteur le plus proche), `computeRewardPoints` (calcul des points après collecte confirmée), `paymentWebhook` (traitement des retours Mobile Money), `generateAdminReport` (export PDF/CSV pour le dashboard municipal) |
| **Messaging** (optionnel) | Notifications push/SMS de rappel de collecte ou de mise à jour de signalement |

Génère les repositories concrets (`AppwriteReportRepository`, `AppwriteCollectionRequestRepository`, etc.) implémentant les interfaces `domain/repositories/`, avec gestion d'erreurs typée (`AppwriteException` → exceptions métier).

### 5. Rôle de Valkey dans l'architecture (usage serveur uniquement)

Valkey (fork compatible Redis) **n'est jamais appelé directement depuis le client Flutter** — aucun SDK Valkey côté mobile/desktop, pour des raisons de sécurité (pas d'exposition d'un store en clair). Il s'intègre uniquement **côté serveur**, dans les Appwrite Functions ou l'infrastructure auto-hébergée :

- **Si Appwrite est self-hosted** : Valkey peut remplacer directement le Redis interne d'Appwrite (queues, cache, pub/sub) dans le `docker-compose` — configuration infra, pas de code Flutter à produire.
- **Leaderboard éco-citoyen** : l'Appwrite Function `computeRewardPoints` peut écrire dans Valkey via des `ZADD`/`ZRANGE` (sorted sets) pour maintenir un classement en temps réel des utilisateurs par points, exposé ensuite via un endpoint HTTP de la Function que le client Flutter interroge normalement (jamais Valkey en direct).
- **Géolocalisation temps réel des collecteurs** : commandes `GEO` de Valkey pour retrouver rapidement le collecteur disponible le plus proche dans `matchCollector`, en complément (pas en remplacement) des données persistées dans Appwrite Databases.
- **Rate-limiting OTP / cache d'agrégations admin** : protection contre le spam de demandes OTP, cache des statistiques lourdes du dashboard municipal pour éviter de recalculer à chaque requête.

Dans le code Flutter généré, laisse un commentaire `// Valkey: agrégé côté Appwrite Function, consommé ici via HTTP` aux endroits concernés (leaderboard, matching collecteur), **sans ajouter de dépendance Valkey/Redis au `pubspec.yaml`**.

### 6. Palette et identité visuelle à appliquer

```dart
// core/theme/colors.dart
class AppColors {
  static const primaryGreen = Color(0xFF2E7D32);
  static const lightGreen = Color(0xFFA5D6A7);
  static const earthOchre = Color(0xFFD9A441);
  static const institutionalBlue = Color(0xFF1565C0);
  static const neutralBackground = Color(0xFFFAFAF7);
  static const textDark = Color(0xFF212121);
}
```
- Typographie : `google_fonts` avec **Poppins** (titres) et **Inter** (corps de texte)
- Composants signature à créer : `StatusBadge` (signalé/en cours/résolu, code couleur), `ImpactGauge` (jauge circulaire), `RewardBadgeCard` (niveaux bronze/argent/or)

### 7. Structure de dossiers attendue

```
lib/
├── main.dart
├── app.dart (MaterialApp.router, thème, localisation)
├── core/
│   ├── appwrite/ (appwrite_config.dart, appwrite_client.dart)
│   ├── theme/ (colors.dart, text_styles.dart, app_theme.dart)
│   ├── router/ (app_router.dart, route_names.dart)
│   ├── constants/
│   ├── utils/ (responsive_helper.dart)
│   └── widgets/ (composants réutilisables)
├── features/
│   ├── auth/            # Account Appwrite (phone OTP)
│   ├── reporting/        # Databases + Storage (waste_reports)
│   ├── collection_request/ # Databases + Realtime + Functions (matchCollector)
│   ├── collector/
│   ├── rewards/           # Functions (computeRewardPoints) + leaderboard Valkey via HTTP
│   ├── map/
│   ├── dashboard_admin/   # Functions (generateAdminReport), desktop-first
│   └── profile/
├── l10n/ (app_fr.arb, app_en.arb)
└── shared/models/ (User, Report, CollectionRequest, RewardPoint, Zone)
```

### 8. Écrans à générer (avec navigation fonctionnelle entre eux)

**Côté Citoyen**
1. Onboarding (3 slides) → Inscription téléphone/OTP (Appwrite Account) → Sélection ville/quartier
2. Accueil : résumé d'impact (points, kg triés, CO2 évité), actions rapides, notifications
3. Signalement : capture photo (`image_picker` → upload Storage), géolocalisation sur carte, catégorie, confirmation, suivi Realtime du statut
4. Demande de collecte : type/volume, date/heure, récapitulatif paiement, suivi de statut en direct (position collecteur)
5. Carte des points de collecte (`flutter_map`), filtrage par type
6. Récompenses : solde de points, catalogue, classement (leaderboard)
7. Profil : infos, historique, paramètres

**Côté Collecteur**
8. Accueil collecteur : toggle disponibilité, liste des demandes à proximité (résultat de `matchCollector`)
9. Tournée du jour : liste ordonnée des arrêts
10. Confirmation de collecte : preuve photo (Storage), poids/volume

**Côté Administrateur municipal (desktop-first, responsive mobile en lecture seule)**
11. Dashboard : carte de chaleur des signalements, KPIs (données agrégées via `generateAdminReport`)
12. Liste des signalements (table filtrable/triable, DataTable desktop)
13. Détail signalement + affectation manuelle à un opérateur
14. Gestion des zones et opérateurs
15. Rapports (export PDF/CSV via Function)

### 9. Modèles de données à générer (`shared/models/`)

Classes Dart immuables (`freezed` + `json_serializable` recommandé) mappées 1:1 sur les collections Appwrite :
- `AppUser` (id, nom, téléphone, ville, rôle enum {citizen, collector, admin}, points)
- `WasteReport` (id, authorId, photoFileId, lat, lng, category enum, urgency enum, status enum {reported, inProgress, resolved}, createdAt)
- `CollectionRequest` (id, authorId, wasteType, estimatedVolume, scheduledAt, status enum, assignedCollectorId, amountPaid)
- `Collector` (id, coveredZones, isAvailable, interventionsHistory)
- `RewardItem` (id, type enum {mobileMoneyCredit, voucher, partnerPerk}, pointsCost)
- `Zone` (id, city, district, assignedOperators, collectionFrequency)

### 10. Dépendances `pubspec.yaml` attendues

```yaml
dependencies:
  flutter_riverpod:
  go_router:
  appwrite:
  flutter_map:
  latlong2:
  image_picker:
  hive_flutter:
  google_fonts:
  intl:
  freezed_annotation:
  json_annotation:

dev_dependencies:
  build_runner:
  freezed:
  json_serializable:
  flutter_test:
  mockito:
```

### 11. Livrables attendus de ta génération

1. Le projet Flutter complet, code compilable, connecté à Appwrite (pas de mocks en dur — utiliser les vrais appels SDK, avec `--dart-define` pour la config)
2. Un fichier `appwrite/README.md` décrivant les collections, attributs, permissions et Functions à créer côté console Appwrite pour que le projet fonctionne (schéma de chaque collection en tableau)
3. Un `README.md` principal expliquant : lancement mobile (`flutter run -d <device> --dart-define=APPWRITE_ENDPOINT=... --dart-define=APPWRITE_PROJECT_ID=...`) et desktop (`flutter run -d windows/linux/macos`), structure du projet, et note sur le rôle de Valkey côté infra/Functions (jamais côté client)
4. Vérifie que le layout desktop bascule correctement vers une navigation par sidebar et que les écrans admin exploitent l'espace horizontal disponible

### 12. Style de code

- Respecter les conventions Dart officielles (`flutter analyze` sans erreur)
- Commenter les sections clés en français
- Nommer les fichiers en `snake_case`, les classes en `PascalCase`

---
baas appwrite:https://appwrite.kernelforge.codes/
api key for projet: standard_1b9bfc202e7396a4f39a07e5ffbca092a47d1fd6592aa0fd502cfd4d162efdf6242bde02c210692d61e6a7decce49b52f5d853a4069c7fd6fa16f27b666920d9b0787a27710c111c3d79d8b6312b8f62fc045c37e25501ea9206d20cd19159010c1aad42734e0f23d34dc17274190fc0d71f6797746ca54ccb11e76238db8ba2
project info: Eco-Res
6aad2f1a000a6a6de281

0 B
Bande passante
30 jours
Aucune donnée à afficher

0
Demandes
30 jours
Aucune donnée à afficher

Base de données
0
Documents
Bases de données : 0
Stockage
0 B
Stockage
Seaux : 0
Authentification
0
Utilisateurs
Fonctions
0
Exécutions
0
Connexions en temps réel
Aucune donnée à afficher

Commencez avec Realtime
Intégrations
Plateformes
vide
Créez une plateforme pour démarrer.
Besoin d'aide ? Consultez notre documentation pour en savoir plus.

Version 1.6.1
Documents
Termes
Confidentialité
© 2026 Appwrite. Tous droits réservés.
Console - Appwrite
Logo Appwrite
Génère maintenant l'arborescence complète du projet, fichier par fichier, en commençant par `pubspec.yaml`, puis `core/appwrite/`, puis `core/` restant, puis chaque feature dans l'ordre listé en section 8.
specifcation pour le mobile:
Ajouter une plateforme Flutter

Paramètres
FACULTATIF

Installer

Importer

Construire
Enregistrement du nom du paquet

Nom
eco-respo mobile
Nom du paquet
com.eco.kf
Console - Appwrite
Logo Appwrite

Add a Flutter platform

Settings
OPTIONAL

Install

Import

Build
Install
Add Appwrite SDK to your package's pubspec.yaml file. You can view an example here.

dependencies:
appwrite: ^13.0.0
You can also install the SDK using the Dart package manager from your terminal.

flutter pub add appwrite
Console - Appwrite
Appwrite Logo

Add a Flutter platform

Settings
OPTIONAL

Install

Import

Build
Initialize
Initialize your SDK
Initialize your SDK by pointing the client to your Appwrite project using your
Project ID


import 'package:appwrite/appwrite.dart';

Client client = Client();
client
.setEndpoint('https://appwrite.kernelforge.codes/v1')
.setProject('6aad2f1a000a6a6de281')
.setSelfSigned(status: true); // For self signed certificates, only use for development;
Before sending any API calls to your new Appwrite project, make sure your device or emulator has network access to your Appwrite project's hostname or IP address.

For self-hosted solutions
When connecting to a locally hosted Appwrite project from an emulator or a mobile device, you should use the private IP of the device running your Appwrite project as the hostname of the endpoint instead of localhost. You can also use a service like ngrok to proxy the Appwrite server.

Console - Appwrite
Appwrite Logo

cle totp base 32