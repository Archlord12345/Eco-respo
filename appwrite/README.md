# Schéma Appwrite — Éco-Responsable

Endpoint : `https://appwrite.kernelforge.codes/v1`  
Project ID : `6aad2f1a000a6a6de281`  
Database ID : `eco_responsable_db`

La **clé API serveur** ne doit jamais être embarquée dans l’app Flutter. Elle sert uniquement à la console / `tool/setup_appwrite.py`.

Plateformes Flutter à enregistrer : type `flutter-android` / `flutter-ios` / `flutter-linux` / `flutter-macos` / `flutter-windows`, clé `com.eco.kf`.

## Plateformes desktop

Les trois plateformes desktop utilisent le même endpoint, le même Project ID et
le même identifiant applicatif :

| Type Appwrite | Nom | Identifiant |
|---|---|---|
| `flutter-linux` | `eco-respo linux` | `com.eco.kf` |
| `flutter-macos` | `eco-respo macos` | `com.eco.kf` |
| `flutter-windows` | `eco-respo windows` | `com.eco.kf` |

Le script `tool/setup_appwrite.py` crée ces plateformes en plus des plateformes
Android et iOS. L'initialisation côté desktop reste :

```dart
final client = Client()
	..setEndpoint('https://appwrite.kernelforge.codes/v1')
	..setProject('6aad2f1a000a6a6de281');
```

Ne pas activer `setSelfSigned(true)` sur l'endpoint de production. Ce réglage
est uniquement destiné à une instance locale avec certificat autosigné.

## Collections

Permissions collection (MVP) : `read(any)`, `create/update/delete(users)` + **document security** activé. À durcir ensuite avec Teams `admins` / `collectors`.

### `users`

| Attribut | Type | Notes |
|---|---|---|
| name | string 128 | |
| phone | string 32 | index |
| email | string 128 | |
| city | string 64 | défaut Yaoundé |
| district | string 64 | |
| role | enum `citizen`, `collector`, `admin` | |
| points | integer | |
| language | string 8 | `fr` / `en` |
| notificationsEnabled | boolean | |
| avatarFileId | string 64 | |
| level | string 32 | bronze / argent / or |

### `waste_reports`

| Attribut | Type | Notes |
|---|---|---|
| authorId | string 64 required | index |
| photoFileId | string 64 | bucket `report_photos` |
| lat / lng | float | |
| category | enum `menager`, `plastique`, `electronique`, `encombrant` | |
| urgency | enum `faible`, `moyen`, `eleve`, `critique` | |
| status | enum `reported`, `inProgress`, `resolved` | |
| address | string 255 | |
| description | string 1000 | |
| assignedOperatorId | string 64 | |
| city | string 64 | |
| reportedAt | datetime | |

### `collection_requests`

| Attribut | Type | Notes |
|---|---|---|
| authorId | string 64 required | |
| wasteType | enum (mêmes que category) | |
| estimatedVolume | enum `petit`, `moyen`, `grand`, `tres_grand` | |
| scheduledAt | datetime | |
| status | enum `pending`, `matched`, `enRoute`, `collected`, `cancelled` | |
| assignedCollectorId | string 64 | |
| amountPaid | integer | XAF |
| isRecurring | boolean | |
| paymentProvider | string 32 | `mtn` / `orange` / `afriland` |
| weightKg | float | |
| proofFileId | string 64 | bucket `collection_proofs` |
| address | string 255 | |
| timeSlot | string 32 | |

### `collectors`

| Attribut | Type | Notes |
|---|---|---|
| userId | string 64 required | |
| coveredZones | string[] | ids de `zones` |
| isAvailable | boolean | |
| interventionsCount | integer | |
| displayName, phone, company | string | |

### `reward_items`

| Attribut | Type | Notes |
|---|---|---|
| type | enum `mobileMoneyCredit`, `voucher`, `partnerPerk` | |
| pointsCost | integer required | |
| title | string 128 | |
| description | string 255 | |
| imageKey | string 64 | nom d’asset local |
| enabled | boolean | |

### `zones`

| Attribut | Type | Notes |
|---|---|---|
| city | string 64 | |
| district | string 64 | |
| assignedOperators | string[] | |
| collectionFrequency | string 64 | |
| color | string 16 | |
| centerLat / centerLng | float | |

### `notifications`

| Attribut | Type | Notes |
|---|---|---|
| userId | string 64 | |
| title / body | string | |
| kind | string 32 | |
| read | boolean | |
| createdAt | datetime | |

## Storage

| Bucket | ID | Usage |
|---|---|---|
| Report photos | `report_photos` | photos de signalement |
| Collection proofs | `collection_proofs` | preuves de collecte |

Extensions : jpg, jpeg, png, webp, heic. Taille max 10 Mo.

## Functions (côté serveur, Valkey ici uniquement)

| Function ID | Rôle |
|---|---|
| `matchCollector` | Assignation du collecteur le plus proche |
| `computeRewardPoints` | Points après collecte + leaderboard |
| `paymentWebhook` | Retours Orange Money / MTN MoMo |
| `generateAdminReport` | Export PDF/CSV dashboard |

Le client n’appelle que `Functions.createExecution`. Auth téléphone : `Account.createPhoneToken` puis `Account.createSession` (SDK 13, Appwrite 1.6).
