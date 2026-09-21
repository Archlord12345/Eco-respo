import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eco_responsable/core/appwrite/appwrite_client.dart';
import 'package:eco_responsable/core/appwrite/appwrite_config.dart';
import 'package:eco_responsable/core/error/app_exceptions.dart';
import 'package:eco_responsable/shared/models/app_user.dart';
import 'package:eco_responsable/shared/models/enums.dart';
import 'package:eco_responsable/features/auth/domain/repositories/auth_repository.dart';

class AppwriteAuthRepository implements AuthRepository {
  AppwriteAuthRepository(this._account, this._tables);

  final Account _account;
  final TablesDB _tables;

  static const _db = AppwriteConfig.databaseId;
  static const _table = AppwriteConfig.usersCollection;

  List<String> _ownerPermissions(String userId) => [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.read(Role.users()),
      ];

  AppUser _defaultProfile(String userId, {String name = '', String? phone}) => AppUser(
        id: userId,
        name: name.isEmpty ? 'Citoyen' : name,
        phone: phone ?? '',
        city: 'Yaoundé',
        role: UserRole.citizen,
        points: 0,
      );

  Future<AppUser> _loadOrCreate(String userId) async {
    try {
      final row = await _tables.getRow(databaseId: _db, tableId: _table, rowId: userId);
      return AppUser.fromMap(row.data, id: row.$id);
    } on AppwriteException {
      final account = await _account.get();
      final user = _defaultProfile(userId, name: account.name, phone: account.phone);
      await _tables.createRow(
        databaseId: _db,
        tableId: _table,
        rowId: userId,
        data: user.toMap(),
        permissions: _ownerPermissions(userId),
      );
      return user;
    }
  }

  @override
  Future<AppUser?> currentUser() async {
    try {
      final account = await _account.get();
      try {
        final row = await _tables.getRow(
          databaseId: _db,
          tableId: _table,
          rowId: account.$id,
        );
        return AppUser.fromMap(row.data, id: row.$id);
      } on AppwriteException {
        return _defaultProfile(account.$id, name: account.name, phone: account.phone);
      }
    } on AppwriteException {
      return null;
    }
  }

  @override
  Future<AppUser> upsertProfile(AppUser user) async {
    await _tables.upsertRow(
      databaseId: _db,
      tableId: _table,
      rowId: user.id,
      data: user.toMap(),
      permissions: _ownerPermissions(user.id),
    );
    if (user.name.isNotEmpty) {
      await _account.updateName(name: user.name);
    }
    return user;
  }

  @override
  Future<void> updateProfile(AppUser user) => upsertProfile(user);

  @override
  Future<void> logout() => _account.deleteSessions();

  @override
  Future<AppUser> loginEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      final account = await _account.get();
      return await _loadOrCreate(account.$id);
    } on AppwriteException catch (e) {
      throw AuthFailure(e.message ?? 'Connexion impossible', code: e.code?.toString());
    }
  }

  @override
  Future<AppUser> registerEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final created = await _account.create(
        userId: ID.unique(),
        email: email.trim(),
        password: password,
        name: name,
      );
      await _account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      return await _loadOrCreate(created.$id);
    } on AppwriteException catch (e) {
      throw AuthFailure(e.message ?? 'Inscription impossible', code: e.code?.toString());
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AppwriteAuthRepository(
    ref.watch(accountProvider),
    ref.watch(tablesProvider),
  );
});
