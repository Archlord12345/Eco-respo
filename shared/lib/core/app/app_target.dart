import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/enums.dart';

/// Cible de build : détermine les espaces (citoyen, collecteur, back-office)
/// exposés par le routeur et la page d'accueil après connexion.
enum AppTarget {
  /// Android / iOS — citoyens et collecteurs sur le terrain.
  mobile,

  /// Linux / Windows / macOS — municipalité et entreprises de collecte.
  desktop,

  /// Navigateur — tous les espaces, mise en page adaptative.
  web,
}

extension AppTargetX on AppTarget {
  bool get hasCitizenSpace => this != AppTarget.desktop;
  bool get hasCollectorSpace => this != AppTarget.desktop;
  bool get hasBackOffice => this != AppTarget.mobile;

  String get label => switch (this) {
        AppTarget.mobile => 'Mobile',
        AppTarget.desktop => 'Desktop',
        AppTarget.web => 'Web',
      };

  /// Route d'entrée d'un profil sur cette cible.
  String homeFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return hasBackOffice ? '/admin' : '/home';
      case UserRole.operator:
        return hasBackOffice ? '/company' : '/home';
      case UserRole.collector:
        return hasCollectorSpace ? '/collector' : '/restricted';
      case UserRole.citizen:
        return hasCitizenSpace ? '/home' : '/restricted';
    }
  }
}

/// Surchargé dans le `main.dart` de chaque application.
final appTargetProvider = Provider<AppTarget>((_) => AppTarget.mobile);
