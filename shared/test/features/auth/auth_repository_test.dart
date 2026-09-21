import 'package:eco_core/core/error/app_exceptions.dart';
import 'package:eco_core/features/auth/data/appwrite_auth_repository.dart';
import 'package:eco_core/features/auth/domain/repositories/auth_repository.dart';
import 'package:eco_core/shared/models/app_user.dart';
import 'package:eco_core/shared/models/enums.dart';
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

  final Map<String, String> _pins = {};

  @override
  Future<AppUser> registerPhone({required String phone, required String pin, String name = ''}) async {
    _pins[phone] = pin;
    return stored = AppUser(id: 'phone-user', name: name, phone: phone, city: 'Yaoundé', role: UserRole.citizen, points: 0);
  }

  @override
  Future<AppUser> loginPhone({required String phone, required String pin}) async {
    if (_pins[phone] != pin) throw const AuthFailure('Numéro ou code à 6 chiffres incorrect.');
    return stored = AppUser(id: 'phone-user', name: 'Moussa', phone: phone, city: 'Yaoundé', role: UserRole.citizen, points: 0);
  }

  @override
  Future<void> changePin({required String phone, required String oldPin, required String newPin}) async {
    if (_pins[phone] != oldPin) throw const AuthFailure('Ancien code incorrect.');
    _pins[phone] = newPin;
  }
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

  test('Téléphone : le code à 6 chiffres choisi sert à la connexion, sans SMS', () async {
    final repo = _FakeAuthRepository();
    await repo.registerPhone(phone: '+237690000000', pin: '482913', name: 'Moussa');
    await repo.logout();
    expect(() => repo.loginPhone(phone: '+237690000000', pin: '000000'), throwsA(isA<AuthFailure>()));
    final user = await repo.loginPhone(phone: '+237690000000', pin: '482913');
    expect(user.phone, '+237690000000');
    await repo.changePin(phone: '+237690000000', oldPin: '482913', newPin: '135790');
    expect(await repo.loginPhone(phone: '+237690000000', pin: '135790'), isNotNull);
  });

  test('Dérivation Appwrite : email technique et mot de passe fort déterministes', () {
    expect(AppwriteAuthRepository.phoneToEmail('+237 690 000 000'), '237690000000@phone.eco-responsable.cm');
    final a = AppwriteAuthRepository.pinToPassword('+237690000000', '482913');
    expect(a.length, 64);
    expect(a, AppwriteAuthRepository.pinToPassword('237690000000', '482913'));
    expect(a, isNot(AppwriteAuthRepository.pinToPassword('+237690000000', '482914')));
  });
}
