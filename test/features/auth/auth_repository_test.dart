import 'package:eco_responsable/features/auth/domain/repositories/auth_repository.dart';
import 'package:eco_responsable/shared/models/app_user.dart';
import 'package:eco_responsable/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  AppUser? stored;

  @override
  Future<AppUser?> currentUser() async => stored;

  @override
  Future<void> logout() async => stored = null;

  @override
  Future<AppUser> loginEmail({
    required String email,
    required String password,
  }) async => stored = AppUser(
    id: 'email-user',
    name: 'Moussa',
    phone: '+237690000000',
    city: 'Yaoundé',
    role: UserRole.citizen,
    points: 0,
  );

  @override
  Future<AppUser> registerEmail({
    required String email,
    required String password,
    required String name,
  }) async => stored = AppUser(
    id: 'email-user',
    name: name,
    phone: '+237690000000',
    city: 'Yaoundé',
    role: UserRole.citizen,
    points: 0,
  );

  @override
  Future<String> requestOtp(String phoneE164) async => 'user-otp';

  @override
  Future<AppUser> upsertProfile(AppUser user) async => stored = user;

  @override
  Future<void> updateProfile(AppUser user) async => stored = user;

  @override
  Future<AppUser> verifyOtp({
    required String userId,
    required String secret,
  }) async {
    stored = AppUser(
      id: userId,
      name: 'Moussa',
      phone: '+237690000000',
      city: 'Yaoundé',
      role: UserRole.citizen,
      points: 0,
    );
    return stored!;
  }
}

void main() {
  test('AuthRepository factice : OTP puis session', () async {
    final repo = _FakeAuthRepository();
    final id = await repo.requestOtp('+237693456789');
    expect(id, 'user-otp');
    final user = await repo.verifyOtp(userId: id, secret: '123456');
    expect(user.name, 'Moussa');
    expect(await repo.currentUser(), isNotNull);
    await repo.logout();
    expect(await repo.currentUser(), isNull);
  });
}
