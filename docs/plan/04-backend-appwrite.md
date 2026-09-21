# 04 — Backend Appwrite (périmètre des 2 ingénieurs backend)

Projet Appwrite Cloud `eco-responsable-cm`, région `fra`, endpoint
`https://fra.cloud.appwrite.io/v1`, base `eco_responsable_db`. Schéma source :
`tool/gen_appwrite_config.py` → `appwrite.config.json` → `appwrite push`.

## 1. Schéma existant

Permissions table (MVP, à durcir) : `read(any)`, `create(users)`,
`update(users)`, `delete(users)`, **row security activée**.

### `users` (rowId = `$id` du compte Account)
| Colonne | Type | Notes |
|---|---|---|
| name | varchar 128 | |
| phone | varchar 32 | `+237…` |
| email | varchar 128 | vide pour les comptes téléphone |
| city | varchar 64 | défaut `Yaoundé` |
| district | varchar 64 | quartier |
| role | enum `citizen` `collector` `operator` `admin` | défaut `citizen` — **auto-déclaré aujourd'hui** |
| points | integer | défaut 0 |
| language | varchar 8 | `fr` / `en` |
| notificationsEnabled | boolean | défaut true |
| avatarFileId | varchar 64 | jamais renseigné aujourd'hui |
| level | varchar 32 | `bronze` / `silver` / `gold` |
Index : `phone_idx(phone)`, `role_idx(role)`.

