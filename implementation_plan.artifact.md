# Plan d'implémentation — Éco-Responsable

Développement complet de l'application Flutter multi-plateforme avec backend Appwrite, suivant les spécifications de design et les contraintes techniques.

## User Review Required

> [!IMPORTANT]
> Les clés d'API et l'endpoint Appwrite sont configurés en dur par défaut dans `AppwriteConfig` à la demande de l'utilisateur, mais il est recommandé d'utiliser `--dart-define` en production.
> Les images seront remplacées par des fichiers vides numérotés (`assets/images/img_1.png`, etc.) pour permettre le remplacement ultérieur.

## Proposed Changes

### 1. Modèles de Données (Shared)
Implémentation des modèles immuables pour Appwrite.
- [NEW] `lib/shared/models/app_user.dart`
- [NEW] `lib/shared/models/waste_report.dart`
- [NEW] `lib/shared/models/collection_request.dart`
- [NEW] `lib/shared/models/reward.dart`

### 2. Feature: Authentification (Mobile/Desktop)
Gestion de la session Appwrite (Phone Auth + OTP).
- [NEW] `lib/features/auth/presentation/screens/welcome_screen.dart` (Écran 1)
- [NEW] `lib/features/auth/presentation/screens/login_screen.dart` (Écran 2)
- [NEW] `lib/features/auth/data/repositories/auth_repository.dart`

### 3. Feature: Dashboard & Accueil (Citoyen)
UI responsive avec widgets personnalisés (StatusBadge, ImpactGauge).
- [NEW] `lib/features/home/presentation/screens/home_screen.dart` (Écran 3)
- [NEW] `lib/core/widgets/impact_gauge.dart`
- [NEW] `lib/core/widgets/status_badge.dart`

### 4. Feature: Signalement & Collecte
Formulaires et intégration cartographique.
- [NEW] `lib/features/reporting/presentation/screens/report_waste_screen.dart` (Écran 4)
- [NEW] `lib/features/collection_request/presentation/screens/request_collection_screen.dart` (Écran 5)

### 5. Feature: Récompenses & Profil
Historique et leaderboard.
- [NEW] `lib/features/rewards/presentation/screens/rewards_screen.dart` (Écran 7)
- [NEW] `lib/features/profile/presentation/screens/profile_screen.dart` (Écran 8)
- [NEW] `lib/features/profile/presentation/screens/history_screen.dart` (Écran 9)

### 6. Feature: Admin (Desktop-first)
Interface de gestion pour les municipalités.
- [NEW] `lib/features/dashboard_admin/presentation/screens/admin_dashboard_screen.dart` (Écran 11)
- [NEW] `lib/features/dashboard_admin/presentation/widgets/admin_sidebar.dart`

## Verification Plan

### Automated Tests
- `flutter test` pour les modèles et repositories.

### Manual Verification
- Lancement sur Android/iOS pour vérifier le responsive mobile.
- Lancement sur Desktop (macOS/Windows/Linux) pour vérifier le layout sidebar/rail.
- Test de la navigation via `go_router`.
