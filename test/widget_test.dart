import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finger_board/main.dart';
import 'package:finger_board/core/router/app_router.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Supabase 未初期化でも動くよう routerProvider をオーバーライド
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Finger Board')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(testRouter),
        ],
        child: const FingerBoardApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Finger Board'), findsOneWidget);
  });
}
