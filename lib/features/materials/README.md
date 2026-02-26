# materials

## この feature の責務
教材の作成・保存・読み込み・一覧管理を担当する。

## 主要ファイル
- models/teaching_material.dart — 教材データモデル（materials テーブル対応）
- services/materials_service.dart — Supabase CRUD（createMaterial / getMaterials / savePage / getPages）
- providers/materials_provider.dart — Riverpod 状態管理（AsyncValue ベース）

## Supabase テーブル
- `materials` — id, owner_id, title, description, is_public, forked_from, created_at, updated_at
- `pages` — id, material_id, page_order, title, objects (JSONB), created_at
- 両テーブルとも RLS で owner_id = auth.uid() のみ操作可能

## 依存関係
- core/supabase/supabase_client.dart
- shared/models/page_data.dart
- features/auth（ログイン済みユーザーの owner_id）

## TODO
- [ ] 教材の編集（タイトル・説明文の変更）
- [ ] 教材の削除
- [ ] 教材の複製（fork）
- [ ] 公開/非公開の切り替え
- [ ] ページの並び替え
