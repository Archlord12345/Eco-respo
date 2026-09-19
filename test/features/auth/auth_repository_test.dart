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
  Future<AppUser> upsertProfile(AppUser user) async => stored = user;

  @override
  Future<void> updateProfile(AppUser user) async => stored = user;

}

void main() {
  test('AuthRepository factice : inscription email puis session', () async {
    final repo = _FakeAuthRepository();
    final user = await repo.registerEmail(
      email: 'moussa@example.com',
      password: 'password123',
      name: 'Moussa',
    );
    expect(user.name, 'Moussa');
    expect(await repo.currentUser(), isNotNull);
    await repo.logout();
    expect(await repo.currentUser(), isNull);
  });
}
