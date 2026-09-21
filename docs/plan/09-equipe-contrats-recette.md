# 09 — Équipe, contrats d'interface, definition of done, recette

## 1. Équipe (5 personnes)

| Code | Rôle | Périmètre | Propriétaire de |
|---|---|---|---|
| **BE-A** | Backend | Schéma, Teams / permissions, Functions métier (`matchCollector`, `computeRewardPoints`, `manageRole`, `onUserCreate`, `sendCampaign`, `reverseGeocode`), seeds | `appwrite.config.json`, `tool/`, `appwrite/functions/` |
| **BE-B** | Backend | Paiements (`initPayment`, `paymentWebhook`, sandbox MTN / Orange), positions (`updateCollectorPosition`, OSRM), `generateAdminReport`, Messaging FCM / APNs, staging / prod, monitoring | idem + intégrations externes |
| **FE-M** | Frontend mobile | Espaces citoyen et collecteur, push, localisation en arrière-plan, release Android | `mobile/`, `shared/lib/features/{auth,home,reporting,collection_request,map,rewards,profile,notifications,collector}` |
| **FE-D** | Frontend desktop | Back-office mairie et entreprise, tables, cartes back-office, packaging | `desktop/`, `shared/lib/features/{dashboard_admin,company,settings}`, `BackOfficeShell` |
| **FE-W** | Frontend web | Responsive, PWA, landing, déploiement, push web, e2e | `web/`, `ResponsiveHelper`, `_AdaptiveShell`, `core/services/routing_service.dart` (transverse, à la demande des autres) |

Modèles (`shared/lib/shared/models/`) et `core/appwrite/` : **copropriété
BE-A + FE-M** ; toute modification passe par une PR revue par un frontend
d'une autre app le jour même.

## 2. Dépendances critiques (chemin critique)

```
J1  BE-A : schéma étendu + Teams + plateforme Web  ──► FE-* branchent les nouveaux modèles J2
J1  BE-A/BE-B : contrats JSON des Functions figés  ──► FE-* codent contre des fakes J1–J2
J2  BE-A : matchCollector + computeRewardPoints (staging) ──► FE-M suivi/points réels J3
J2  BE-B : collector_positions + updateCollectorPosition ──► FE-M publication J3, FE-D dispatch live J3
J3  BE-B : initPayment + paymentWebhook (sandbox)  ──► FE-M paiement réel J4
J3  BE-A : manageRole + sendCampaign               ──► FE-D rôles / campagnes J4
J4  BE-B : Messaging FCM/APNs                      ──► FE-M push J5, FE-W push J5
J4  BE-B : generateAdminReport (PDF)               ──► FE-D rapports J5
J5  BE-A : seeds complets Yaoundé + Douala         ──► recette J6–J7
J6  tous : gel des features, corrections, CI verte, packaging
J7  recette croisée, démo, release v1.0.0
```

Règle : un frontend **ne bloque jamais** sur le backend — il code contre
l'interface Dart (`*Repository`, `PaymentService`) avec une implémentation
fake ou le repli existant, puis bascule quand la Function est en staging.

## 3. Contrats d'interface à figer J1

### Functions (entrée / sortie JSON, `responseBody`)
Voir `04-backend-appwrite.md` §4. Format commun :
`{ "ok": true, "data": {…} }` ou `{ "ok": false, "error": "<code>", "message": "<fr>" }`.
Codes d'erreur : `no_collector`, `insufficient_points`, `already_credited`,
`payment_failed`, `forbidden`, `not_found`, `provider_unavailable`.

### Canaux Realtime écoutés par les clients
| Canal | Consommateur |
|---|---|
| `tablesdb.eco_responsable_db.tables.waste_reports.rows` | Dashboards mairie, carte citoyen |
| `…waste_reports.rows.<id>` | Détail signalement |
| `…collection_requests.rows` | Collecteur home, dispatch, dashboards |
| `…collection_requests.rows.<id>` | Suivi de demande |
| `…collector_positions.rows` | Dispatch, dashboard mairie |
| `…collector_positions.rows.<collectorId>` | Suivi de demande (citoyen) |
| `…payments.rows.<id>` | Écran d'attente de paiement |
| `…notifications.rows` (filtré `userId`) | Fil de notifications, badge |

### Colonnes / tables ajoutées (résumé, détail dans `04` §2)
`collector_positions`, `collection_points`, `payments`, `payouts`,
`points_ledger`, `zones.polygon`, `collection_requests.{paymentStatus,
paymentId, etaMinutes, distanceKm, zoneId}`, `users.pushTargetId`,
`collectors.{operatorId, rating}`.

### Conventions
- Ids : `ID.unique()` sauf `users` (= id Account), `collector_positions`
  (= collectorId).
- Dates : ISO 8601 UTC ; le client affiche en `Africa/Douala`.
- Montants : entiers XAF. Poids : double kg. Coordonnées : WGS84.
- Enums : valeurs `wire` sans accents (voir `enums.dart`).

