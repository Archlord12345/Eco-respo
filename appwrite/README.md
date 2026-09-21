# Schéma Appwrite — Éco-Responsable

Endpoint : `https://fra.cloud.appwrite.io/v1`  
Project ID : `eco-responsable-cm`  
Database ID : `eco_responsable_db` (API **TablesDB**)  
Organisation Cloud : `6a8c3a75eab6eb87c22e`, région `fra`

Source de vérité du schéma : `tool/gen_appwrite_config.py`, qui régénère les
sections `tablesDB`, `tables` et `buckets` de `appwrite.config.json`. Le
fichier est ensuite poussé avec la CLI officielle :

```bash
appwrite login
python3 tool/gen_appwrite_config.py
appwrite push settings -f
appwrite push table --all -f
appwrite push bucket --all -f
```

`tool/appwrite_cli_init.sh` enchaîne tout cela (création du projet et des
plateformes si absents, push, données de départ) et peut être relancé sans
risque.

La **clé API serveur** ne doit jamais être embarquée dans l’app Flutter. Elle
sert uniquement à `tool/appwrite.sh` (via `.env`, jamais commité).
L’administration courante passe par la CLI connectée (`appwrite login`).

## Plateformes

Toutes les plateformes partagent l’identifiant applicatif `com.eco.kf` :

| ID | Type Appwrite | Nom | Identifiant |
|---|---|---|---|
| `eco-android` | `android` | `eco-respo mobile` | `com.eco.kf` |
| `eco-apple` | `apple` (iOS + macOS) | `eco-respo apple` | `com.eco.kf` |
| `eco-linux` | `linux` | `eco-respo linux` | `com.eco.kf` |
| `eco-windows` | `windows` | `eco-respo windows` | `com.eco.kf` |

Initialisation côté Flutter (`lib/core/appwrite/`) :

```dart
final client = Client()
  ..setEndpoint('https://fra.cloud.appwrite.io/v1')
  ..setProject('eco-responsable-cm');
final tables = TablesDB(client);   // listRows / getRow / createRow / upsertRow / updateRow
```

Ne pas activer `setSelfSigned(true)` sur l’endpoint de production.

## Client Flutter ↔ Appwrite

| Besoin | API utilisée |
|---|---|
| Compte | `Account.create`, `createEmailPasswordSession`, `get`, `updateName`, `deleteSessions` |
| Profil | table `users`, `rowId = userId`, `upsertRow` avec permissions propriétaire |
| Données | `TablesDB.listRows` avec `Query.equal / orderDesc / limit / contains` |
| Temps réel | `Realtime.subscribe([Channel.tablesdb(db).table(t).row()])` → `tablesdb.<db>.tables.<t>.rows` |
| Fichiers | `Storage.createFile` (`InputFile.fromBytes`) dans `report_photos` / `collection_proofs` |
| Serveur | `Functions.createExecution` uniquement (matching, points, paiement, rapports) |

Permissions posées par l’app à la création d’une ligne :
`read/update(user:<auteur>)` + `read/update(users)`.

## Vérification de l’instance

```bash
tool/appwrite.sh tables
tool/appwrite.sh rows reward_items
tool/appwrite.sh rows zones
tool/appwrite.sh buckets
tool/appwrite.sh functions
```

Sans clé, une lecture publique suffit pour vérifier les tables `read(any)` :

```bash
curl -H 'X-Appwrite-Project: eco-responsable-cm' \
  https://fra.cloud.appwrite.io/v1/tablesdb/eco_responsable_db/tables/zones/rows
```

État vérifié le 21 septembre 2026 : base, sept tables avec colonnes et index,
deux buckets ; `reward_items` contient trois lignes et `zones` cinq lignes.
Aucune Function ni provider Messaging n’est encore déployé.

## Tables

Permissions table (MVP) : `read(any)`, `create/update/delete(users)` +
**row security** activée. À durcir ensuite avec Teams `admins` / `collectors`.

### `users` — index `phone_idx`, `role_idx`

| Colonne | Type | Notes |
|---|---|---|
| name | varchar 128 | |
| phone | varchar 32 | |
| email | varchar 128 | |
| city | varchar 64 | défaut `Yaoundé` |
| district | varchar 64 | |
| role | enum `citizen`, `collector`, `admin` | défaut `citizen` |
| points | integer | défaut 0 |
| language | varchar 8 | `fr` / `en` |
| notificationsEnabled | boolean | défaut `true` |
| avatarFileId | varchar 64 | |
| level | varchar 32 | `bronze` / `silver` / `gold` |