### `waste_reports`
| Colonne | Type |
|---|---|
| authorId* | varchar 64 |
| photoFileId | varchar 64 (bucket `report_photos`) |
| lat*, lng* | double |
| category* | enum `menager` `plastique` `electronique` `encombrant` |
| urgency* | enum `faible` `moyen` `eleve` `critique` |
| status | enum `reported` `inProgress` `resolved` (défaut `reported`) |
| address | varchar 255 |
| description | varchar 1000 |
| assignedOperatorId | varchar 64 (id d'une ligne `collectors`) |
| city | varchar 64 |
| reportedAt, resolvedAt | datetime |
Index : `author_idx`, `status_idx`, `city_idx`.

### `collection_requests`
| Colonne | Type |
|---|---|
| authorId* | varchar 64 |
| wasteType* | enum (mêmes valeurs) |
| estimatedVolume* | enum `petit` `moyen` `grand` `tres_grand` |
| scheduledAt | datetime |
| status | enum `pending` `matched` `enRoute` `collected` `cancelled` |
| assignedCollectorId | varchar 64 (id ligne `collectors`) |
| amountPaid | integer (XAF) — **aujourd'hui = prix estimé, pas un paiement** |
| isRecurring | boolean |
| paymentProvider | varchar 32 (`mtn`, `orange`, `afriland`) |
| weightKg | double |
| proofFileId | varchar 64 (bucket `collection_proofs`) |
| address, timeSlot, city, notes | varchar |
| lat, lng | double |
| collectedAt | datetime |
Index : `author_req_idx`, `collector_idx`, `req_status_idx`.

### `collectors`
`userId*`, `coveredZones` (varchar[]), `isAvailable` (bool), `interventionsCount`
(int), `displayName`, `phone`, `company`. Index `user_idx`.

### `reward_items`
`type*` enum `mobileMoneyCredit` `voucher` `partnerPerk`, `pointsCost*`,
`title*`, `description`, `imageKey`, `enabled`.

### `zones`
`city*`, `district*`, `assignedOperators` (varchar[] d'ids `collectors`),
`collectionFrequency`, `color` (`#RRGGBB`), `centerLat`, `centerLng`.

### `notifications`
`userId*`, `title*`, `body`, `kind` (`status`, `collect`, `points`, `alert`,
`campaign`, `info`), `read`, `createdAt`, `refType` (`report` | `request`),
`refId`. Index `notif_user_idx`.

### Buckets
`report_photos`, `collection_proofs` : 10 Mo, `jpg jpeg png webp heic`,
chiffrés, file security activée, mêmes permissions que les tables.

## 2. Évolutions de schéma à livrer

| Table / colonne | Pourquoi |
|---|---|
| **`collector_positions`** (nouvelle) : `collectorId*`, `lat*`, `lng*`, `heading`, `speed`, `updatedAt*`, `requestId` ; index `collector_pos_idx(collectorId)`. Permissions : `create/update(user:<collecteur>)`, `read(users)`. Une ligne par collecteur (`rowId = collectorId`, `upsertRow`). | Position en direct → suivi citoyen, dispatch, ETA |
| **`collection_points`** (nouvelle) : `city*`, `name*`, `type` enum `bac` `decheterie` `point_tri` `composteur`, `lat*`, `lng*`, `acceptedTypes` (varchar[]), `openingHours`, `zoneId`, `enabled`. | La carte affiche aujourd'hui les centres de `zones` faute de mieux |
| **`payments`** (nouvelle) : `requestId*`, `userId*`, `provider*`, `amountXaf*`, `status` enum `initiated` `pending` `success` `failed` `refunded`, `providerRef`, `phone`, `createdAt`, `confirmedAt`, `raw` (varchar 2000). Index `payment_request_idx`, `payment_user_idx`. | Paiement Mobile Money réel et traçable |
| **`payouts`** (nouvelle) : `collectorId*`, `amountXaf*`, `status` `requested` `paid` `rejected`, `periodStart`, `periodEnd`, `requestedAt`, `paidAt`, `providerRef`. | Versements collecteurs / entreprise |
| **`points_ledger`** (nouvelle) : `userId*`, `delta*` (int), `reason` (`collect`, `report_resolved`, `redeem`, `bonus`), `refType`, `refId`, `createdAt`. | Historique et audit des points ; `users.points` devient un cache recalculable |
| `zones.polygon` (varchar 8000, GeoJSON) | Zones en polygone pour la mairie |
| `collection_requests.paymentStatus` enum `unpaid` `pending` `paid` `failed`, `paymentId` | Statut de paiement lisible par le client |
| `collection_requests.etaMinutes` (int), `distanceKm` (double) | Renseignés par `matchCollector` / mise à jour position |
| `users.pushTargetId` (varchar 64), `users.teamRoles` (optionnel) | Push Messaging |
| `collectors.rating` (double), `collectors.operatorId` (varchar 64 → id du `users` opérateur) | Rattachement explicite à une entreprise |

Mettre à jour `tool/gen_appwrite_config.py`, régénérer, `appwrite push`,
puis **les modèles Dart correspondants** (`shared/lib/shared/models/`) en
coordination avec les frontends.

## 3. Sécurité : Teams et permissions

Aujourd'hui, un utilisateur peut se donner le rôle `admin` en modifiant
`users.role`. À faire :

1. Créer les **Teams** `admins`, `operators`, `collectors`. L'appartenance
   est gérée par une Function `manageRole` (voir §4) ou manuellement dans la
   console pour les premiers comptes.
2. Permissions par table :
   - `waste_reports` : `create(users)`, `read(users)`, `update(team:admins)`,
     `update(team:operators)` + owner update limité (annulation).
   - `collection_requests` : `create(users)`, `read(user:auteur)`,
     `read(team:collectors)`, `read(team:operators)`, `read(team:admins)`,
     `update(team:collectors)`, `update(team:operators)`.
   - `collectors` : `read(users)`, `create/update(team:operators)`,
     `update(user:<collecteur>)` (disponibilité).
   - `zones`, `collection_points`, `reward_items` : `read(any)`,
     `create/update/delete(team:admins)`.
   - `notifications` : `create` réservé aux Functions (clé API), `read/update(user:<destinataire>)`.
   - `users.points`, `users.role`, `users.level` : **plus modifiables par le
     client** — passer par les Functions (`computeRewardPoints`, `manageRole`).
     Approche : row permission `update(user:<id>)` retirée ; profil mis à
     jour via Function `updateProfile` ou champs séparés dans une table
     `user_settings` modifiable par l'utilisateur (name, phone, city,
     district, language, notificationsEnabled, avatarFileId).
3. Le client Flutter lit le rôle effectif depuis les Teams
   (`Teams.list()` côté client) et `AppTarget.homeFor` s'appuie dessus.

## 4. Functions à écrire (Node.js 20 recommandé ; Dart possible)

Toutes les Functions : déploiement via `appwrite push function`, variables
d'environnement (`APPWRITE_API_KEY` scope minimal, clés fournisseurs), logs
activés, timeout 15 s, et **contrat JSON figé J1**. Réponses en JSON
`{ ok: bool, data?, error? }` (le client lit `responseBody`).

### 4.1 `matchCollector`
- Déclencheur : exécution HTTP par le client après création d'une demande **et** événement `databases.*.tables.collection_requests.rows.*.create`.
- Entrée : `{ "requestId": "…" }`.
- Logique : charger la demande ; candidats = `collectors` avec `isAvailable=true`, `coveredZones` ∩ {district, city} ≠ ∅ ou position (`collector_positions`) à < 8 km ; trier par distance puis `interventionsCount` croissant ; affecter → `status=matched`, `assignedCollectorId`, `etaMinutes`, `distanceKm` ; notification au citoyen (`kind=collect`, `refType=request`) et au collecteur ; push si `pushTargetId`.
- Sortie : `{ ok, data: { collectorId, etaMinutes } }` ou `{ ok: false, error: "no_collector" }` (la demande reste `pending`, visible au dispatch).
- Client : `appwrite_report_repository.dart` (`create`), `request_tracking_screen.dart`.

### 4.2 `computeRewardPoints`
- Entrée : `{ "action": "collect", "requestId" }` | `{ "action": "report_resolved", "reportId" }` | `{ "action": "redeem", "userId", "itemId" }`.
- Logique : calcul autoritaire (`pointsPerKg` = valeur de `AppConstants`, à porter en variable d'env), écriture `points_ledger`, mise à jour `users.points` et `users.level` (seuils Bronze 0 / Argent 1000 / Or 3000), idempotence par `refId` (pas deux crédits pour la même collecte), refus si solde insuffisant.
- Sortie : `{ ok, data: { points: <nouveau solde>, delta } }`. **Le client attend un entier** aujourd'hui (`int.tryParse(ex.responseBody)`) → aligner le client sur le JSON.
- Déclencheur secondaire : événement `collection_requests.rows.*.update` quand `status` passe à `collected` (supprime la dépendance au client).
- Client : `collector_actions.dart` (`confirm`), `appwrite_report_repository.dart` (`redeem`).

### 4.3 `initPayment` (nouvelle) et `paymentWebhook`
- `initPayment` entrée : `{ "requestId", "provider": "mtn"|"orange", "phone", "amountXaf" }` ; crée `payments(status=initiated)`, appelle l'API fournisseur (MTN MoMo Collections `requesttopay` ; Orange Money Web Payment), stocke `providerRef`, passe `pending` ; sortie `{ ok, data: { paymentId, status, redirectUrl? } }`.
- `paymentWebhook` : endpoint public (exécution HTTP `POST` sans session) recevant la notification fournisseur ; vérifie signature / statut auprès du fournisseur ; met `payments.status=success|failed`, `collection_requests.paymentStatus`, `amountPaid` réel ; notification citoyen ; en cas d'échec, `status=failed` et push.
- Repli si contrats marchands non signés à J7 : mode **sandbox** des deux fournisseurs (MTN MoMo Sandbox User Provisioning ; Orange Developer sandbox) ; documenter la bascule prod (variables d'env seulement).
- Client : `AppwritePaymentService.startCheckout` → appeler `initPayment`, puis écouter `payments` en Realtime dans `request_tracking_screen.dart`.

### 4.4 `updateCollectorPosition` (nouvelle) ou écriture directe
- Option simple : le collecteur écrit directement `collector_positions` via `upsertRow` toutes les 10–15 s (permission `update(user:<lui>)`). Pas de Function nécessaire.
- Option Function (recommandée si ETA) : entrée `{ lat, lng, heading, speed, requestId? }` ; met à jour la position et recalcule `collection_requests.etaMinutes` via OSRM (`router.project-osrm.org/route/v1/driving/…`) pour la demande `enRoute`.

### 4.5 `generateAdminReport`
- Entrée : `{ "kind": "general"|"zone"|"operator"|"reports", "city", "from", "to" }`.
- Logique : agrégations sur `waste_reports`, `collection_requests`, `collectors`, `payments` ; génération **PDF** (pdfkit / puppeteer-core) et CSV ; upload dans un bucket `reports` (nouveau, `read(team:admins)`) ; sortie `{ ok, data: { fileId, url, csvFileId } }`.
- Client : `admin_screens.dart` (`_generate`) ouvre `url`.

### 4.6 `sendCampaign` (nouvelle)
- Entrée : `{ "title", "body", "kind": "campaign"|"alert"|"info", "city", "district"?: string }`.
- Logique : cible `users` (role citizen, ville, quartier), écrit les lignes `notifications` par lots, envoie un push Messaging (topic par ville / quartier). Sortie `{ ok, data: { recipients } }`.
- Client : remplace la boucle client de `admin_screens.dart` (`_send`).

### 4.7 `manageRole` (nouvelle)
- Entrée : `{ "userId", "role": "admin"|"operator"|"collector"|"citizen", "operatorId"? }` ; réservé `team:admins` (vérifier le JWT / l'appelant) ; ajoute/retire des Teams, met `users.role`, crée la fiche `collectors` si besoin.
- Client : Paramètres desktop (remplace le chip d'auto-attribution), écran Flotte (création d'un collecteur avec compte).

### 4.8 `reverseGeocode` (nouvelle, optionnelle)
- Entrée `{ lat, lng }` → Nominatim (`nominatim.openstreetmap.org/reverse`, User-Agent obligatoire, 1 req/s) avec cache dans une table `geocode_cache` ; sortie `{ ok, data: { address, district } }`. Évite d'exposer Nominatim au trafic client.

### 4.9 `onUserCreate` (événement `users.*.create`)
- Crée la ligne `users` par défaut (aujourd'hui fait par le client), enregistre le `pushTargetId` ultérieurement.

## 5. Messaging (push)

- Providers : **FCM** (Android, web) et **APNs** (iOS) dans Appwrite Messaging.
- Client : `firebase_messaging` (ou plugin équivalent) → `Account.createPushTarget(providerId, identifier)` ; stocker `targetId` dans `users.pushTargetId`.
- Topics : `city:<ville>`, `district:<ville>:<quartier>`, `role:collector:<ville>`.
- Envoi depuis les Functions (`Messaging.createPush`). Les notifications in-app (table) restent la source de vérité du fil.

## 6. Seeds et données de démonstration

Étendre `tool/appwrite_cli_init.sh` (ou une Function `seed` protégée) :
zones Douala (Akwa, Bonanjo, Bonapriso, Deïdo, New-Bell), `collection_points`
(≥ 10 par ville avec horaires), 2 opérateurs (`Propre Cité SARL`, `Hysacam
Partenaire`), 6 collecteurs (3 par opérateur, comptes téléphone + code),
1 admin mairie par ville, 5 récompenses, 30 signalements et 20 demandes
répartis sur 30 jours (pour les graphiques), positions initiales des
collecteurs.

## 7. Exploitation

- Deux projets : `eco-responsable-staging` (Functions en dev, sandbox
  paiements) et `eco-responsable-cm` (prod). Variables CI par environnement.
- Logs des Functions activés ; alerte email sur échec (Appwrite Webhooks →
  Slack/Email).
- Sauvegardes : export hebdomadaire des tables via `appwrite pull` +
  script `tool/appwrite.sh` (cron GitHub Actions).
- Quotas Cloud à surveiller : exécutions Functions, bande passante Storage,
  Realtime connexions.

## 8. Livrables backend attendus (résumé)

1. Schéma étendu (§2) poussé + modèles Dart mis à jour avec les frontends.
2. Teams + permissions durcies (§3) + `manageRole`.
3. Functions `matchCollector`, `computeRewardPoints`, `initPayment`,
   `paymentWebhook`, `updateCollectorPosition`, `sendCampaign`,
   `generateAdminReport`, `reverseGeocode`, `onUserCreate` déployées en
   staging puis prod, avec README par Function (`appwrite/functions/<nom>/`).
4. Messaging FCM / APNs configuré, topics créés.
5. Seeds complets Yaoundé + Douala.
6. Plateforme **Web** déclarée (nom d'hôte de déploiement).
7. Documentation mise à jour : `appwrite/README.md`, `tool/gen_appwrite_config.py`.
