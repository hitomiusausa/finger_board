// lib/features/auth/providers/auth_provider.dart
// ─────────────────────────────────────────────────────────────
// 認証状態の Riverpod 管理
// エラーは AsyncValue で管理
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../services/auth_service.dart';

// ── AuthService Provider ──────────────────────────────────────
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(supabase),
);

// ── Auth State Stream（ログイン/ログアウトを監視）──────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// ── 現在のユーザー ───────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return supabase.auth.currentUser;
});

// ── ユーザー role（profiles テーブルから取得）────────────────
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(authServiceProvider).fetchUserRole(user.id);
});

// ── サインイン ────────────────────────────────────────────────
class SignInNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signInWithEmail(
            email: email,
            password: password,
          ),
    );
  }
}

final signInProvider =
    AutoDisposeAsyncNotifierProvider<SignInNotifier, void>(
  SignInNotifier.new,
);

// ── サインアップ ──────────────────────────────────────────────
class SignUpNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signUp(String email, String password, String role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signUpWithEmail(
            email: email,
            password: password,
            role: role,
          ),
    );
  }
}

final signUpProvider =
    AutoDisposeAsyncNotifierProvider<SignUpNotifier, void>(
  SignUpNotifier.new,
);
