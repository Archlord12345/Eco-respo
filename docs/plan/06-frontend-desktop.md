# 06 — Frontend desktop (ingénieur desktop)

App `desktop/` (`runEcoApp(AppTarget.desktop)`) : back-office **mairie**
(`admin`) et **entreprise de collecte** (`operator`). Linux, Windows, macOS.
Fenêtre 1360×820 par défaut, titre « Éco-Responsable — Back-office », icône
depuis `shared/assets/branding/`.

Sur desktop, les rôles `citizen` / `collector` sont redirigés vers
`/restricted`. Un `admin` peut voir l'espace entreprise et inversement via
`BackOfficeHeader` (menu « Changer d'espace »).

## Écrans et état

### Mairie (`shared/lib/features/dashboard_admin/presentation/admin_screens.dart`, shell `AdminShell`)

| Route | Écran | État | Reste à faire |
|---|---|---|---|
| `/admin` | `AdminDashboardScreen` | RÉEL (calculs client) | Carte de chaleur réelle (`flutter_map_heatmap` ou cercles pondérés), **collecteurs en direct** (`collector_positions`), sélecteur de période, filtre ville, agrégats fournis par `generateAdminReport(kind=general)` pour éviter de charger toutes les lignes |
| `/admin/reports` | `AdminReportsScreen` + `_ReportDetail` | RÉEL | Pagination serveur (`Query.cursorAfter`), tri, recherche plein texte (index fulltext sur `address`/`description`), affectation par **zone** (opérateurs de la zone en premier), historique des changements, pièce jointe résolue (photo « après ») |
| `/admin/zones` | `AdminZonesScreen` | PARTIEL | **Édition de polygones** sur la carte (dessin, `zones.polygon` GeoJSON), import GeoJSON, liste des opérateurs avec statut en direct, création d'un opérateur (`manageRole`) |
| `/admin/reports-comms` | `AdminReportsCommsScreen` | PARTIEL | Rapports PDF via Function `generateAdminReport` (téléchargement + aperçu), campagnes via `sendCampaign` (ciblage quartier, planification), historique des campagnes |
| `/admin/settings` | `SettingsScreen(embedded: true)` | PARTIEL | Supprimer l'auto-attribution de rôle ; gestion des rôles réservée aux admins via `manageRole` ; profil mairie (logo, nom de la commune) |

### Entreprise (`shared/lib/features/company/presentation/company_screens.dart`, shell `CompanyShell`)

| Route | Écran | État | Reste à faire |
|---|---|---|---|
| `/company` | `CompanyDashboardScreen` | RÉEL (calculs client) | Filtrer sur **sa** flotte (`collectors.operatorId`), revenus depuis `payments` |
| `/company/dispatch` | `CompanyDispatchScreen` | RÉEL | Carte des demandes `pending` + collecteurs en direct ; suggestion automatique (distance) ; glisser-déposer ; réaffectation ; vue tournées par collecteur |
| `/company/fleet` | `CompanyFleetScreen` | PARTIEL | Création d'un collecteur **avec compte** (téléphone + code initial via `manageRole`), désactivation, zones couvertes depuis la liste `zones`, statistiques par collecteur, note (`rating`) |
| `/company/revenue` | `CompanyRevenueScreen` | PARTIEL | Revenus réels (`payments.success`), commissions, **versements** (`payouts` : valider / rejeter / marquer payé), export CSV / PDF |
| `/company/settings` | `SettingsScreen(embedded: true)` | PARTIEL | Fiche entreprise (nom, contact, zones), utilisateurs de l'entreprise |

## Chantiers spécifiques desktop

1. **Rôles réels** : lire les Teams Appwrite au démarrage
   (`Teams.list()`), n'afficher les espaces qu'aux membres ; écran de
   « demande d'accès » sinon.
2. **Tables de données** : composant commun `DataTableX` (tri, pagination
   serveur, sélection multiple, actions groupées, colonnes redimensionnables)
   utilisé par signalements, demandes, flotte, versements.
3. **Cartes back-office** : couche collecteurs en direct (Realtime
   `collector_positions`), couche zones (polygones), couche demandes en
   attente ; clic → panneau latéral. Voir `08`.
4. **Exports** : CSV existant ; PDF via Function ; sauvegarde par
   `file_picker` (déjà utilisé) ; impression (`printing` package) des
   rapports.
5. **Raccourcis clavier** (Ctrl+F recherche, Ctrl+N nouveau, Échap fermer
   le panneau), menu fenêtre, taille / position mémorisées
   (`window_manager`), multi-écrans.
6. **Packaging** : `.deb` / AppImage (Linux, `flutter_distributor`), MSIX
   (Windows, `msix` package, certificat auto-signé documenté), DMG (macOS,
   `create-dmg`) — publiés par le job `publication`. Vérifier
   `libwebkit2gtk-4.1` embarqué ou documenté pour Linux.
7. **Sessions longues** : rafraîchissement de session Appwrite, reconnexion
   Realtime après veille, indicateur de connexion.
8. **Tests** : tests widgets sur les filtres de `AdminReportsScreen`, sur
   l'affectation, sur le tri de `CompanyFleetScreen` ; test golden du
   `BackOfficeHeader`.

## Points de coordination

- Attend du backend : Teams + permissions, `manageRole`, `sendCampaign`,
  `generateAdminReport`, `collector_positions`, `payments`, `payouts`,
  `zones.polygon`, `collectors.operatorId`.
- Propriétaire dans `shared/` des features `dashboard_admin`, `company`,
  `settings` (partie back-office) et du widget `BackOfficeShell`.
- Fournit au web : les écrans back-office doivent rester utilisables en
  navigateur ≥ 1024 px (le web réutilise `AdminShell` / `CompanyShell`).
