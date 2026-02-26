// lib/features/board/models/undo_command.dart
// ─────────────────────────────────────────────────────────────
// Undo/Redo コマンドパターン
// AS3 UndoManager / UndoCommand に対応
// ─────────────────────────────────────────────────────────────

import '../../../shared/models/page_data.dart';

/// Undo/Redo 可能な1コマンド
abstract class UndoCommand {
  const UndoCommand();
  PageData apply(PageData page);
  PageData undo(PageData page);
}

/// オブジェクト移動コマンド
class MoveCommand extends UndoCommand {
  final String objectId;
  final double fromX, fromY;
  final double toX, toY;

  const MoveCommand({
    required this.objectId,
    required this.fromX, required this.fromY,
    required this.toX, required this.toY,
  });

  @override
  PageData apply(PageData page) => _updateObj(page, toX, toY);

  @override
  PageData undo(PageData page) => _updateObj(page, fromX, fromY);

  PageData _updateObj(PageData page, double x, double y) => page.copyWith(
    objectsData: page.objectsData.map((o) =>
      o.id == objectId ? o.copyWith(x: x, y: y) : o
    ).toList(),
  );
}

/// オブジェクト追加コマンド
class AddObjectCommand extends UndoCommand {
  final int insertIndex;
  final dynamic object; // BoardObject

  const AddObjectCommand({required this.insertIndex, required this.object});

  @override
  PageData apply(PageData page) {
    final newList = List.from(page.objectsData);
    newList.insert(insertIndex, object);
    return page.copyWith(objectsData: List.from(newList));
  }

  @override
  PageData undo(PageData page) => page.copyWith(
    objectsData: page.objectsData.where((o) => o != object).toList(),
  );
}

/// オブジェクト削除コマンド
class DeleteObjectCommand extends UndoCommand {
  final dynamic object; // BoardObject が削除前に保持
  final int originalIndex;

  const DeleteObjectCommand({required this.object, required this.originalIndex});

  @override
  PageData apply(PageData page) => page.copyWith(
    objectsData: page.objectsData.where((o) => o != object).toList(),
  );

  @override
  PageData undo(PageData page) {
    final newList = List.from(page.objectsData);
    newList.insert(originalIndex.clamp(0, newList.length), object);
    return page.copyWith(objectsData: List.from(newList));
  }
}

/// Undo/Redo マネージャー
/// AS3 UndoManager を Dart に移植
class UndoManager {
  static const int _maxHistory = 20;

  final List<UndoCommand> _history = [];
  int _cursor = -1; // 現在位置（-1 = 空）

  bool get canUndo => _cursor >= 0;
  bool get canRedo => _cursor < _history.length - 1;

  /// コマンドを実行してヒストリに追加
  PageData execute(UndoCommand command, PageData current) {
    // カーソル以降のヒストリを破棄（redo 不可にする）
    if (_cursor < _history.length - 1) {
      _history.removeRange(_cursor + 1, _history.length);
    }
    _history.add(command);
    _cursor++;

    // 上限超過時は古いものから削除
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
      _cursor = _history.length - 1;
    }

    return command.apply(current);
  }

  /// Undo
  PageData? undo(PageData current) {
    if (!canUndo) return null;
    final cmd = _history[_cursor];
    _cursor--;
    return cmd.undo(current);
  }

  /// Redo
  PageData? redo(PageData current) {
    if (!canRedo) return null;
    _cursor++;
    final cmd = _history[_cursor];
    return cmd.apply(current);
  }

  void reset() {
    _history.clear();
    _cursor = -1;
  }
}
