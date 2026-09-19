# Instructions Gemini AI Studio - Eco-Responsable

## Mission

Finaliser l'application Eco-Responsable a partir du depot Flutter existant. Le projet comprend deux experiences partageant le meme backend Appwrite :

- `mobile/` : application citoyenne Android/iOS, responsive et conforme aux planches mobiles.
- `desktop/` : application municipale Linux/Windows/macOS, orientee back-office et conforme a la planche desktop.

Le code partage reste dans `lib/` pour eviter de dupliquer les models, repositories, widgets, theme et navigation. Ne pas transformer les deux profils en deux projets Flutter independants qui casseraient les plugins et le lancement existant. Utiliser des profils d'execution, des layouts responsives et des entrypoints si une separation de code devient necessaire.

## Reference visuelle obligatoire

Les planches presentes a la racine du depot sont la source de verite visuelle :

- planches citoyennes onboarding, accueil, signalement, collecte, carte, recompenses, profil et historique ;
- planches collecteur accueil, tournee, detail d'arret, confirmation, historique et revenus ;
- planches suivi de signalement, demande de collecte et notifications ;
- planche back-office municipal ;
- affiche de marque Eco-Responsable.

Avant de modifier un ecran, lire les planches correspondantes et conserver :

- palette verte, vert clair, ocre, blanc chaud et texte anthracite ;
- typographies Poppins pour les titres et Inter pour le corps ;
- cartes compactes, coins doux, espaces aeres et hierarchie visuelle nette ;
- navigation basse sur mobile ;
- sidebar et espace horizontal exploite sur desktop ;
- etats de chargement, succes, erreur, vide et confirmation ;
- transitions douces et animations utiles, jamais decoratives ou excessives.

L'interface doit etre epuree, accessible, coherente et proche des planches sans recopier aveuglement un composant qui ne serait pas fonctionnel.

## Authentification

Ne pas utiliser OTP, SMS ou verification par telephone pour le parcours principal.

Le parcours doit etre :

1. onboarding ;
2. inscription avec nom, email et mot de passe ;
3. connexion avec email et mot de passe ;
4. selection de ville/quartier ;
5. ouverture de l'espace selon le role.

Utiliser Appwrite Account :

- `Account.create` pour l'inscription ;
- `Account.createEmailPasswordSession` pour la connexion ;
- `Account.get` pour restaurer la session ;
- `Account.deleteSessions` pour la deconnexion ;
- `Account.updateName` lors de la mise a jour du profil.

Ne pas remettre de formulaire OTP dans l'interface. Les champs telephone peuvent rester dans les donnees collecteur/profil si necessaire au metier, mais ils ne controlent pas l'authentification.

## Appwrite

Configuration publique Flutter :

- Endpoint : `https://appwrite.kernelforge.codes/v1`
- Project ID : `6aad2f1a000a6a6de281`
- Database ID : `eco_responsable_db`
- Package mobile : `com.eco.kf`
- SDK Dart : `appwrite: ^13.0.0`

Le client Flutter ne doit jamais contenir de cle API serveur.

Toutes les requetes d'administration et de provisioning passent par :

```bash
tool/appwrite.sh databases
tool/appwrite.sh collections
tool/appwrite.sh buckets
tool/appwrite.sh functions
tool/appwrite.sh documents reward_items
tool/appwrite.sh documents zones
```

La cle est fournie uniquement dans un environnement local :

```bash
APPWRITE_API_KEY='cle-locale' tool/appwrite.sh databases
APPWRITE_API_KEY='cle-locale' python3 tool/setup_appwrite.py
```

Ne jamais mettre la cle dans Flutter, Git, un README ou un fichier partage.

Ressources attendues :

- collections `users`, `waste_reports`, `collection_requests`, `collectors`, `reward_items`, `zones`, `notifications` ;
- buckets `report_photos` et `collection_proofs` ;
- donnees initiales des recompenses et zones ;
- Functions `matchCollector`, `computeRewardPoints`, `paymentWebhook`, `generateAdminReport` ;
- provider Messaging FCM/APNs si les notifications push sont activees.

Ne pas simuler une Function absente : afficher un etat indisponible clair et documenter le deploiement necessaire.

## Fonctionnalites mobiles

Implementer et connecter aux repositories Appwrite :

