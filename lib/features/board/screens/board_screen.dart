// lib/features/board/screens/board_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/board_provider.dart';
import '../providers/mun_import_provider.dart';
import '../models/board_object.dart';
import '../widgets/board_canvas.dart';
import '../../materials/providers/materials_provider.dart';

class BoardScreen extends ConsumerStatefulWidget {
  final String? materialId;
  const BoardScreen({super.key, this.materialId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String get _materialId => widget.materialId ?? '';

  @override
  void initState() {
    super.initState();
    _initBoardIfNeeded();
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
        title: Text(
          currentMaterial?.title ?? page?.pageTitle ?? '無題のページ',
        ),
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
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: "import_fab",
                  child: const Icon(Icons.file_upload),
                  onPressed: () => _showImportMenu(),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "add_fab", 
                  child: const Icon(Icons.add),
                  onPressed: () => _showAddObjectMenu(),
                ),
              ],
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

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('ファイルをインポート',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('.munファイル'),
              subtitle: const Text('教材ファイルをインポート'),
              onTap: () {
                Navigator.pop(context);
                _pickAndImportFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.demo_outlined),
              title: const Text('デモインポート'),
              subtitle: const Text('サンプル教材を読み込み'),
              onTap: () {
                Navigator.pop(context);
                _importDemo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mun', 'json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      
      final file = result.files.first;
      final filename = file.name;
      
      if (file.bytes != null) {
        // Web環境: bytes使用
        await ref.read(munImportProvider.notifier).importFromBytes(
          file.bytes!,
          filename,
        );
      } else if (file.path != null) {
        // Native環境: path使用
        await ref.read(munImportProvider.notifier).importFromPath(file.path!);
      } else {
        throw Exception('ファイル読み込みに失敗しました');
      }

      _handleImportResult();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ファイル選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importDemo() {
    final demoResult = ref.read(munImportProvider.notifier);
    // デモはすぐに実行可能（非同期処理不要）
    final result = ref.read(munImportProvider);
    
    // デモデータを直接load
    _loadDemoData();
  }

  void _loadDemoData() {
    // デモ用のJSONデータを直接作成してloadPage
    const demoJson = {
      'pageTitle': 'デモページ',
      'objectsData': [
        {
          'id': '1',
          'className': 'LetterBox',
          'x': 100.0,
          'y': 100.0,
          'width': 200.0,
          'height': 80.0,
          'extra': {'text': 'こんにちは！'},
        },
        {
          'id': '2',
          'className': 'ImgBox',
          'x': 350.0,
          'y': 150.0,
          'width': 150.0,
          'height': 150.0,
          'extra': {},
        },
      ],
      'check_on': false,
      'animationData': {},
    };

    ref.read(boardProvider(_materialId).notifier).loadPage(demoJson);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('デモデータを読み込みました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleImportResult() {
    final importState = ref.read(munImportProvider);
    
    importState.when(
      data: (result) {
        if (result == null) return;
        
        if (result.success && result.pages.isNotEmpty) {
          // 最初のページをボードに読み込む
          final page = result.pages.first;
          final munJson = page.toJson();
          ref.read(boardProvider(_materialId).notifier).loadPage(munJson);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${result.docTitle ?? 'ファイル'}を読み込みました'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('インポートエラー: ${result.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      loading: () {
        // ローディング表示はCircularProgressIndicatorで自動処理
      },
      error: (error, stackTrace) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラー: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
