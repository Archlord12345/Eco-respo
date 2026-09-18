import 'package:eco_responsable/shared/models/app_user.dart';

abstract class AuthRepository {
  Future<String> requestOtp(String phoneE164);
  Future<AppUser> verifyOtp({required String userId, required String secret});
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
}
