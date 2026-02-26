// lib/core/router/app_router.dart
// ─────────────────────────────────────────────────────────────
// go_router によるルーティング
// 認証状態に応じてリダイレクト
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/board/screens/home_screen.dart';
import '../../features/board/screens/board_screen.dart';

// ── Auth 変更を GoRouter に通知する ChangeNotifier ──────────
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _subscription = supabase.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Router Provider ──────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = supabase.auth.currentSession != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/signup';

      // 未ログイン → ログイン画面へ
      if (!isLoggedIn && !isAuthRoute) return '/login';
      // ログイン済み → ホーム画面へ
      if (isLoggedIn && isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/board/:materialId',
        builder: (_, state) => BoardScreen(
          materialId: state.pathParameters['materialId']!,
        ),
      ),
      GoRoute(
        path: '/board',
        builder: (_, __) => const BoardScreen(),
      ),
    ],
  );
});
