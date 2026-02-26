// lib/features/board/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/router/app_router.dart';
import '../../materials/providers/materials_provider.dart';
import '../../materials/models/teaching_material.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);

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
      body: materialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('エラー: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(materialsProvider.notifier).refresh(),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
        data: (materials) => materials.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () => ref.read(materialsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: materials.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _MaterialCard(material: materials[index]),
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

    final notifier = ref.read(createMaterialProvider.notifier);
    await notifier.create(title.trim());

    final result = ref.read(createMaterialProvider);
    result.whenOrNull(
      data: (material) {
        if (material != null) {
          ref.read(materialsProvider.notifier).refresh();
          ref.read(currentMaterialProvider.notifier).state = material;
          // ctxではなくrouterを直接使う
          ref.read(routerProvider).push('/board/${material.id}');
        }
      },
      error: (e, _) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('作成失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}

class _MaterialCard extends ConsumerWidget {
  final TeachingMaterial material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.book, size: 36),
        title: Text(
          material.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '更新: ${_formatDate(material.updatedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ref.read(currentMaterialProvider.notifier).state = material;
          context.push('/board/${material.id}');
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
          Text('教材がまだありません',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('右下のボタンで最初の教材を作りましょう！',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
