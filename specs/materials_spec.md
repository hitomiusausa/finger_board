# 教材管理機能仕様書

**作成日:** 2026-02-28  
**ステータス:** 確定（随時更新）  
**対象 Phase:** Phase 1  
**関連ファイル:** `features/materials/`

---

## 1. 概要

教材（material）の作成・保存・読み込み・削除・共有を管理する機能。旧アプリの「ファイルライブラリ」に相当する。

---

## 2. データ構造

### 2-1. material（教材）

```dart
class Material {
  final String id;           // UUID
  final String ownerId;      // 作成者の profiles.id
  final String title;        // 教材タイトル
  final String? description; // 説明（任意）
  final bool isPublic;       // マーケットプレイス公開フラグ
  final String? forkedFrom;  // 改変元の material_id（任意）
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 2-2. page（ページ）

```dart
class PageData {
  final String id;           // UUID
  final String materialId;   // 所属する material の id
  final int pageOrder;       // 表示順（0始まり）
  final String? title;       // ページタイトル（任意）
  final List<BoardObject> objects; // ページ上のオブジェクト一覧
  final DateTime createdAt;
}
```

### 2-3. BoardObject（オブジェクト）

```dart
class BoardObject {
  final String id;           // UUID
  final String type;         // 'letter' | 'image' | 'assemble' | 'line' | 'question'
  final double x;            // X座標
  final double y;            // Y座標
  final double width;
  final double height;
  final double rotation;     // 回転角（度）
  final Map<String, dynamic> properties; // 種別ごとの追加プロパティ
}
```

---

## 3. 教材ライブラリ画面

ログイン後のホーム画面。自分の教材一覧を表示する。旧アプリの「ファイルライブラリ」に相当。

### 3-1. 表示内容

- 教材のサムネイル（1ページ目の画像）
- 教材タイトル
- 最終更新日時
- ページ数

### 3-2. 操作

| 操作 | 動作 |
|---|---|
| 教材をタップ | BoardScreen（編集モード）で開く |
| 「＋」ボタン | 新規教材を作成 |
| 教材を長押し | 教材名変更ダイアログを表示 |
| 教材をスワイプ | 削除ボタンを表示 |
| 検索バー | タイトルでフィルタリング |

### 3-3. ソート・フィルタ

- 最終更新日（新しい順 / 古い順）
- タイトル（あいうえお順）

---

## 4. 教材の作成フロー

```
1. 「＋」ボタンタップ
2. タイトル入力ダイアログ（デフォルト：「新しい教材」）
3. Supabase の materials テーブルに INSERT
4. 最初のページを pages テーブルに INSERT（page_order: 0）
5. BoardScreen（編集モード）で開く
```

---

## 5. 教材の保存フロー

```
編集中に「💾」ボタンタップ
  ├─ 現在のページの BoardObject リストを JSON に変換
  ├─ pages テーブルを UPSERT（page_id で一意）
  ├─ materials テーブルの updated_at を更新
  └─ 保存完了トースト表示
```

**自動保存：** Phase 1 では手動保存のみ。Phase 2 以降で検討。

---

## 6. 教材の読み込みフロー

```
教材ライブラリで教材をタップ
  ├─ materials テーブルから教材情報を取得
  ├─ pages テーブルから全ページを page_order 順に取得
  ├─ 各ページの objects（JSONB）を BoardObject リストに変換
  ├─ BoardState に格納
  └─ BoardScreen（編集モード）を表示
```

---

## 7. 教材タイトル編集

```
BoardScreen の AppBar タイトルをタップ
  ├─ インライン編集フィールドに切り替え
  ├─ 確定（Returnキー or フォーカスアウト）
  ├─ materials テーブルの title を UPDATE
  └─ AppBar タイトルを更新
```

---

## 8. 教材の削除フロー

```
教材をスワイプ → 削除ボタン
  ├─ 確認ダイアログ（「削除すると元に戻せません」）
  ├─ 「削除」を選択
  ├─ materials テーブルから DELETE（CASCADE で pages も削除）
  └─ ライブラリから項目を削除
```

---

## 9. .mun ファイルインポート

旧アプリの教材ファイル（.mun）を読み込んで Flutter の教材として取り込む。

### 9-1. インポートフロー

```
ファイルピッカーで .mun ファイルを選択
  ├─ MunImportService.import() でデコード
  │     ├─ AMF3 + zlib のデコード
  │     ├─ JSON 変換
  │     └─ PageData / BoardObject に変換
  ├─ materials テーブルに新規 INSERT（タイトルは .mun のファイル名）
  ├─ 全ページを pages テーブルに INSERT
  └─ BoardScreen（編集モード）で開く
```

### 9-2. エラーハンドリング

| エラー | 表示 |
|---|---|
| 非対応ファイル形式 | 「このファイル形式には対応していません」 |
| デコード失敗 | 「ファイルの読み込みに失敗しました」 |
| Supabase エラー | 「保存に失敗しました。再度お試しください」 |

---

## 10. ゲストモードでの動作（for Students）

ゲストユーザーは Supabase を使用しない。

```
AirDrop / リンクで .mun を受け取る
  ├─ MunImportService.import() でデコード（ローカルのみ）
  ├─ デバイス内のローカルストレージに保存
  └─ BoardScreen（学習モード）で開く
```

**制限：**
- Supabase への保存なし
- 進捗記録なし
- 教材の作成・編集不可

---

## 11. 実装状況

| 機能 | 状態 |
|---|---|
| 教材ライブラリ画面 | ✅ 実装済み |
| 教材の新規作成 | ✅ 実装済み |
| ページの保存（Supabase） | ✅ 実装済み |
| ページの読み込み（DB → ボード表示） | ⬜ 未実装 |
| 教材タイトル編集 | ⬜ 未実装 |
| 複数ページ対応 | ⬜ 未実装 |
| .mun インポート動作確認 | ⬜ 未確認 |
| 教材削除 | ⬜ 未実装 |
| ゲストモード | ⬜ 未実装（Phase 2） |
