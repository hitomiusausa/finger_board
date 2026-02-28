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
import '../../materials/models/teaching_material.dart';

class BoardScreen extends ConsumerStatefulWidget {
  final String? materialId;
  const BoardScreen({super.key, this.materialId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String get _materialId => widget.materialId ?? '';
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initBoardIfNeeded();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _initBoardIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final currentPage = ref.read(boardProvider(_materialId)).currentPage;
      if (currentPage != null) return;

      final currentMaterial = ref.read(currentMaterialProvider);

      if (currentMaterial != null && widget.materialId != null) {
        try {
          await ref.read(boardProvider(_materialId).notifier).loadPages(widget.materialId!);
        } catch (e) {
          debugPrint('ページ読み込みエラー: $e');
        }
      } else {
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
          if (mode == AppMode.teacherEdit) ...[
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
            if (currentMaterial != null)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: '保存',
                onPressed: () => _save(currentMaterial.id),
              ),
          ],
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
          : Column(
              children: [
                if (mode == AppMode.teacherEdit) _buildPageTabBar(),
                Expanded(
                  child: BoardCanvas(
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
                ),
              ],
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
    final boardState = ref.read(boardProvider(_materialId));
    final pages = boardState.pages;
    if (pages.isEmpty) return;

    try {
      final service = ref.read(materialsServiceProvider);
      await service.saveAllPages(materialId: materialId, pages: pages);

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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

    if (currentMaterial != null) {
      return GestureDetector(
        onTap: () => _showTitleEditDialog(currentMaterial, displayTitle),
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

  void _showTitleEditDialog(TeachingMaterial currentMaterial, String currentTitle) {
    _titleController.text = currentTitle;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タイトルを編集'),
        content: TextField(
          controller: _titleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'タイトルを入力'),
          onSubmitted: (value) {
            Navigator.pop(context);
            _saveTitleEdit(currentMaterial.id, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveTitleEdit(currentMaterial.id, _titleController.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

void _saveTitleEdit(String materialId, String newTitle) async {
    if (newTitle.trim().isEmpty) return;

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
      // AutoDisposeAsyncNotifier の既知の問題は無視
      if (mounted && !e.toString().contains('Future already completed')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タイトル更新失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              leading: const Icon(Icons.science_outlined),
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
        await ref.read(munImportProvider.notifier).importFromBytes(
          file.bytes!,
          filename,
        );
      } else if (file.path != null) {
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
    _loadDemoData();
  }

  void _loadDemoData() {
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
      loading: () {},
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

  Widget _buildPageTabBar() {
    final boardState = ref.watch(boardProvider(_materialId));
    final pages = boardState.pages;
    final currentIndex = boardState.currentPageIndex;

    return Container(
      height: 50,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () {
                    ref.read(boardProvider(_materialId).notifier)
                        .setCurrentPageIndex(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pages[index].pageTitle.isEmpty
                              ? 'ページ ${index + 1}'
                              : pages[index].pageTitle,
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (pages.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ref.read(boardProvider(_materialId).notifier)
                                  .deletePage(index);
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(boardProvider(_materialId).notifier).addPage();
            },
            tooltip: 'ページ追加',
          ),
        ],
      ),
    );
  }
}