## 4. Definition of done (par tâche)

1. Fonctionne sur le **backend réel** (staging) — pas de fake restant, repli
   client supprimé ou explicitement documenté.
2. `flutter analyze --fatal-infos` : 0 problème ; tests existants verts ;
   au moins un test ajouté si logique métier.
3. Démontrable sur la plateforme cible (APK / desktop / web déployé).
4. États vide / chargement / erreur gérés ; textes en français relus.
5. Documentation touchée mise à jour (`README` de l'app, `appwrite/README.md`,
   README de la Function).
6. PR revue par un pair d'une autre équipe ; CI verte ; merge sur `master`.

## 5. Rituels

- **Daily 9h00** (15 min) : bloqueurs, changements de modèles annoncés.
- **Sync contrats J1 14h** : BE + FE valident les JSON et les canaux.
- **Démo fin de journée 17h30** (20 min) : chaque personne montre son
  livrable du jour sur l'app, pas dans l'IDE.
- **Gel J6 12h** : plus de nouvelle feature ; corrections uniquement.
- Canal unique (Slack / WhatsApp) + tableau Kanban (GitHub Projects) avec
  colonnes par jour.

## 6. Scénarios de recette (J7)

| # | Scénario | Plateformes | Résultat attendu |
|---|---|---|---|
| R1 | Inscription téléphone `+237 6XX…` + code 6 chiffres, choix ville, déconnexion, reconnexion avec le code | Mobile, Web | Compte créé (`users`), mauvais code refusé, session persistante |
| R2 | Signalement avec photo et GPS, réseau coupé pendant l'envoi | Mobile | Mis en file, envoyé à la reconnexion, visible mairie < 2 s après |
| R3 | Mairie affecte un opérateur puis résout | Desktop → Mobile | Citoyen notifié (in-app + push), chronologie mise à jour en direct, points crédités par la Function (`points_ledger`) |
| R4 | Demande de collecte payée en MTN MoMo sandbox | Mobile | `payments.success`, `paymentStatus=paid`, reçu affiché ; échec simulé → `failed` + relance possible |
| R5 | `matchCollector` affecte automatiquement un collecteur disponible ; sinon dispatch manuel par l'entreprise | Backend, Desktop | Demande `matched`, collecteur notifié, ETA affiché |
| R6 | Collecteur démarre la tournée ; le citoyen voit sa position bouger et l'itinéraire routier | Mobile × 2 | Mise à jour ≤ 15 s, polyline OSRM, ETA cohérent |
| R7 | Confirmation avec photo + poids | Mobile | `collected`, preuve visible côté citoyen, points crédités **une seule fois**, revenus collecteur mis à jour |
| R8 | Échange d'une récompense | Mobile, Web | Débit autoritaire, refus si solde insuffisant, ligne `points_ledger` |
| R9 | Carte citoyen : filtres, rayon, points de collecte, fiche, itinéraire | Mobile, Web | Données réelles `collection_points`, aucune image statique |
| R10 | Mairie : zones polygones, rapport PDF, campagne quartier | Desktop | PDF téléchargé, campagne reçue par les citoyens du quartier uniquement (in-app + push) |
| R11 | Entreprise : création d'un collecteur avec compte, dispatch, validation d'un versement | Desktop | Le collecteur se connecte avec téléphone + code initial ; `payouts.paid` |
| R12 | Sécurité : un citoyen tente de modifier `users.role` ou `points` via l'API | Backend | Refusé (401 / 403) |
| R13 | Web : PWA installable, parcours R1 + R9 sur Chrome Android et Safari iOS | Web | OK, HTTPS, géolocalisation fonctionnelle |
| R14 | CI : tag `v1.0.0` → release avec APK/AAB signés, bundles desktop, web déployé | CI | Tous les jobs verts, artefacts téléchargeables |

## 7. Risques et parades

| Risque | Impact | Parade |
|---|---|---|
| Contrats marchands MTN / Orange non signés | Paiement prod impossible | Sandbox fonctionnel + bascule par variables d'env ; mode « paiement à la collecte » (cash) comme option |
| OSRM public indisponible / limité | Pas d'itinéraire | `ROUTING_BASE_URL` configurable, repli OpenRouteService, repli ligne droite avec mention |
| Conflits dans `shared/` | Perte de temps | Propriété par feature, PR petites, rebase quotidien, annonce des changements de modèles |
| Permissions trop strictes cassant l'app | Régressions | Staging séparé, matrice de permissions testée par R12 avant prod |
| Localisation en arrière-plan Android | Refus / batterie | Foreground service avec notification, intervalle 15 s / 25 m, arrêt automatique |
| Compte Apple absent | Pas de TestFlight | Hors périmètre déclaré ; build CI non signé conservé |
| Quotas Appwrite Cloud (Functions, Realtime) | Coupures | Surveiller la console J5–J7 ; debounce Realtime ; agrégats via Function |
