// lib/features/board/providers/board_provider.dart
// ─────────────────────────────────────────────────────────────
// ボードの状態管理（Riverpod）
// AS3 の FB.as グローバルシングルトンと FreeBoardIndex の役割を分散管理に置き換え
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/board_object.dart';
import '../../../shared/models/page_data.dart';
import '../models/undo_command.dart';
import '../../materials/services/materials_service.dart';
import '../../materials/providers/materials_provider.dart';

// ── アプリモード ────────────────────────────────────────────
enum AppMode {
  teacherEdit,   // 教師編集モード（旧 editorsMode）
  studentPlay,   // 生徒学習モード（旧 studentsVersion）
  presentation,  // 発表モード
}

// ── ボードの状態 ────────────────────────────────────────────
@immutable
class BoardState {
  final List<PageData> pages;            // 全ページのリスト
  final int currentPageIndex;            // 現在表示中のページインデックス
  final List<String> selectedObjectIds; // 選択中オブジェクトID
  final AppMode mode;
  final bool canUndo;
  final bool canRedo;

  const BoardState({
    this.pages = const [],
    this.currentPageIndex = 0,
    this.selectedObjectIds = const [],
    this.mode = AppMode.teacherEdit,
    this.canUndo = false,
    this.canRedo = false,
  });

  /// 現在表示中のページを取得
  PageData? get currentPage {
    if (pages.isEmpty || currentPageIndex < 0 || currentPageIndex >= pages.length) {
      return null;
    }
    return pages[currentPageIndex];
  }

  BoardState copyWith({
    List<PageData>? pages,
    int? currentPageIndex,
    List<String>? selectedObjectIds,
    AppMode? mode,
    bool? canUndo,
    bool? canRedo,
  }) =>
      BoardState(
        pages: pages ?? this.pages,
        currentPageIndex: currentPageIndex ?? this.currentPageIndex,
        selectedObjectIds: selectedObjectIds ?? this.selectedObjectIds,
        mode: mode ?? this.mode,
        canUndo: canUndo ?? this.canUndo,
        canRedo: canRedo ?? this.canRedo,
      );
}

// ── Board Provider（状態ノーティファイア）──────────────────
class BoardNotifier extends StateNotifier<BoardState> {
  final UndoManager _undoManager = UndoManager();
  final MaterialsService _materialsService;

  BoardNotifier(this._materialsService) : super(const BoardState());

  /// ページを読み込む（.mun JSON から）
  void loadPage(Map<String, dynamic> munJson) {
    final page = PageData.fromMunJson(munJson);
    _undoManager.reset();
    state = state.copyWith(
      pages: [page],
      currentPageIndex: 0,
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
    
    // 現在のページを新しいページに置き換え
    final newPages = List<PageData>.from(state.pages);
    newPages[state.currentPageIndex] = newPage;
    
    state = state.copyWith(
      pages: newPages,
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
      final newPages = List<PageData>.from(state.pages);
      newPages[state.currentPageIndex] = newPage;
      
      state = state.copyWith(
        pages: newPages,
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
      final newPages = List<PageData>.from(state.pages);
      newPages[state.currentPageIndex] = newPage;
      
      state = state.copyWith(
        pages: newPages,
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
    
    final newPages = List<PageData>.from(state.pages);
    newPages[state.currentPageIndex] = newPage;
    
    state = state.copyWith(
      pages: newPages,
      canUndo: _undoManager.canUndo,
      canRedo: _undoManager.canRedo,
    );
  }

  /// Supabase から教材のページを読み込む
  Future<void> loadPages(String materialId) async {
    try {
      final pages = await _materialsService.getPages(materialId);
      
      if (pages.isNotEmpty) {
        // 全ページを読み込み、最初のページを表示
        _undoManager.reset();
        state = state.copyWith(
          pages: pages,
          currentPageIndex: 0,
          selectedObjectIds: [],
          canUndo: false,
          canRedo: false,
        );
      } else {
        // ページがない場合は空ページを初期化
        initEmptyPage('');
      }
    } catch (e) {
      // エラー時は空ページで初期化
      initEmptyPage('');
      rethrow;
    }
  }

  /// 空のページを初期化する（新規教材用）
  void initEmptyPage(String title) {
    _undoManager.reset();
    final emptyPage = PageData(
      id: _generateUuid(),
      pageTitle: 'ページ 1',
      objectsData: const [],
    );
    state = state.copyWith(
      pages: [emptyPage],
      currentPageIndex: 0,
      selectedObjectIds: [],
      canUndo: false,
      canRedo: false,
    );
  }

  /// ページをクリアする（画面遷移前のリセット用）
  void clearPage() {
    _undoManager.reset();
    state = const BoardState();
  }

  /// ページを切り替える
  void setCurrentPageIndex(int index) {
    if (index >= 0 && index < state.pages.length) {
      _undoManager.reset(); // ページ切り替え時はUndoをリセット
      state = state.copyWith(
        currentPageIndex: index,
        selectedObjectIds: [],
        canUndo: false,
        canRedo: false,
      );
    }
  }

  /// 新しいページを追加
  void addPage() {
    final newPage = PageData(
      id: _generateUuid(),
      pageTitle: 'ページ ${state.pages.length + 1}',
      objectsData: const [],
    );
    final newPages = List<PageData>.from(state.pages);
    newPages.add(newPage);
    
    state = state.copyWith(
      pages: newPages,
      currentPageIndex: newPages.length - 1, // 新しいページに切り替え
      selectedObjectIds: [],
    );
  }

  /// ページを削除
  void deletePage(int index) {
    if (state.pages.length <= 1) return; // 最低1ページは残す
    if (index < 0 || index >= state.pages.length) return;

    final newPages = List<PageData>.from(state.pages);
    newPages.removeAt(index);
    
    // 現在のページインデックスを調整
    int newIndex = state.currentPageIndex;
    if (index <= state.currentPageIndex && state.currentPageIndex > 0) {
      newIndex = state.currentPageIndex - 1;
    } else if (state.currentPageIndex >= newPages.length) {
      newIndex = newPages.length - 1;
    }

    _undoManager.reset();
    state = state.copyWith(
      pages: newPages,
      currentPageIndex: newIndex,
      selectedObjectIds: [],
      canUndo: false,
      canRedo: false,
    );
  }

  String _generateUuid() => const Uuid().v4();
}

// ── Provider 定義（family: materialId ごとに独立した状態）────
final boardProvider =
    StateNotifierProvider.family<BoardNotifier, BoardState, String>(
  (ref, materialId) {
    final materialsService = ref.watch(materialsServiceProvider);
    return BoardNotifier(materialsService);
  },
);
