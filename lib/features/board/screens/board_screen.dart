// lib/features/board/screens/board_screen.dart
// ─────────────────────────────────────────────────────────────
// ボードスクリーン — FreeBoard.as に対応するメイン画面
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/board_provider.dart';
import '../models/board_object.dart';
import '../widgets/board_canvas.dart';

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final page = boardState.currentPage;
    final mode = boardState.mode;

    return Scaffold(
      appBar: AppBar(
        title: Text(page?.pageTitle.isEmpty == true ? '無題のページ' : page?.pageTitle ?? ''),
        actions: [
          // Undo ボタン
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '元に戻す',
            onPressed: boardState.canUndo
                ? () => ref.read(boardProvider.notifier).undo()
                : null,
          ),
          // Redo ボタン
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'やり直し',
            onPressed: boardState.canRedo
                ? () => ref.read(boardProvider.notifier).redo()
                : null,
          ),
          // モード切替
          PopupMenuButton<AppMode>(
            icon: Icon(mode == AppMode.teacherEdit
                ? Icons.edit
                : mode == AppMode.studentPlay
                    ? Icons.school
                    : Icons.slideshow),
            tooltip: 'モード切替',
            onSelected: (m) => ref.read(boardProvider.notifier).setMode(m),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: AppMode.teacherEdit,
                child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('教師編集モード')]),
              ),
              const PopupMenuItem(
                value: AppMode.studentPlay,
                child: Row(children: [Icon(Icons.school), SizedBox(width: 8), Text('生徒学習モード')]),
              ),
              const PopupMenuItem(
                value: AppMode.presentation,
                child: Row(children: [Icon(Icons.slideshow), SizedBox(width: 8), Text('発表モード')]),
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
                ref.read(boardProvider.notifier).moveObject(id, x, y);
              },
              onObjectSelected: (id) {
                ref.read(boardProvider.notifier).selectObject(id);
              },
            ),
      // 教師編集モード時だけ FAB を表示
      floatingActionButton: mode == AppMode.teacherEdit
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _showAddObjectMenu(context, ref),
            )
          : null,
    );
  }

  void _showAddObjectMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('オブジェクトを追加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _addTile(context, ref, Icons.text_fields, 'テキストボックス', 'LetterBox'),
            _addTile(context, ref, Icons.image, '画像ボックス', 'ImgBox'),
            _addTile(context, ref, Icons.quiz, '問題ボックス', 'QuestionBox'),
          ],
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context, WidgetRef ref, IconData icon, String label, String className) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        // テンプレートオブジェクトを追加
        final newObj = BoardObject(
          id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
          className: className,
          x: 100, y: 100, width: 200, height: 100,
          extra: className == 'LetterBox' ? {'text': 'テキスト'} : {},
        );
        ref.read(boardProvider.notifier).addObject(newObj);
      },
    );
  }
}
