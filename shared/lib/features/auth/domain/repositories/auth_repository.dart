import 'package:eco_core/shared/models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> currentUser();
  Future<AppUser> upsertProfile(AppUser user);
  Future<void> updateProfile(AppUser user);
  Future<void> logout();
  Future<AppUser> loginEmail({required String email, required String password});
  Future<AppUser> registerEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Inscription par téléphone : l'utilisateur choisit lui-même son code de
  /// connexion à 6 chiffres. Aucun SMS n'est envoyé.
  Future<AppUser> registerPhone({
    required String phone,
    required String pin,
    String name = '',
  });

  /// Connexion par téléphone + code à 6 chiffres choisi à l'inscription.
  Future<AppUser> loginPhone({required String phone, required String pin});

  /// Changement du code à 6 chiffres (compte téléphone).
  Future<void> changePin({required String phone, required String oldPin, required String newPin});
}
