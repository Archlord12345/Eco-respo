# 05 — Frontend mobile (ingénieur mobile)

App `mobile/` (`runEcoApp(AppTarget.mobile)`) : espaces **citoyen** et
**collecteur**. Android (`com.eco.kf`) et iOS. Le code vit dans `shared/`.

## Écrans et état

| Route | Écran (fichier dans `shared/lib/features/`) | État | Reste à faire |
|---|---|---|---|
| `/splash`, `/onboarding` | `auth/presentation/splash_screen.dart`, `onboarding_screen.dart` | RÉEL | — |
| `/welcome`, `/login`, `/register` | `welcome_screen.dart`, `login_screen.dart`, `register_phone_screen.dart` | RÉEL | Message clair si numéro déjà utilisé ; « code oublié » (réinitialisation par admin ou via email si renseigné) |
| `/city` | `city_select_screen.dart` | RÉEL | Proposer la ville détectée par GPS |
| `/home` | `home/presentation/home_screen.dart` | RÉEL | Brancher `points_ledger` pour « derniers gains » ; état vide soigné |
| `/report` | `reporting/presentation/report_screen.dart` | RÉEL | Adresse par **reverse geocoding** (Function `reverseGeocode`) ; carte de confirmation de position déplaçable ; gestion refus permission caméra / GPS ; compression image (< 1 Mo) |
| `/report/:id` | `report_detail_screen.dart` | RÉEL | Bouton « Partager », « Signaler à nouveau » |
| `/collect` | `collection_request/presentation/collection_request_screen.dart` | PARTIEL | **Paiement réel** : appeler `initPayment`, écran d'attente de confirmation (Realtime sur `payments`), gestion échec / relance ; carte pour ajuster la position ; récapitulatif prix |
| `/collect/:id` | `request_tracking_screen.dart` | PARTIEL | **Position du collecteur en direct** (`collector_positions` Realtime) affichée sur la carte, ETA depuis `etaMinutes`, reçu de paiement depuis `payments`, bouton annuler (si `pending`/`matched`), notation du collecteur après `collected` |
| `/map` | `map/presentation/map_screen.dart` | RÉEL | Brancher `collection_points` (au lieu des centres de `zones`), clustering au-delà de 200 marqueurs, fiche d'un point (horaires, types acceptés), itinéraire in-app (polyline OSRM) — voir `08` |
| `/rewards` | `rewards/presentation/rewards_screen.dart` | PARTIEL | Après déploiement de `computeRewardPoints` : lire le JSON `{ ok, data.points }`, supprimer le repli client ; historique des échanges (`points_ledger`) |
| `/notifications` | `notifications/presentation/notifications_screen.dart` | RÉEL | Push : réception FCM en premier plan / arrière-plan, tap → route via `refType/refId` |
| `/profile`, `/history`, `/settings` | `profile/`, `settings/` | RÉEL | Upload avatar (`users.avatarFileId`, bucket `avatars` à créer ou `report_photos`), suppression de compte (RGPD), localisation en/fr effective |
| `/collector` | `collector/presentation/collector_screens.dart` (Home) | RÉEL | **Publication de position** toutes les 10–15 s quand disponible (`geolocator` stream → `collector_positions.upsertRow` ou Function) ; service en arrière-plan Android (foreground service) |
| `/collector/tour` | Tour | PARTIEL | Itinéraire routier OSRM entre arrêts, ordre optimisé (plus proche voisin), navigation externe conservée |
| `/collector/confirm/:id` | Confirm | RÉEL | Compression photo, mode hors ligne (déjà `SyncQueue`, à tester), lire le solde renvoyé par la Function |
| `/collector/history`, `/collector/earnings` | History, Earnings | PARTIEL | Brancher `payouts` : demande de versement réelle, statut, historique ; revenus depuis `payments.success` plutôt que `amountPaid` |

## Chantiers spécifiques mobile

1. **Push notifications** : `firebase_messaging` + `flutter_local_notifications`,
   fichiers `google-services.json` / `GoogleService-Info.plist` (à ne pas
   committer : secrets CI + `dart-define` ou fichiers chiffrés), enregistrement
   du push target Appwrite, gestion du tap.
2. **Localisation en arrière-plan (collecteur)** : permission
   `ACCESS_BACKGROUND_LOCATION` justifiée, notification persistante Android,
   `NSLocationAlwaysAndWhenInUseUsageDescription` iOS, arrêt automatique
   quand `isAvailable=false`.
3. **Permissions** : écrans explicatifs avant la demande (caméra, position,
   notifications) et état « refusé définitivement » → ouverture des réglages
   (`Geolocator.openAppSettings`).
4. **Réseau faible** : `SyncQueue` pour signalements et confirmations ;
   indicateur « en attente d'envoi » ; réessais exponentiels ; cache des
   tuiles OSM (`flutter_map_tile_caching` ou cache HTTP) pour la carte.
5. **Compression d'images** : `flutter_image_compress` (qualité 80, max
   1600 px) avant upload.
6. **Deep links** : `eco://report/<id>`, `eco://collect/<id>` (App Links /
   Universal Links) pour les notifications et le partage.
7. **Release Android** : keystore de release (secret CI `ANDROID_KEYSTORE_BASE64`),
   `signingConfigs.release`, versionCode auto depuis le tag, AAB signé dans
   la release GitHub. **iOS** : build non signé conservé en CI ; TestFlight
   hors périmètre sans compte développeur.
8. **Tests** : tests widgets pour `RegisterPhoneScreen` (validation du code),
   `CollectorConfirmScreen`, `MapScreen` (filtres), et un test d'intégration
   (`integration_test/`) du parcours signalement sur émulateur Android en CI
   (job optionnel).
9. **Accessibilité / performance** : tailles de police dynamiques, contraste,
   `cacheWidth` déjà en place, éviter les rebuilds de `FlutterMap` (les
   `MarkerLayer` sont recréées à chaque `setState`).

## Points de coordination

- Attend du backend : contrats `initPayment` / `paymentWebhook`, table
  `collector_positions`, `collection_points`, `payments`, `payouts`,
  `points_ledger`, Function `reverseGeocode`, Messaging FCM/APNs.
- Partage `shared/` avec desktop et web : le mobile est **propriétaire** des
  features `auth`, `home`, `reporting`, `collection_request`, `map`,
  `rewards`, `profile`, `notifications`, `collector`. Toute modification
  d'un modèle (`shared/models/`) doit être annoncée le matin même.
- Fournit au web : les écrans citoyen / collecteur doivent rester
  responsives (`ResponsiveHelper`), pas de dépendance à `dart:io` hors
  `PhotoPicker`.
