# 08 — Spécification de la carte réelle et du temps réel

Exigence : **la carte est une vraie carte interactive partout, jamais une
image.** Aujourd'hui `flutter_map` + tuiles OpenStreetMap est déjà utilisé
dans tous les écrans (`MapScreen`, `MiniMap`, tableaux de bord). Ce document
fixe ce que « réel » signifie pour chaque usage et comment le construire.

## 1. Composants existants

- `shared/lib/core/widgets/mini_map.dart` — `MiniMap(pins, polyline, center,
  zoom, height, interactive, overlay)` : carte compacte réutilisable
  (détail signalement, suivi de demande, tournée, arrêt).
- `shared/lib/features/map/presentation/map_screen.dart` — carte citoyen
  plein écran : position utilisateur (`userPositionProvider`), cercle de
  rayon, marqueurs `zones` (points de collecte de substitution), signalements
  ouverts filtrés par type / distance, liste horizontale des points proches,
  bouton « ma position », itinéraire externe.
- Tableaux de bord mairie / entreprise : `FlutterMap` avec pins colorés par
  urgence / statut.
- `AppConstants.centerFor(city)` : centres Yaoundé (3.848, 11.502), Douala…
- `AppConstants.osmUserAgent` : User-Agent requis par la politique OSM.

## 2. Couches de données à rendre réelles

| Couche | Source | Écrans | Mise à jour |
|---|---|---|---|
| Position de l'utilisateur | `geolocator` (précision medium, timeout 8 s) | Carte, signalement, demande | À la demande + stream quand l'écran est visible |
| Points de collecte | **table `collection_points`** (nouvelle) — aujourd'hui centres de `zones` | Carte citoyen, zones mairie | Chargement par ville, cache local 24 h |
| Signalements ouverts | `waste_reports` (`status != resolved`) | Carte citoyen (rayon), dashboards | Realtime `rowsChannel('waste_reports')` |
| Demandes en attente | `collection_requests` (`status = pending`) | Collecteur home, dispatch | Realtime |
| **Collecteurs en direct** | **table `collector_positions`** (nouvelle) | Suivi citoyen (le sien), dispatch, dashboard mairie | Realtime `rowsChannel('collector_positions')` ; publication toutes les 10–15 s ou 50 m par le collecteur en tournée |
| Zones | `zones` (centre + couleur ; **polygone** à ajouter) | Mairie, carte citoyen (contour) | Rare |
| Itinéraire | **OSRM** `GET https://router.project-osrm.org/route/v1/driving/{lng,lat;lng,lat}?overview=full&geometries=geojson` | Tournée collecteur, suivi citoyen (collecteur → moi), itinéraire vers un point | À chaque changement d'arrêts / toutes les 60 s pendant la tournée |
| Adresse (reverse geocoding) | Nominatim via Function `reverseGeocode` (cache) | Signalement, demande, détail | À la création |

## 3. Comportements attendus par écran

### Carte citoyen (`/map`)
- Centrée sur la position réelle (repli : centre de la ville du profil).
- Marqueurs : points de collecte (icône verte, fiche au tap : nom, type,
  types acceptés, horaires, distance, bouton itinéraire), signalements
  ouverts (icône par urgence, tap → `/report/:id`), ma position.
- Filtres : type de déchet, rayon 1–15 km, afficher / masquer les
  signalements. Liste horizontale synchronisée avec le filtre ; tap → centre.
- Itinéraire **dans l'app** : polyline OSRM depuis ma position jusqu'au point
  choisi, distance / durée affichées ; bouton « Ouvrir dans Maps » conservé.
- Au-delà de 200 marqueurs : clustering (`flutter_map_marker_cluster`).
- Attribution OSM visible (`RichAttributionWidget`).

### Signalement (`/report`) et demande (`/collect`)
- Après acquisition GPS : `MiniMap` interactive avec marqueur déplaçable pour
  corriger la position ; adresse remplie par reverse geocoding, éditable.
- Si GPS refusé : la carte reste utilisable, l'utilisateur pose le marqueur.

