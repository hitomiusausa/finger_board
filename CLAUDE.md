# Finger Board — Claude Code ルールブック

## プロジェクト概要

Adobe AIR 製の教育アプリ「Finger Board」を Flutter + Supabase に移行するプロジェクト。
教師が教材を作成し、生徒が学習する AAC（拡大代替コミュニケーション）支援ツール。

**リポジトリ:** https://github.com/hitomiusausa/finger_board
**Flutter:** 3.41.2 / Dart 3.11.0
**Supabase URL:** https://jtwgjziunzhoswtuknxm.supabase.co

---

## 技術スタック

- フレームワーク: Flutter 3.41.2
- 状態管理: Riverpod（StateNotifierProvider.family）
- バックエンド: Supabase（Auth + PostgreSQL + RLS）
- ルーティング: go_router（routerProvider）
- パッケージ: supabase_flutter, flutter_riverpod, go_router, uuid

---

## フォルダ構造（Feature-first）

lib/
├─ core/
│   ├─ router/app_router.dart
│   └─ supabase/supabase_client.dart
├─ features/
│   ├─ auth/                    ← 認証（実装済み）
│   ├─ board/                   ← ボード編集（実装済み・拡張中）
│   │   ├─ models/board_object.dart
│   │   ├─ models/undo_command.dart
│   │   ├─ providers/board_provider.dart   ← AppMode, BoardState, BoardNotifier
│   │   ├─ screens/board_screen.dart       ← メイン画面
│   │   ├─ screens/home_screen.dart        ← 教材一覧
│   │   └─ widgets/board_canvas.dart
│   └─ materials/               ← 教材 CRUD（実装済み）
│       ├─ models/teaching_material.dart
│       ├─ providers/materials_provider.dart
│       └─ services/materials_service.dart ← getPages(), savePage() 実装済み
├─ shared/
│   ├─ models/page_data.dart
│   └─ services/mun_import_service.dart
└─ main.dart

---

## 重要な設計ルール

### AppMode（モード管理）

board_provider.dart に定義済み。名称を変えないこと。

enum AppMode {
  teacherEdit,   // 編集モード（教師用）
  studentPlay,   // 学習モード（生徒用）
  presentation,  // 提示モード
}

### boardProvider は family

// materialId ごとに独立した状態
final boardProvider = StateNotifierProvider.family<BoardNotifier, BoardState, String>(
  (ref, materialId) => BoardNotifier(),
);

### エラーハンドリング（必須）

// 禁止：エラーを握りつぶす
try { ... } catch (e) { return null; }

// 必須：AsyncValue で管理するか、例外をそのまま throw して上位で処理
final result = await AsyncValue.guard(() => someAsyncCall());

### features/ にアプリ固有知識を持たせない

Pro / Students の判断は app_pro/ と app_students/ だけが持つ。

---

## 現在の実装状況

### 実装済み
- Supabase Auth（ログイン・サインアップ）
- go_router（auth state 連動）
- 教材一覧画面（home_screen.dart）
- 教材作成・DB 保存（materials テーブル）
- ページ保存（pages テーブル、savePage()）
- ページ取得（getPages() — BoardScreen からは未呼び出し）
- ボード編集（オブジェクト追加・移動・Undo/Redo）
- AppMode 切り替え UI（PopupMenu）

### 未実装（Phase 1 残タスク）
- ページ読み込み（DB → ボード表示）← 最優先
- 複数ページ対応
- タイトルインライン編集
- .mun インポート動作確認
- AssembleBox SVG 表示（fbi_to_svg.py 完成待ち）
- app_pro / app_students エントリポイント分離

---

## Supabase テーブル

### 実装済み
- profiles — ユーザープロフィール（role, plan）
- materials — 教材（owner_id, title, is_public）
- pages — ページ（material_id, page_order, objects JSONB）

### Phase 2 で追加予定
- teacher_students / assignments / learning_sessions / progress
- ※ progress.object_id は BoardObject.id と一致させること（Dashboard 集計に使用）

---

## ブランチ・コミットルール

- main に直接コミットしない
- ブランチ名: feature/xxx, fix/xxx, refactor/xxx
- コミットメッセージは日本語 OK、1行で何をしたか書く
- 未完成コードには // TODO: を残す
- 必ず PR を出してからマージ

---

## 仕様書の場所

specs/ フォルダに仕様書がある。実装前に必ず参照すること。
- specs/board_screen_spec.md — BoardScreen・AppMode 詳細
- specs/materials_spec.md — 教材管理
- specs/question_box_spec.md — QuestionBox（Phase 2）
- specs/learning_session_spec.md — 学習セッション（Phase 2）

---

## よく使うコマンド

flutter run -d chrome
flutter run -d ios
flutter build ios --no-codesign
flutter pub get
