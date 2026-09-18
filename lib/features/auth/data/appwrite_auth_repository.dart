import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eco_responsable/core/appwrite/appwrite_client.dart';
import 'package:eco_responsable/core/appwrite/appwrite_config.dart';
import 'package:eco_responsable/core/error/app_exceptions.dart';
import 'package:eco_responsable/shared/models/app_user.dart';
import 'package:eco_responsable/shared/models/enums.dart';
import 'package:eco_responsable/features/auth/domain/repositories/auth_repository.dart';

class AppwriteAuthRepository implements AuthRepository {
  AppwriteAuthRepository(this._account, this._db);

  final Account _account;
  final Databases _db;

  @override
  Future<String> requestOtp(String phoneE164) async {
    try {
      final token = await _account.createPhoneToken(
        userId: ID.unique(),
        phone: phoneE164,
      );
      return token.userId;
    } on AppwriteException catch (e) {
      throw AuthFailure(e.message ?? 'OTP impossible', code: e.code?.toString());
    }
  }

  @override
  Future<AppUser> verifyOtp({
    required String userId,
    required String secret,
  }) async {
    try {
      await _account.createSession(userId: userId, secret: secret);
      return await _loadOrCreate(userId);
    } on AppwriteException catch (e) {
      throw AuthFailure(e.message ?? 'Code invalide', code: e.code?.toString());
    }
  }

  Future<AppUser> _loadOrCreate(String userId) async {
    try {
      final doc = await _db.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: userId,
      );
      return AppUser.fromMap(doc.data, id: doc.$id);
    } on AppwriteException {
      final account = await _account.get();
      final user = AppUser(
        id: userId,
        name: account.name.isEmpty ? 'Citoyen' : account.name,
        phone: account.phone,
        city: 'Yaoundé',
        role: UserRole.citizen,
        points: 0,
      );
      await _db.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: userId,
        data: user.toMap(),
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.read(Role.users()),
        ],
      );
      return user;
    }
  }

  @override
  Future<AppUser?> currentUser() async {
    try {
      final account = await _account.get();
      try {
        final doc = await _db.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollection,
          documentId: account.$id,
        );
        return AppUser.fromMap(doc.data, id: doc.$id);
      } on AppwriteException {
        return AppUser(
          id: account.$id,
          name: account.name,
          phone: account.phone,
          city: 'Yaoundé',
          role: UserRole.citizen,
          points: 0,
        );
      }
    } on AppwriteException {
      return null;
    }
  }

  @override
  Future<AppUser> upsertProfile(AppUser user) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: user.id,
        data: user.toMap(),
      );
    } on AppwriteException {
      await _db.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: user.id,
        data: user.toMap(),
      );
    }
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
      return _loadOrCreate(account.$id);
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
      return _loadOrCreate(created.$id);
    } on AppwriteException catch (e) {
      throw AuthFailure(e.message ?? 'Inscription impossible', code: e.code?.toString());
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AppwriteAuthRepository(
    ref.watch(accountProvider),
    ref.watch(databasesProvider),
  );
});
