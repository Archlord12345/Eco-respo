import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../data/appwrite_auth_repository.dart';

class AuthState {
  const AuthState({this.user, this.loading = false, this.error, this.otpUserId});

  final AppUser? user;
  final bool loading;
  final String? error;
  final String? otpUserId;

  AuthState copyWith({
    AppUser? user,
    bool? loading,
    String? error,
    String? otpUserId,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      otpUserId: otpUserId ?? this.otpUserId,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState(loading: true);
  }

  Future<void> restore() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    state = AuthState(user: user, loading: false);
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final id = await ref.read(authRepositoryProvider).requestOtp(phone);
      state = state.copyWith(loading: false, otpUserId: id);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verify(String code) async {
    final uid = state.otpUserId;
    if (uid == null) {
      state = state.copyWith(error: 'Demandez d’abord un code');
      return false;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).verifyOtp(
            userId: uid,
            secret: code,
          );
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<void> saveProfile(AppUser user) async {
    final saved = await ref.read(authRepositoryProvider).upsertProfile(user);
    state = state.copyWith(user: saved);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
