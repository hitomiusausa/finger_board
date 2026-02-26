// lib/features/board/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/board_provider.dart';
import '../../../shared/services/mun_import_service.dart';
import '../../materials/providers/materials_provider.dart';
import 'board_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // 教材作成の結果を監視
    ref.listen(createMaterialProvider, (_, next) {
      next.whenData((material) {
        if (material == null) return;
        ref.read(currentMaterialProvider.notifier).state = material;
        ref.read(boardProvider.notifier).loadPage({
          'pageTitle': '新しいページ',
          'objectsData': [],
        });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BoardScreen()),
          );
        }
      });
      if (next.hasError) {
        _showError(next.error.toString());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Finger Board', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('データを読み込み中...'),
                ],
              ),
            )
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴ
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.touch_app, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'Finger Board',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 8),
            Text(
              '特別支援教育向けインタラクティブ教材',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 56),

            // ── アクションカード ──────────────────────────
            _actionCard(
              icon: Icons.play_circle_fill,
              color: const Color(0xFF10B981),
              title: 'デモを体験する',
              subtitle: 'サンプル教材でキャンバスを試す',
              onTap: _loadDemo,
            ),
            const SizedBox(height: 16),
            _actionCard(
              icon: Icons.add_circle,
              color: const Color(0xFF4A90E2),
              title: '新しい教材を作成',
              subtitle: '空のキャンバスから始める',
              onTap: _createNewPage,
            ),
            const SizedBox(height: 16),
            _actionCard(
              icon: Icons.file_upload,
              color: const Color(0xFF8B5CF6),
              title: '.mun ファイルを読み込む',
              subtitle: '既存の Finger Board 教材をインポート',
              onTap: _importMunFile,
            ),

            const SizedBox(height: 40),
            // バージョン情報
            Text(
              'Flutter 3.19.6 • Phase 1 MVP',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ── アクション ─────────────────────────────────────────────

  Future<void> _loadDemo() async {
    setState(() => _isLoading = true);
    final result = MunImportService.importDemo();
    setState(() => _isLoading = false);

    if (!result.success || result.pages.isEmpty) {
      _showError(result.errorMessage ?? '不明なエラー');
      return;
    }
    ref.read(boardProvider.notifier).loadPage(
      result.pages.first.toJson(),
    );
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BoardScreen()),
      );
    }
  }

  Future<void> _createNewPage() async {
    ref.read(createMaterialProvider.notifier).create('新しい教材');
  }

  Future<void> _importMunFile() async {
    // ファイルピッカーは Phase 1.5 で実装予定
    // 現在はデモ JSON ファイルのパスを固定で読み込む
    const demoJsonPath =
        '/Users/usausagi/Dropbox/Semiosis共有 (2)/010 個人/くが/claud/mun_output/page/main/main.json';

    setState(() => _isLoading = true);
    final result = await MunImportService.importFromJsonFile(demoJsonPath);
    setState(() => _isLoading = false);

    if (!result.success || result.pages.isEmpty) {
      _showError(result.errorMessage ?? 'インポート失敗');
      return;
    }
    ref.read(boardProvider.notifier).loadPage(result.pages.first.toJson());
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BoardScreen()),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
