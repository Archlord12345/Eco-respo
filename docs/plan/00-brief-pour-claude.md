# Brief — plan de travail sur 7 jours pour finaliser Éco-Responsable

## Ce que je te demande

Produis un **plan de travail détaillé sur 7 jours** (J1 à J7) pour terminer
le projet Éco-Responsable et rendre **toutes** ses fonctionnalités réelles et
branchées sur le backend Appwrite Cloud : plus aucune donnée simulée, aucun
écran « vitrine », aucune image à la place d'un composant fonctionnel
(la carte doit être une vraie carte interactive avec de vraies données).

Les documents joints (`01` à `09`) décrivent le produit, l'état exact du code
au 21 septembre 2026, l'architecture, le schéma backend, et ce qui reste à
faire par équipe. **Appuie-toi dessus, ne suppose pas de fonctionnalités qui
n'y figurent pas** ; si une information manque, dis-le explicitement et fais
une hypothèse raisonnable.

## L'équipe

| Rôle | Effectif | Périmètre |
|---|---|---|
| Ingénieur backend | **2** | Appwrite Cloud : schéma, permissions, Functions (Node.js ou Dart), paiements Mobile Money, Messaging (push), seeds, monitoring |
| Ingénieur frontend mobile | **1** | `mobile/` + parties de `shared/` utilisées par le mobile (citoyen, collecteur) — Android / iOS |
| Ingénieur frontend desktop | **1** | `desktop/` + parties de `shared/` utilisées par le back-office (mairie, entreprise de collecte) — Linux / Windows / macOS |
| Ingénieur frontend web | **1** | `web/` + adaptations responsive de `shared/`, PWA, déploiement |

Le code Flutter est **partagé** dans `shared/` (package `eco_core`) : les
trois frontends doivent se coordonner sur ce package (répartition par
feature, revues croisées) pour éviter les conflits. Le plan doit dire
**qui touche quoi, quel jour**.

## Contraintes

- Durée : 7 jours calendaires de travail, J1 = lundi. Journées de 8 h.
- Stack imposée : Flutter 3.47 / Dart 3.13, Riverpod 3, go_router, flutter_map
  (OpenStreetMap), Appwrite Cloud (région `fra`, projet `eco-responsable-cm`,
  API TablesDB), Appwrite Functions, GitHub Actions (workflow unique existant).
- Le backend est la dépendance critique : les Functions et permissions
  doivent être livrées **tôt** (J1–J3) pour que les frontends branchent le
  réel dès J2–J4. Prévois des **contrats d'interface** (entrée/sortie des
  Functions, événements Realtime) figés dès J1 pour découpler les équipes.
- Pas de nouveau service externe payant sans alternative gratuite : cartes via
  OSM ; itinéraires via OSRM public ou OpenRouteService (clé gratuite) ;
  paiements via les API sandbox MTN MoMo et Orange Money (mode test si les
  contrats marchands ne sont pas signés à J7, avec bascule prod documentée).
- Qualité : `flutter analyze --fatal-infos` à zéro, tests existants au vert,
  CI verte à chaque fin de journée. Chaque livrable doit être **démontrable**
  sur l'app (pas seulement « le code est écrit »).

## Format de sortie attendu

1. **Vue d'ensemble** : objectif de la semaine, jalons J1/J3/J5/J7, risques
   majeurs et parades.
2. **Plan jour par jour (J1 → J7)** : pour chaque jour, un tableau par
   personne (Backend A, Backend B, Mobile, Desktop, Web) avec : tâches
   concrètes (fichiers / Functions / écrans nommés), dépendances, livrable
   démontrable en fin de journée, critère de validation.
3. **Contrats d'interface** à figer J1 : signature JSON de chaque Function,
   canaux Realtime écoutés, colonnes ajoutées au schéma, permissions.
4. **Matrice de recette J7** : reprise des scénarios de `09` avec qui les
   exécute et sur quelle plateforme.
5. **Ce qui ne rentre pas** en 7 jours (hors périmètre explicite) et
   recommandation pour la semaine suivante.

Sois concret : nomme les fichiers Dart, les Functions, les tables, les
colonnes. Préfère des tâches d'une demi-journée maximum. Indique les
points de synchronisation inter-équipes (ex. « J2 14h : Backend livre
`matchCollector` en staging → Mobile branche le suivi de demande »).
