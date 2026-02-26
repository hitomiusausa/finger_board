# auth

## この feature の責務
ログイン・サインアップ・セッション管理を担当する。

## 主要ファイル
- services/auth_service.dart — Supabase Auth のラッパー（signUp / signIn / signOut / role 取得）
- providers/auth_provider.dart — Riverpod で auth state を管理（AsyncValue ベース）
- screens/login_screen.dart — ログイン画面
- screens/signup_screen.dart — サインアップ画面（role 選択付き）

## 依存関係
- core/supabase/supabase_client.dart
- core/router/app_router.dart（リダイレクト制御）

## Supabase テーブル
- `profiles` テーブルに `id`, `email`, `role` カラムが必要

## 画面遷移
- 未ログイン → /login
- ログイン済み → / (HomeScreen)
- go_router の redirect で自動遷移

## TODO
- [ ] パスワードリセット画面
- [ ] ソーシャルログイン（Google / Apple）
- [ ] メール確認フロー
- [ ] role に応じた画面分岐（teacher → home, student → viewer）