### `waste_reports` — index `author_idx`, `status_idx`, `city_idx`

| Colonne | Type | Notes |
|---|---|---|
| authorId | varchar 64 **requis** | |
| photoFileId | varchar 64 | bucket `report_photos` |
| lat / lng | double **requis** | |
| category | enum `menager`, `plastique`, `electronique`, `encombrant` **requis** | |
| urgency | enum `faible`, `moyen`, `eleve`, `critique` **requis** | |
| status | enum `reported`, `inProgress`, `resolved` | défaut `reported` |
| address | varchar 255 | |
| description | varchar 1000 | |
| assignedOperatorId | varchar 64 | |
| city | varchar 64 | |
| reportedAt | datetime | |

### `collection_requests` — index `author_req_idx`, `collector_idx`, `req_status_idx`

| Colonne | Type | Notes |
|---|---|---|
| authorId | varchar 64 **requis** | |
| wasteType | enum (mêmes valeurs que `category`) **requis** | |
| estimatedVolume | enum `petit`, `moyen`, `grand`, `tres_grand` **requis** | |
| scheduledAt | datetime | |
| status | enum `pending`, `matched`, `enRoute`, `collected`, `cancelled` | défaut `pending` |
| assignedCollectorId | varchar 64 | |
| amountPaid | integer | XAF, défaut 0 |
| isRecurring | boolean | défaut `false` |
| paymentProvider | varchar 32 | `mtn` / `orange` / `afriland` |
| weightKg | double | |
| proofFileId | varchar 64 | bucket `collection_proofs` |
| address | varchar 255 | |
| timeSlot | varchar 32 | |

### `collectors` — index `user_idx`

| Colonne | Type | Notes |
|---|---|---|
| userId | varchar 64 **requis** | |
| coveredZones | varchar 64 [] | ids de `zones` |
| isAvailable | boolean | défaut `false` |
| interventionsCount | integer | défaut 0 |
| displayName, phone, company | varchar | |

### `reward_items`

| Colonne | Type | Notes |
|---|---|---|
| type | enum `mobileMoneyCredit`, `voucher`, `partnerPerk` **requis** | |
| pointsCost | integer **requis** | |
| title | varchar 128 **requis** | |
| description | varchar 255 | |
| imageKey | varchar 64 | `reward_mtn` / `reward_voucher` / `reward_partner` (asset local) |
| enabled | boolean | défaut `true` |

Données de départ : `rw_mtn` (1 000 pts), `rw_voucher` (1 500 pts), `rw_partner` (2 000 pts).

### `zones`

| Colonne | Type | Notes |
|---|---|---|
| city | varchar 64 **requis** | |
| district | varchar 64 **requis** | |
| assignedOperators | varchar 64 [] | |
| collectionFrequency | varchar 64 | |
| color | varchar 16 | hex |
| centerLat / centerLng | double | |

Données de départ : `z_centre`, `z_nord`, `z_est`, `z_ouest`, `z_sud` (Yaoundé).

### `notifications` — index `notif_user_idx`

| Colonne | Type | Notes |
|---|---|---|
| userId | varchar 64 **requis** | |
| title | varchar 128 **requis** | |
| body | varchar 255 | |
| kind | varchar 32 | `collecte` / `points` / `map` (icône côté app) |
| read | boolean | défaut `false` |
| createdAt | datetime | |

## Storage

| Bucket | ID | Usage |
|---|---|---|
| Report photos | `report_photos` | photos de signalement |
| Collection proofs | `collection_proofs` | preuves de collecte |

Extensions : jpg, jpeg, png, webp, heic. Taille max 10 Mo. Sécurité par
fichier activée, chiffrement activé.

## Functions (côté serveur — Valkey ici uniquement)

| Function ID | Rôle | Appel client |
|---|---|---|
| `matchCollector` | Assignation du collecteur le plus proche | après `createRow` sur `collection_requests` |
| `computeRewardPoints` | Points après collecte, échange, classement | écran Récompenses |
| `paymentWebhook` | Retours Orange Money / MTN MoMo / Afriland | démarrage d’un paiement |
| `generateAdminReport` | Export PDF / CSV du tableau de bord | back-office |

Le client n’appelle que `Functions.createExecution` et tolère leur absence
(repli sur la table `users` pour le classement, statut `pending` pour le
paiement).
