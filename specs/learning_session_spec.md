# 学習セッション仕様書

**作成日:** 2026-02-28  
**ステータス:** Phase 2 着手前に確定  
**対象 Phase:** Phase 2  
**関連ファイル:** `features/progress/`, `features/board/`

---

## 1. 概要

学習セッションは「生徒が1回の学習で教材に取り組んだ記録」の単位。開始・終了・進捗記録のフローを定義する。

---

## 2. セッションの開始・終了フロー

### 2-1. 開始条件

以下のいずれかのタイミングでセッションを開始する：

- ログイン中の student が BoardScreen を学習モードで開いたとき
- for Students アプリで教材を開いたとき（ログイン時のみ）

**ゲストは記録しない。**

```
学習モードで BoardScreen を開く（ログイン済みの場合）
  ├─ learning_sessions テーブルに INSERT
  │     started_at: now()
  │     student_id: 現在のユーザー
  │     material_id: 開いている教材の id
  └─ session_id を BoardState に格納
```

### 2-2. 終了条件

以下のいずれかのタイミングでセッションを終了する：

- BoardScreen を閉じる（ホームに戻る）
- 編集モードに切り替える（Pro アプリ）
- アプリをバックグラウンドに移す（一定時間後）
- 全ページの学習が完了した場合（将来対応）

```
セッション終了イベント発生
  ├─ learning_sessions テーブルを UPDATE
  │     ended_at: now()
  │     duration_sec: (ended_at - started_at) の秒数
  └─ BoardState から session_id をクリア
```

---

## 3. 進捗記録のフロー

セッション中に QuestionBox へ解答するたびに progress テーブルに記録する。

```
学習者が QuestionBox に解答
  ├─ 正誤判定を実行
  ├─ progress テーブルに INSERT
  │     student_id: 現在のユーザー
  │     material_id: 現在の教材
  │     page_id: 現在のページ
  │     object_id: QuestionBox の id（BoardObject.id）
  │     is_correct: 正誤
  │     score: 1（正解）or 0（不正解）
  │     answer_given: 解答内容（JSON）
  │     answered_at: now()
  │     session_id: 現在のセッション id
  └─ フィードバックを表示
```

---

## 4. 学習完了画面

全ページの QuestionBox に解答し終えたとき（または任意で終了したとき）に表示する画面。

### 4-1. 表示内容

- 「学習完了！」メッセージ
- 正解率（正解数 / 全問題数）
- 所要時間
- 「もう一度」ボタン
- 「ホームに戻る」ボタン

### 4-2. 「もう一度」の動作

```
「もう一度」をタップ
  ├─ 新しい learning_session を開始
  ├─ 全ページを最初の状態にリセット
  └─ 1ページ目から学習を再開
```

---

## 5. ページ保存・復元機能

旧アプリの「ページ保存 / 復元」機能に相当。現在のページの状態を一時的に保存して後で復元できる。

**用途：** 提示モードで先生が動かしたオブジェクトを元の位置に戻す。

```
「ページ保存」ボタンをタップ
  ├─ 現在の BoardObject の配置状態を一時スナップショットとして保存
  └─ 「保存済み」トーストを表示

「ページ復元」ボタンをタップ
  ├─ スナップショットの状態に BoardObject を戻す
  └─ アンドゥ履歴もリセット
```

**注意：** この「保存」は Supabase への保存ではなく、セッション内の一時保存。アプリを閉じると消える。

---

## 6. for Students アプリでのセッション管理

### 6-1. ログイン済み student

- セッション記録あり（learning_sessions + progress）
- 教師が Dashboard でセッション結果を確認できる

### 6-2. ゲスト

- セッション記録なし
- 進捗は記録されない
- 何度でも自由に取り組める

---

## 7. Dashboard 向けの集計（Phase 5 で使用）

`learning_sessions` と `progress` を組み合わせて以下の集計が可能：

| 集計内容 | SQL概要 |
|---|---|
| 教材ごとの達成率 | `progress WHERE material_id=X GROUP BY student_id` |
| 問題ごとの正誤率 | `progress GROUP BY object_id` |
| 平均学習時間 | `learning_sessions AVG(duration_sec)` |
| 最終アクセス日時 | `learning_sessions MAX(started_at)` |
| つまずき問題の特定 | `progress WHERE is_correct=false GROUP BY object_id ORDER BY COUNT DESC` |

---

## 8. 未解決の設計課題（Phase 2 着手前に要決定）

- [ ] セッションの「完了」をどう定義するか（全問解答 or 任意終了）
- [ ] 1教材を複数回取り組んだとき、progress はすべて残す？最新のみ？
- [ ] 部分正解（QuestionBox の一部だけ正解）をどう記録するか
- [ ] オフライン時の進捗をどうキャッシュしてあとで同期するか
