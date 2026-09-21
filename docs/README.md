# Documentation Éco-Responsable

Ce dossier est la documentation de référence du projet. Les fichiers
`plan/*.md` sont conçus pour être **envoyés tels quels à un assistant (Claude)**
afin de produire un plan de travail sur 7 jours qui rend toutes les
fonctionnalités réelles, avec une équipe de **2 ingénieurs backend et
3 ingénieurs frontend (mobile, desktop, web)**.

## Comment utiliser ce dossier avec Claude

1. Ouvrir une conversation et coller **d'abord** `plan/00-brief-pour-claude.md`
   (c'est la consigne : objectif, équipe, format attendu).
2. Joindre ensuite les fichiers `01` à `09` dans l'ordre (ou les concaténer :
   `cat docs/plan/*.md > /tmp/contexte-eco.md`).
3. Demander le plan. Les fichiers contiennent tout le contexte nécessaire :
   état exact du code, schéma backend, contrats entre équipes, critères
   d'acceptation.

## Contenu

| Fichier | Rôle |
|---|---|
| [`plan/00-brief-pour-claude.md`](plan/00-brief-pour-claude.md) | Consigne à donner à Claude : objectif du plan, équipe, contraintes, format de sortie |
| [`plan/01-vision-et-perimetre.md`](plan/01-vision-et-perimetre.md) | Produit, personas, périmètre fonctionnel cible par profil |
| [`plan/02-etat-actuel.md`](plan/02-etat-actuel.md) | Audit précis : ce qui est réel, partiel, simulé ou absent — module par module, avec chemins de fichiers |
| [`plan/03-architecture-technique.md`](plan/03-architecture-technique.md) | Monorepo, stack, patterns, flux de données, CI, environnement de dev |
| [`plan/04-backend-appwrite.md`](plan/04-backend-appwrite.md) | Pour les 2 backend : schéma complet, Functions à écrire (specs entrée/sortie), paiements Mobile Money, Messaging, sécurité, seeds |
| [`plan/05-frontend-mobile.md`](plan/05-frontend-mobile.md) | Pour le frontend mobile : écrans, reste à faire, permissions, stores |
| [`plan/06-frontend-desktop.md`](plan/06-frontend-desktop.md) | Pour le frontend desktop : back-office mairie et entreprise, reste à faire, packaging |
| [`plan/07-frontend-web.md`](plan/07-frontend-web.md) | Pour le frontend web : PWA, CORS/plateforme, responsive, déploiement |
| [`plan/08-carte-temps-reel.md`](plan/08-carte-temps-reel.md) | Spécification de la carte réelle (positions, signalements, collecteurs en direct, itinéraires) — transverse |
| [`plan/09-equipe-contrats-recette.md`](plan/09-equipe-contrats-recette.md) | Organisation des 5 ingénieurs, dépendances entre équipes, contrats d'interface, definition of done, scénarios de recette |
| [`design/`](design/) | Les 7 planches de maquettes + sources des visuels |
| [`marketing/`](marketing/) | Affiches, bannière, post réseaux sociaux |

Documentation technique complémentaire :
[`../README.md`](../README.md) (racine), [`../appwrite/README.md`](../appwrite/README.md)
(schéma), [`../mobile/README.md`](../mobile/README.md),
[`../desktop/README.md`](../desktop/README.md), [`../web/README.md`](../web/README.md).