- onboarding et authentification ;
- accueil avec points, impact, actions rapides et notifications reelles ;
- signalement avec photo, geolocalisation, categorie, urgence, upload Storage et suivi Realtime ;
- demande de collecte avec type, volume, date, horaire, paiement et statut ;
- vraie carte interactive `flutter_map` avec tuiles OpenStreetMap et marqueurs Appwrite ;
- recompenses et catalogue Appwrite ;
- profil, historique, parametres et deconnexion ;
- espace collecteur conforme aux planches : disponibilite, demandes proches, tournee, detail d'arret, confirmation photo/poids, historique et revenus.

Les cartes ne doivent pas etre remplacees par des images statiques. Les images de carte peuvent servir de reference visuelle uniquement.

## Fonctionnalites desktop

Construire le back-office municipal avec :

- sidebar persistante ;
- dashboard avec KPIs calcules depuis Appwrite ;
- vraie carte des signalements et marqueurs ;
- liste filtrable et detail des signalements ;
- gestion zones/operators ;
- rapports et communication ;
- etats d'erreur visibles lorsque les Functions ou providers ne sont pas deployes.

Ne jamais afficher des KPIs inventes comme des donnees reelles. Utiliser une valeur vide, zero ou indisponible avec un libelle explicite quand Appwrite ne fournit pas la donnee.

## Assets et images

Arborescence obligatoire :

- `assets/images/logos/` : logos clair et blanc ;
- `assets/images/auth/` : onboarding et visuels d'inscription ;
- `assets/images/reporting/` : signalements, preuves, camion et dechets ;
- `assets/images/map/` : icones et references cartographiques ;
- `assets/images/rewards/` : badges et recompenses ;
- `assets/images/profile/` : avatars, notifications et decorations ;
- `assets/images/payments/` : Mobile Money et tri ;
- `assets/images/shared/` : drapeau et assets transverses.

Chaque asset doit :

- avoir un nom `snake_case` explicite ;
- etre declare dans `pubspec.yaml` ;
- etre reference via `lib/core/constants/app_assets.dart` ;
- etre utilise par un ecran identifie ;
- etre verifie apres modification avec `flutter clean` puis `flutter pub get`.

Si une image existante est fausse, vide, floue, incoherente avec la planche ou visuellement faible, Gemini AI Studio est autorise a :

1. l'analyser ;
2. la regenerer ou la remplacer par une image adequate ;
3. conserver le meme role et le meme nom de reference lorsque possible ;
4. mettre a jour `AppAssets` si le chemin change ;
5. verifier son rendu sur mobile et desktop.

Si une image manque, creer ou selectionner un asset coherent avec la marque, sans utiliser une image generique sans rapport. Les cartes reelles restent des widgets cartographiques, pas des PNG.

## Animations et etats

Utiliser les bibliotheques deja presentes : `animations` et `flutter_animate`.

Prevoir :

- transitions de pages `FadeThroughTransition` ou equivalente ;
- apparitions progressives legeres ;
- boutons avec etat loading bloque ;
- skeleton ou indicateur pendant les requetes ;
- messages de succes apres creation/upload ;
- messages d'erreur lisibles et recuperables ;
- etats vides utiles ;
- confirmation avant actions sensibles.

Ne pas cacher les erreurs Appwrite dans des `catch (_) {}` silencieux.

## Organisation du code

Conserver l'architecture feature-first :

- `lib/core/` : Appwrite, theme, router, widgets et utilitaires ;
- `lib/features/auth/` ;
- `lib/features/reporting/` ;
- `lib/features/collection_request/` ;
- `lib/features/collector/` ;
- `lib/features/map/` ;
- `lib/features/rewards/` ;
- `lib/features/profile/` ;
- `lib/features/dashboard_admin/` ;
- `lib/shared/models/`.

Les dossiers `mobile/` et `desktop/` documentent les profils et peuvent accueillir des entrypoints ou configurations specifiques, mais ne doivent pas casser l'entrypoint racine `lib/main.dart`.

## Validation obligatoire

Avant toute livraison :

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
flutter build linux --debug
flutter build apk --debug
```

Si Android ou un device mobile n'est pas disponible, ne pas pretendre avoir teste `flutter run -d android`. Signaler le blocage et fournir la commande exacte.

Verifier egalement :

- aucun chemin d'asset ne renvoie vers un fichier absent ;
- les ecrans ne debordent pas sur petit mobile ;
- les cartes sont interactives ;
- les appels Appwrite utilisent les vrais repositories ;
- les Functions absentes sont signalees clairement ;
- aucune cle serveur n'est versionnee ;
- le diff Git est propre avant commit et push.
