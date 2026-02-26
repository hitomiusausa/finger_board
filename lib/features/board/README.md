# board

## この feature の責務
ボードの編集・表示・オブジェクト操作を担当する。

## 主要ファイル
- screens/board_screen.dart — ボード編集画面
- screens/home_screen.dart — ホーム画面
- providers/board_provider.dart — ボードの状態管理
- models/board_object.dart — ボードオブジェクトのモデル
- models/undo_command.dart — Undo/Redo の管理
- widgets/board_canvas.dart — ボードのキャンバス描画
- widgets/objects/object_widget.dart — 各オブジェクトの Widget

## 依存関係
- shared/models/page_data.dart
- shared/services/mun_import_service.dart

## 未実装・TODO
- [ ] AssembleBox への SVG 表示（fbi_to_svg.py 完成後）
