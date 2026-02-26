// lib/features/board/providers/board_provider.dart
// ─────────────────────────────────────────────────────────────
// ボードの状態管理（Riverpod）
// AS3 の FB.as グローバルシングルトンと FreeBoardIndex の役割を分散管理に置き換え
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_object.dart';
import '../../../shared/models/page_data.dart';
import '../models/undo_command.dart';

// ── アプリモード ────────────────────────────────────────────
enum AppMode {
  teacherEdit,   // 教師編集モード（旧 editorsMode）
  studentPlay,   // 生徒学習モード（旧 studentsVersion）
  presentation,  // 発表モード
}

// ── ボードの状態 ────────────────────────────────────────────
@immutable
class BoardState {
  final PageData? currentPage;
  final List<String> selectedObjectIds;  // 選択中オブジェクトID
  final AppMode mode;
  final bool canUndo;
  final bool canRedo;

  const BoardState({
    this.currentPage,
    this.selectedObjectIds = const [],
    this.mode = AppMode.teacherEdit,
    this.canUndo = false,
    this.canRedo = false,
  });

  BoardState copyWith({
    PageData? currentPage,
    List<String>? selectedObjectIds,
    AppMode? mode,
    bool? canUndo,
    bool? canRedo,
  }) =>
      BoardState(
        currentPage: currentPage ?? this.currentPage,
        selectedObjectIds: selectedObjectIds ?? this.selectedObjectIds,
        mode: mode ?? this.mode,
        canUndo: canUndo ?? this.canUndo,
        canRedo: canRedo ?? this.canRedo,
      );
}

// ── Board Provider（状態ノーティファイア）──────────────────
class BoardNotifier extends StateNotifier<BoardState> {
  final UndoManager _undoManager = UndoManager();

  BoardNotifier() : super(const BoardState());

  /// ページを読み込む（.mun JSON から）
  void loadPage(Map<String, dynamic> munJson) {
    final page = PageData.fromMunJson(munJson);
    _undoManager.reset();
    state = state.copyWith(
      currentPage: page,
      selectedObjectIds: [],
      canUndo: false,
      canRedo: false,
    );
  }

  /// オブジェクトを移動する
  void moveObject(String objectId, double newX, double newY) {
    final page = state.currentPage;
    if (page == null) return;

    final obj = page.objectsData.firstWhere(
      (o) => o.id == objectId,
      orElse: () => throw Exception('Object not found: $objectId'),
    );

    final cmd = MoveCommand(
      objectId: objectId,
      fromX: obj.x, fromY: obj.y,
      toX: newX, toY: newY,
    );
    final newPage = _undoManager.execute(cmd, page);
    state = state.copyWith(
      currentPage: newPage,
      canUndo: _undoManager.canUndo,
      canRedo: _undoManager.canRedo,
    );
  }

  /// Undo
  void undo() {
    final page = state.currentPage;
    if (page == null || !_undoManager.canUndo) return;
    final newPage = _undoManager.undo(page);
    if (newPage != null) {
      state = state.copyWith(
        currentPage: newPage,
        canUndo: _undoManager.canUndo,
        canRedo: _undoManager.canRedo,
      );
    }
  }

  /// Redo
  void redo() {
    final page = state.currentPage;
    if (page == null || !_undoManager.canRedo) return;
    final newPage = _undoManager.redo(page);
    if (newPage != null) {
      state = state.copyWith(
        currentPage: newPage,
        canUndo: _undoManager.canUndo,
        canRedo: _undoManager.canRedo,
      );
    }
  }

  /// オブジェクト選択
  void selectObject(String? objectId) {
    if (objectId == null) {
      state = state.copyWith(selectedObjectIds: []);
    } else {
      state = state.copyWith(selectedObjectIds: [objectId]);
    }
  }

  /// アプリモード切り替え（旧 FB.editorsMode / studentsVersion）
  void setMode(AppMode mode) {
    state = state.copyWith(mode: mode, selectedObjectIds: []);
  }

  /// オブジェクトを追加する
  void addObject(BoardObject obj) {
    final page = state.currentPage;
    if (page == null) return;
    final cmd = AddObjectCommand(
      insertIndex: page.objectsData.length,
      object: obj,
    );
    final newPage = _undoManager.execute(cmd, page);
    state = state.copyWith(
      currentPage: newPage,
      canUndo: _undoManager.canUndo,
      canRedo: _undoManager.canRedo,
    );
  }
}

// ── Provider 定義 ───────────────────────────────────────────
final boardProvider = StateNotifierProvider<BoardNotifier, BoardState>(
  (ref) => BoardNotifier(),
);

// ── セレクター（パフォーマンス最適化） ──────────────────────
final currentPageProvider = Provider<PageData?>(
  (ref) => ref.watch(boardProvider).currentPage,
);

final appModeProvider = Provider<AppMode>(
  (ref) => ref.watch(boardProvider).mode,
);

final selectedObjectIdsProvider = Provider<List<String>>(
  (ref) => ref.watch(boardProvider).selectedObjectIds,
);
