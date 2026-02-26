// lib/features/auth/services/auth_service.dart
// ─────────────────────────────────────────────────────────────
// Supabase Auth サービス
// ─────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// メールアドレスでサインアップし、profiles テーブルにも insert する
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'role': role,
      });
    }

    return response;
  }

  /// メールアドレスでログイン
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// ログアウト
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 現在のユーザーを取得
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// profiles テーブルから role を取得
  Future<String?> fetchUserRole(String userId) async {
    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return response['role'] as String?;
  }
}
