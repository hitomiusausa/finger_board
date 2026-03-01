// lib/core/supabase/supabase_client.dart
// ─────────────────────────────────────────────────────────────
// Supabase 初期化設定
// URL と anonKey は --dart-define で上書き可能
//   flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
// ─────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://jtwgjziunzhoswtuknxm.supabase.co',
);

const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_FRvjx_88hJFSwoVir2VmvA_Tux6j694',
);

/// Supabase クライアントへのショートカット
SupabaseClient get supabase => Supabase.instance.client;

/// Supabase を初期化する（main() で1回だけ呼ぶ）
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
}