### Suivi de demande (`/collect/:id`)
- Carte : ma position (adresse de la demande), position **en direct** du
  collecteur affecté (`collector_positions` Realtime, `rowChannel`), polyline
  OSRM collecteur → moi, ETA = `etaMinutes` de la demande (recalculé côté
  Function) ou calcul client depuis la durée OSRM.
- Statuts : `matched` → « en route dans X min » ; `enRoute` → suivi live ;
  `collected` → carte figée + preuve.

### Collecteur (`/collector`, `/collector/tour`)
- Home : carte des demandes `pending` dans le rayon choisi + ma position.
- Tournée : arrêts ordonnés (plus proche voisin depuis ma position),
  polyline OSRM complète, distance / durée totales, bouton « Démarrer » qui
  active la publication de position (foreground service Android), navigation
  externe par arrêt.
- Publication de position : `Geolocator.getPositionStream(distanceFilter: 25)`
  → `collector_positions.upsertRow(rowId = collectorId)` ; arrêt à la fin de
  la tournée ou quand `isAvailable=false`.

### Dispatch entreprise et dashboard mairie
- Couches : demandes en attente, collecteurs en direct (couleur = statut
  disponible / en tournée, tooltip nom + dernière mise à jour), zones
  (polygones semi-transparents), signalements (mairie).
- Clic sur une demande → panneau d'affectation avec collecteurs triés par
  distance réelle. Clic sur un collecteur → sa tournée.
- Carte de chaleur des signalements (`flutter_map_heatmap` ou cercles
  pondérés) avec sélecteur de période.

### Zones mairie
- Dessin de polygone (clics successifs, fermeture, édition des sommets),
  enregistrement `zones.polygon` (GeoJSON), import GeoJSON, couleur, opérateurs
  affectés ; test d'appartenance point-dans-polygone pour rattacher
  automatiquement signalements et demandes à une zone (`zoneId`).

## 4. Détails techniques

- **Tuiles** : `https://tile.openstreetmap.org/{z}/{x}/{y}.png` avec
  `userAgentPackageName: AppConstants.osmUserAgent` ; respecter la politique
  d'usage (pas de préchargement massif). Alternative sans clé si limité :
  `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png`.
  Cache : `flutter_map_tile_caching` (mobile / desktop), pas sur le web.
- **OSRM** : instance publique `router.project-osrm.org` (démo, sans SLA) —
  prévoir une variable d'env `ROUTING_BASE_URL` et, si besoin, une clé
  OpenRouteService (2 000 req/j gratuites). Service Dart commun
  `core/services/routing_service.dart` : `route(List<LatLng>) → RouteResult(points, distanceKm, durationMin)` avec cache mémoire.
- **Distance** : `latlong2` `Distance()` pour les tris et filtres (déjà
  utilisé dans `MapScreen`).
- **Performance** : ne pas reconstruire `FlutterMap` à chaque `setState` ;
  isoler les `MarkerLayer` dans des widgets consommant des providers ;
  limiter la fréquence Realtime (debounce 500 ms).
- **Web** : géolocalisation uniquement en HTTPS ; CORS OSM et OSRM OK.
- **Modèles Dart** à ajouter : `CollectorPosition`, `CollectionPoint`,
  `RouteResult` ; `Zone.polygon` (`List<LatLng>?`).

## 5. Critères d'acceptation « carte réelle »

1. Aucun asset `map_preview.png` référencé dans le code (à supprimer de
   `AppAssets` une fois la dernière utilisation retirée).
2. Sur un appareil réel à Yaoundé, la carte citoyen s'ouvre centrée sur
   l'utilisateur en < 3 s et affiche au moins les points de collecte
   seedés à moins de 3 km.
3. Un signalement créé sur le mobile apparaît sur la carte mairie (desktop)
   en < 2 s sans rafraîchissement.
4. Pendant une tournée, la position du collecteur se met à jour sur l'écran
   de suivi du citoyen au moins toutes les 15 s et la polyline suit la route.
5. L'itinéraire affiché suit les rues (OSRM), pas une ligne droite.
6. La carte reste utilisable (tuiles en cache, marqueurs) en réseau dégradé.
