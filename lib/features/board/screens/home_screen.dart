// lib/features/board/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/repositories/board_repository.dart';
import '../data/models/board.dart';

final boardsProvider = FutureProvider.autoDispose<List<Board>>((ref) async {
  return await BoardRepository().fetchBoards();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finger Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: boardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('エラー: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(boardsProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
        data: (boards) => boards.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () async { ref.invalidate(boardsProvider); },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: boards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _BoardCard(board: boards[index]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('新しい教材'),
        onPressed: () => _showCreateDialog(context, ref),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('教材を作成'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '教材のタイトル',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _create(ctx, ref, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => _create(ctx, ref, controller.text),
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext ctx, WidgetRef ref, String title) async {
    if (title.trim().isEmpty) return;
    Navigator.pop(ctx);

    try {
      final newBoard = Board(
        id: const Uuid().v4(),
        userId: supabase.auth.currentUser?.id,
        title: title.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await BoardRepository().createBoard(newBoard);
      ref.invalidate(boardsProvider);
      if (ctx.mounted) {
        ctx.go('/board/${newBoard.id}');
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('作成失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _BoardCard extends ConsumerWidget {
  final Board board;
  const _BoardCard({required this.board});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.dashboard, size: 36),
        title: Text(
          board.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '更新: ${_formatDate(board.updatedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.go('/board/${board.id}');
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('ボードがまだありません',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('右下のボタンで最初のボードを作りましょう！',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
