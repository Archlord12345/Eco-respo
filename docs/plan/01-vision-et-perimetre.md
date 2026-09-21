# 01 — Vision produit et périmètre fonctionnel

## Le produit

**Éco-Responsable** est une plateforme citoyenne de gestion des déchets pour
les villes camerounaises (Yaoundé et Douala en priorité). Elle relie quatre
acteurs autour d'un même backend Appwrite Cloud :

| Acteur | Rôle applicatif (`users.role`) | Frontend principal |
|---|---|---|
| Citoyen | `citizen` | Mobile (Android / iOS), Web |
| Collecteur (terrain, indépendant ou salarié d'une entreprise) | `collector` | Mobile, Web |
| Entreprise de collecte (opérateur) | `operator` | Desktop, Web |
| Mairie / communauté urbaine | `admin` | Desktop, Web |

Promesse : *« Signalez. Collectez. Gagnez. »* — le citoyen signale un dépôt
sauvage ou demande une collecte à domicile payée en Mobile Money ; les
collecteurs interviennent ; la mairie pilote ; le citoyen gagne des points
convertibles en récompenses.

## Personas

- **Sandrine, 28 ans, Yaoundé (Bastos)** — citoyenne, smartphone Android
  d'entrée de gamme, connexion 3G/4G irrégulière, paie en MTN MoMo. Veut
  signaler un tas d'ordures en 30 secondes et suivre ce qu'il devient.
- **Moussa, 34 ans, collecteur** — tricycle, travaille pour « Propre Cité
  SARL ». A besoin d'une liste de demandes proches, d'un itinéraire, d'une
  preuve de collecte simple et de voir ses revenus.
- **Mme Ngo, responsable dispatch chez Propre Cité SARL** — PC Windows.
  Veut affecter les demandes à sa flotte, suivre les tournées et les revenus.
- **M. Essomba, service hygiène de la Mairie de Yaoundé** — PC Windows /
  Linux. Veut une vue d'ensemble (carte, KPI), affecter des opérateurs par
  zone, produire des rapports et envoyer des campagnes.

## Périmètre fonctionnel cible (état « réel » attendu à J7)

### Citoyen
1. Onboarding (3 slides) puis **inscription par téléphone + code à 6 chiffres
   choisi par l'utilisateur** (aucun SMS) ou email + mot de passe ; choix de
   la ville / du quartier.
2. Accueil : impact réel (points, kg valorisés, CO₂ évité), objectif mensuel,
   raccourcis, dernières notifications, badges Bronze / Argent / Or.
3. Signaler un dépôt : photo (caméra / galerie), géolocalisation automatique,
   adresse inverse (reverse geocoding), catégorie, urgence ; envoi hors ligne
   différé.
4. Détail d'un signalement : photo, carte, chronologie, opérateur affecté,
   mise à jour temps réel.
5. Demander une collecte : type, volume, date/créneau, récurrence, position,
   prix calculé, **paiement Mobile Money réel** (MTN MoMo / Orange Money)
   avec confirmation asynchrone.
6. Suivi d'une demande : collecteur assigné (nom, téléphone, appel), **position
   du collecteur en direct** et ETA, stepper de statut, reçu de paiement.
7. **Carte réelle** : ma position, points de collecte, signalements ouverts,
   filtres type / distance, itinéraire vers un point.
8. Récompenses : solde, catalogue, échange (Function autoritaire), historique
   des échanges, classement.
9. Notifications in-app **et push** (FCM / APNs) ; profil, historique,
   paramètres (langue fr/en, notifications, changement du code à 6 chiffres).

### Collecteur
1. Disponibilité en ligne / hors ligne ; **publication de sa position** en
   direct quand il est en tournée.
2. Demandes en attente à proximité (rayon paramétrable), acceptation.
3. Tournée du jour : carte avec itinéraire réel (OSRM), arrêts ordonnés,
   navigation externe.
4. Détail d'un arrêt, appel du citoyen, démarrage (`enRoute`).
5. Confirmation : photo de preuve, poids réel, → points crédités au citoyen,
   notification, revenus mis à jour.
6. Historique, revenus (jour / semaine / mois), demandes de versement.

### Entreprise de collecte (back-office)
1. Tableau de bord : demandes en attente, collectes en cours, volume,
   revenus, graphiques.
2. **Dispatch** : affecter une demande à un collecteur de la flotte, carte des
   collecteurs en direct.
3. Flotte : créer / modifier un collecteur (compte + fiche), disponibilité,
   zones couvertes.
4. Revenus et versements (par collecteur, par période, export CSV).

### Mairie (back-office)
1. Tableau de bord : taux de résolution, délai moyen, volume, signalements
   ouverts ; carte de chaleur ; séries 30 jours ; répartition par type.
2. Signalements : liste filtrable, détail, **affectation d'un opérateur**,
   prise en charge, résolution, réouverture, export CSV.
3. Zones et opérateurs : zones éditables (polygone ou centre + rayon),
   affectation d'opérateurs, liste des opérateurs.
4. Rapports (PDF via Function `generateAdminReport`) et campagnes
   (notification in-app + push ciblée par quartier).
5. Paramètres, gestion des rôles (promotion `operator` / `admin` via Teams).

### Transverse
- Realtime Appwrite sur toutes les tables métier.
- Sécurité : permissions par ligne + Teams (`admins`, `operators`,
  `collectors`), aucune clé serveur côté client.
- Hors ligne (file Hive) pour les signalements et confirmations de collecte.
- Localisation fr / en (ARB existants).
- CI unique : analyse, tests, builds Android / iOS / Linux / Windows / macOS /
  web, release sur tag.

## Hors périmètre à J7 (à mentionner si utile)

Application native iOS signée / TestFlight (nécessite compte développeur),
publication Play Store, facturation entreprise, multi-tenant multi-villes
avancé, tableau de bord national.
