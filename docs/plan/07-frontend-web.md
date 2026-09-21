# 07 — Frontend web (ingénieur web)

App `web/` (`runEcoApp(AppTarget.web)`) : **tous les espaces** (citoyen,
collecteur, mairie, entreprise) dans le navigateur, avec `NavigationRail`
au-delà de 900 px et barre basse en dessous. Build `flutter build web
--release --pwa-strategy offline-first`. Splash HTML et `manifest.json`
personnalisés (`web/web/`).

## État

| Élément | État | Reste à faire |
|---|---|---|
| Build et rendu | RÉEL (testé localement, écran d'inscription OK) | — |
| Accès Appwrite depuis le navigateur | **BLOQUÉ** | Déclarer une plateforme **Web** dans Appwrite avec le nom d'hôte (`localhost` pour le dev, domaine de prod) — tâche backend, à faire J1 |
| Authentification | RÉEL (sessions cookie Appwrite ; le domaine doit être en HTTPS en prod) | Tester `flutter_web_auth_2` pour l'OAuth si activé ; mode navigation privée |
| Géolocalisation | PARTIEL | Fonctionne uniquement en HTTPS / `localhost` ; message explicite sinon ; saisie manuelle de position sur la carte en repli |
| Caméra / photos | RÉEL via `image_picker` web (input file) | Aperçu et compression côté navigateur (`image` package ou canvas) |
| Carte | RÉEL (tuiles OSM, CORS OK) | Cache tuiles hors ligne impossible sans service worker dédié ; limiter le zoom max ; attribution OSM visible |
| Realtime | RÉEL (WebSocket) | Reconnexion à la reprise d'onglet |
| Hors ligne | PARTIEL | `SyncQueue` Hive fonctionne (IndexedDB) ; service worker par défaut Flutter ; à valider sur Chrome Android |
| Push | ABSENT | FCM web (`firebase_messaging` web + `firebase-messaging-sw.js`), permission notifications, push target Appwrite |
| Déploiement | ABSENT | Cible recommandée : **Appwrite Sites** (même compte, `appwrite push site`) ou Netlify / Cloudflare Pages ; job CI `web` étendu au déploiement sur `master` ; en-têtes (`Cache-Control`, `Content-Security-Policy`), routage SPA (`/*` → `index.html`) |
| SEO / partage | PARTIEL | `og:` tags présents ; page d'accueil publique (landing) avant `/welcome` avec les affiches `docs/marketing/` |
| Responsive | PARTIEL | Écrans citoyen conçus mobile-first : ajouter des largeurs max (`ResponsiveHelper`), colonnes sur desktop pour `home`, `rewards`, `history` ; back-office ≥ 1024 px |
| Accessibilité | PARTIEL | `Semantics`, navigation clavier, focus visible, `lang="fr"` déjà présent |
| Téléchargements | PARTIEL | Export CSV : `file_picker` ne sauvegarde pas en web → utiliser `download` via `AnchorElement` / `package:web` |

## Chantiers spécifiques web

1. **Landing page** publique (`/`) : présentation, boutons « Je suis
   citoyen / collecteur / mairie / entreprise », liens vers les stores
   (APK dans la release GitHub en attendant), affiches marketing.
2. **Déploiement continu** : `flutter build web --base-href /`, publication
   sur Appwrite Sites (ou Netlify) depuis le job `web` quand `master` est
   vert ; URL de prévisualisation par pull request.
3. **PWA** : icônes 192/512 maskable (déjà générées), `display: standalone`,
   `start_url: /home`, écran « Installer l'application », gestion de la mise
   à jour du service worker (bandeau « nouvelle version »).
4. **Push web** : FCM + service worker `firebase-messaging-sw.js`, push target
   Appwrite, tap → route.
5. **Performance** : `--wasm` à tester (flutter_map compatible ?), lazy
   loading des images via `Image.network` + `fileViewUrl` avec `width`/`height`
   côté Appwrite (`/preview?width=`), `deferred imports` pour le back-office
   quand l'utilisateur est citoyen.
6. **Sécurité** : CSP stricte (autoriser `fra.cloud.appwrite.io`,
   `tile.openstreetmap.org`, `router.project-osrm.org`, `fonts.gstatic.com`),
   HTTPS obligatoire, aucune clé serveur.
7. **Compatibilité** : Chrome / Firefox / Safari récents, Chrome Android,
   Safari iOS (tester `geolocator`, `image_picker`, WebSocket Realtime).
8. **Tests** : `flutter test --platform chrome` sur les tests widgets
   existants ; test e2e Playwright (ou `integration_test` web) du parcours
   inscription → signalement.

## Points de coordination

- Attend du backend : plateforme Web déclarée (J1), Messaging FCM web,
  domaine de production, CORS pour le webhook de paiement (redirection retour
  Orange Money vers le web).
- Partage `shared/` : le web est **propriétaire** de `core/utils/responsive_helper.dart`,
  des adaptations responsive et de `core/widgets/app_scaffold.dart`
  (`_AdaptiveShell`). Il relit les écrans mobile / desktop pour la largeur.
- Fournit aux autres : le déploiement web sert de **démo commune** pour la
  recette J7 (aucune installation nécessaire).
