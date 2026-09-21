# Éco-Responsable — back-office desktop

Cible **Linux / Windows / macOS** pour la **mairie** (`/admin`) et les
**entreprises de collecte** (`/company`) — `AppTarget.desktop`. Tout le code
vient du package partagé [`../shared`](../shared) (`eco_core`).

```bash
flutter pub get
flutter run -d linux \
  --dart-define=APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=eco-responsable-cm

flutter build linux --release      # build/linux/x64/release/bundle/
flutter build windows --release    # build/windows/x64/runner/Release/
flutter build macos --release      # build/macos/Build/Products/Release/Eco-Responsable.app
```

Dépendances Linux : `clang cmake ninja-build pkg-config libgtk-3-dev
libsecret-1-dev libwebkit2gtk-4.1-dev`.

## Espaces

| Rôle | Écrans |
|---|---|
| `admin` (mairie) | Tableau de bord, gestion des signalements (affectation, résolution, export CSV), zones et opérateurs, rapports et campagnes, paramètres |
| `operator` (entreprise) | Tableau de bord, dispatch des demandes, flotte de collecteurs, revenus, paramètres |

Un compte citoyen ou collecteur qui se connecte ici est redirigé vers
l'écran « accès réservé ». Le rôle se change dans *Paramètres → Organisation*.

- Identifiant : `com.eco.kf` (plateformes Appwrite `eco-linux`, `eco-windows`, `eco-apple`).
- Icônes : `dart run flutter_launcher_icons` (Windows, macOS) ; Linux installe
  `runner/resources/app_icon.png` dans `data/` via CMake.
- Fenêtre par défaut 1360 × 820, titre « Éco-Responsable — Back-office ».
