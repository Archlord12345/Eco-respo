import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../data/appwrite_auth_repository.dart';

class AuthState {
  const AuthState({this.user, this.loading = false, this.error});
  final AppUser? user;
  final bool loading;
  final String? error;
  AuthState copyWith({
    AppUser? user,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
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

  Future<bool> loginEmail(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).loginEmail(
            email: email,
            password: password,
          );
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> registerEmail(String email, String password, String name) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).registerEmail(
            email: email,
            password: password,
            name: name,
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
