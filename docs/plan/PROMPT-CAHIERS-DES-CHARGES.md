# Invite pour Claude — génération des cahiers des charges par pôle (PDF + DOCX)

> Copier tout ce qui suit dans Claude, puis joindre l'archive
> `eco-responsable-docs.zip` (ou les fichiers `.md` et `logo.png` qu'elle contient).

---

Tu es architecte logiciel et chef de projet. Je te fournis la documentation
complète du projet **Éco-Responsable** (plateforme citoyenne de gestion des
déchets au Cameroun, Flutter + Appwrite Cloud) sous forme de fichiers
Markdown, ainsi que le logo du projet (`logo.png`).

Lis d'abord `00-brief-pour-claude.md` (consigne générale), puis `01` à `09`
dans l'ordre. Ces fichiers décrivent le produit, l'état exact du code au
21 septembre 2026, l'architecture, le schéma backend, ce qui reste à faire
par équipe, la spécification de la carte temps réel, l'organisation de
l'équipe et les scénarios de recette. **Appuie-toi exclusivement sur eux** ;
si une information manque, signale-le dans une section « Hypothèses » et
fais une hypothèse raisonnable.

## Équipe

- 2 ingénieurs backend (BE-A : schéma, permissions, Functions métier ;
  BE-B : paiements, positions, rapports, Messaging, exploitation)
- 1 ingénieur frontend mobile (Android / iOS — citoyen et collecteur)
- 1 ingénieur frontend desktop (Linux / Windows / macOS — mairie et entreprise)
- 1 ingénieur frontend web (PWA — tous les espaces)

Durée : 7 jours de travail (J1 = lundi), objectif : **toutes** les
fonctionnalités réelles et branchées sur Appwrite, aucune donnée simulée,
carte réelle partout.

## Ce que tu dois produire

Génère **six documents distincts**, chacun livré **en PDF et en DOCX**
(mêmes contenus, mise en page soignée, logo `logo.png` en page de garde et en
en-tête, palette : vert `#2E7D32`, ocre `#C98A2B`, bleu `#1F4E79`, texte
`#1B1B1B`) :

1. **Cahier des charges général** — vision, périmètre, acteurs, exigences
   fonctionnelles et non fonctionnelles, architecture cible, planning macro
   J1–J7 avec jalons, organisation, gouvernance, risques, critères de
   réception (reprend `01`, `03`, `09`).
2. **Cahier des charges — Pôle Backend (Appwrite)** — pour BE-A et BE-B :
   schéma cible complet (tables, colonnes, index, permissions, Teams),
   spécification détaillée de chaque Function (déclencheur, entrée, sortie,
   règles métier, erreurs, idempotence, tests), paiements Mobile Money
   (MTN MoMo, Orange Money : flux, sandbox, bascule prod), positions et
   itinéraires (OSRM), Messaging push, seeds, environnements staging / prod,
   monitoring, planning J1–J7 par personne, livrables et critères
   d'acceptation (reprend `04`, `08`, `09`).
3. **Cahier des charges — Pôle Frontend Mobile** — écrans citoyen et
   collecteur un par un (état actuel, comportement cible, données consommées,
   canaux Realtime, états vide / erreur), push, localisation en arrière-plan,
   hors ligne, permissions, compression d'images, release Android, tests,
   planning J1–J7, dépendances backend avec dates (reprend `05`, `08`).
4. **Cahier des charges — Pôle Frontend Desktop** — écrans mairie et
   entreprise, tables de données, cartes back-office (collecteurs en direct,
   polygones de zones), rôles via Teams, rapports PDF, campagnes, versements,
   packaging (deb / AppImage, MSIX, DMG), raccourcis, tests, planning J1–J7,
   dépendances (reprend `06`, `08`).
5. **Cahier des charges — Pôle Frontend Web** — plateforme Web Appwrite,
   responsive, PWA, landing page publique, déploiement continu (Appwrite
   Sites), push web, sécurité (CSP, HTTPS), compatibilité navigateurs, tests
   e2e, planning J1–J7, dépendances (reprend `07`, `08`).
6. **Plan de travail sur 7 jours et plan de recette** — tableau jour par
   jour et personne par personne (tâche, fichiers / Functions / écrans
   concernés, dépendance, livrable démontrable, critère de validation),
   points de synchronisation inter-équipes, contrats d'interface figés J1
   (JSON des Functions, canaux Realtime, colonnes), matrice de recette des
   14 scénarios (qui exécute, sur quelle plateforme, résultat attendu),
   hors périmètre et semaine suivante (reprend `09`, `02`).

## Structure imposée de chaque cahier des charges

1. Page de garde (logo, titre, pôle, version 1.0, date, auteurs)
2. Sommaire
3. Contexte et objectifs du pôle
4. Périmètre (inclus / exclu)
5. État actuel (ce qui est réel, partiel, simulé — d'après `02`)
6. Exigences fonctionnelles détaillées (identifiants `BE-01`, `MOB-01`,
   `DSK-01`, `WEB-01`… avec priorité Must / Should / Could)
7. Exigences non fonctionnelles (performance, sécurité, hors ligne,
   accessibilité, i18n fr/en)
8. Spécifications techniques (fichiers Dart, tables, Functions, canaux,
   bibliothèques, versions)
9. Interfaces avec les autres pôles (ce que le pôle attend, ce qu'il fournit,
   dates)
10. Planning J1–J7 du pôle (tableau)
11. Livrables et critères d'acceptation (Definition of Done)
12. Risques et parades
13. Annexes (glossaire, références aux fichiers du dépôt)

## Consignes de rédaction

- Langue : **français**, ton professionnel, phrases courtes ; termes
  techniques en anglais quand c'est l'usage (Function, Realtime, Team).
- Sois concret : nomme les fichiers (`shared/lib/features/...`), les tables,
  les colonnes, les Functions, les routes (`/collect/:id`), les paquets pub.
- Tableaux pour les exigences, les plannings et les matrices ; diagrammes
  (Mermaid ou description textuelle si le format ne le permet pas) pour
  l'architecture et les flux.
- Chaque exigence doit être **vérifiable** (critère d'acceptation
  mesurable) et rattachée à un jour du planning et à une personne.
- Numérote les pages, ajoute en-tête (logo + titre du document) et pied de
  page (« Éco-Responsable — Cahier des charges <pôle> — v1.0 — <date> »).
- Ne réinvente pas de fonctionnalités absentes des fichiers fournis.

## Format de livraison

Pour chaque document : un fichier `.docx` et un fichier `.pdf`, nommés
`Eco-Responsable_CDC_<Pole>_v1.0.docx` / `.pdf` (`General`, `Backend`,
`Mobile`, `Desktop`, `Web`, `Plan-7-jours`). Si tu ne peux produire qu'un
document à la fois, commence par le **cahier des charges général**, puis
**Backend**, puis les trois frontends, puis le plan ; indique à chaque fois
lequel suit.
