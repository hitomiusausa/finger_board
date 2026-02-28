// lib/features/board/screens/board_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/board_provider.dart';
import '../models/board_object.dart';
import '../widgets/board_canvas.dart';
import '../../materials/providers/materials_provider.dart';
import '../../materials/models/teaching_material.dart';

class BoardScreen extends ConsumerStatefulWidget {
  final String? materialId;
  const BoardScreen({super.key, this.materialId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String get _materialId => widget.materialId ?? '';
  bool _isEditingTitle = false;
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initBoardIfNeeded();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _initBoardIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final currentPage = ref.read(boardProvider(_materialId)).currentPage;
      if (currentPage != null) return; // 既に初期化済み

      final currentMaterial = ref.read(currentMaterialProvider);
      
      if (currentMaterial != null && widget.materialId != null) {
        // 既存教材の場合：Supabase からページを読み込み
        try {
          await ref.read(boardProvider(_materialId).notifier).loadPages(widget.materialId!);
        } catch (e) {
          // エラー時はログに出力（loadPages 内で空ページ初期化済み）
          debugPrint('ページ読み込みエラー: $e');
        }
      } else {
        // 新規教材やデモの場合：空ページで初期化
        final title = currentMaterial?.title ?? '';
        ref.read(boardProvider(_materialId).notifier).initEmptyPage(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(boardProvider(_materialId));
    final page = boardState.currentPage;
    final mode = boardState.mode;
    final currentMaterial = ref.watch(currentMaterialProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(currentMaterial, page),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '元に戻す',
            onPressed: boardState.canUndo
                ? () => ref.read(boardProvider(_materialId).notifier).undo()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'やり直し',
            onPressed: boardState.canRedo
                ? () => ref.read(boardProvider(_materialId).notifier).redo()
                : null,
          ),
          // 保存ボタン（教材が選択されているときのみ表示）
          if (currentMaterial != null)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存',
              onPressed: () => _save(currentMaterial.id),
            ),
          PopupMenuButton<AppMode>(
            icon: Icon(mode == AppMode.teacherEdit
                ? Icons.edit
                : mode == AppMode.studentPlay
                    ? Icons.school
                    : Icons.slideshow),
            tooltip: 'モード切替',
            onSelected: (m) =>
                ref.read(boardProvider(_materialId).notifier).setMode(m),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: AppMode.teacherEdit,
                child: Row(children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('教師編集モード'),
                ]),
              ),
              PopupMenuItem(
                value: AppMode.studentPlay,
                child: Row(children: [
                  Icon(Icons.school),
                  SizedBox(width: 8),
                  Text('生徒学習モード'),
                ]),
              ),
              PopupMenuItem(
                value: AppMode.presentation,
                child: Row(children: [
                  Icon(Icons.slideshow),
                  SizedBox(width: 8),
                  Text('発表モード'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: page == null
          ? const Center(child: CircularProgressIndicator())
          : BoardCanvas(
              page: page,
              mode: mode,
              onObjectMoved: (id, x, y) {
                ref
                    .read(boardProvider(_materialId).notifier)
                    .moveObject(id, x, y);
              },
              onObjectSelected: (id) {
                ref
                    .read(boardProvider(_materialId).notifier)
                    .selectObject(id);
              },
            ),
      floatingActionButton: mode == AppMode.teacherEdit
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _showAddObjectMenu(),
            )
          : null,
    );
  }

  Future<void> _save(String materialId) async {
    final page = ref.read(boardProvider(_materialId)).currentPage;
    if (page == null) return;

    try {
      await ref.read(materialsServiceProvider).savePage(
            materialId: materialId,
            pageOrder: 0,
            pageData: page,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存しました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddObjectMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('オブジェクトを追加',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _addTile(Icons.text_fields, 'テキストボックス', 'LetterBox'),
            _addTile(Icons.image, '画像ボックス', 'ImgBox'),
            _addTile(Icons.quiz, '問題ボックス', 'QuestionBox'),
          ],
        ),
      ),
    );
  }

  Widget _addTile(IconData icon, String label, String className) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
        final newObj = BoardObject(
          id: const Uuid().v4(),
          className: className,
          x: 100,
          y: 100,
          width: 200,
          height: 100,
          extra: className == 'LetterBox' ? {'text': 'テキスト'} : {},
        );
        ref.read(boardProvider(_materialId).notifier).addObject(newObj);
      },
    );
  }

  Widget _buildTitle(TeachingMaterial? currentMaterial, dynamic page) {
    final displayTitle = currentMaterial?.title ?? page?.pageTitle ?? '無題のページ';

    if (_isEditingTitle && currentMaterial != null) {
      return TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'タイトルを入力',
          hintStyle: TextStyle(color: Colors.white70),
        ),
        onSubmitted: (value) => _saveTitleEdit(currentMaterial.id, value),
        onTapOutside: (_) => _saveTitleEdit(currentMaterial.id, _titleController.text),
      );
    }

    if (currentMaterial != null) {
      return GestureDetector(
        onTap: () => _startTitleEdit(displayTitle),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayTitle),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 18, color: Colors.white70),
          ],
        ),
      );
    }

    return Text(displayTitle);
  }

  void _startTitleEdit(String currentTitle) {
    setState(() {
      _isEditingTitle = true;
      _titleController.text = currentTitle;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );
    });
  }

  void _saveTitleEdit(String materialId, String newTitle) async {
    if (!_isEditingTitle) return;
    
    setState(() {
      _isEditingTitle = false;
    });

    if (newTitle.trim().isEmpty) {
      return;
    }

    try {
      await ref.read(updateMaterialTitleProvider.notifier).updateTitle(materialId, newTitle.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('タイトルを更新しました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タイトル更新失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
