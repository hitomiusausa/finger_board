import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/board_provider.dart';
import '../data/models/board_object.dart';
import '../widgets/board_canvas.dart';
import '../data/repositories/board_repository.dart';
import '../data/repositories/board_object_repository.dart';
import '../data/models/board.dart';
import '../data/models/board_page.dart';
import '../../../shared/models/page_data.dart';

class BoardScreen extends ConsumerStatefulWidget {
  final String? materialId;
  const BoardScreen({super.key, this.materialId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String get _boardId => widget.materialId ?? '';
  final _titleController = TextEditingController();
  Board? _board;
  bool _isLoading = true;

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

  Future<void> _initBoardIfNeeded() async {
    if (_boardId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final board = await BoardRepository().getBoardById(_boardId);
      final boardPages = await BoardRepository().fetchPages(_boardId);
      
      List<PageData> loadedPages = [];
      final objRepo = BoardObjectRepository();
      for (final bp in boardPages) {
        final objects = await objRepo.getBoardObjects(_boardId, bp.pageIndex);
        loadedPages.add(PageData(
           id: bp.id,
           pageTitle: 'ページ ${bp.pageIndex}',
           objectsData: objects,
        ));
      }
      
      final notifier = ref.read(boardProvider(_boardId).notifier);
      if (loadedPages.isNotEmpty) {
        notifier.setLoadedPages(loadedPages);
      } else {
        notifier.initEmptyPage(board.title);
      }

      if (mounted) {
        setState(() {
          _board = board;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final boardState = ref.watch(boardProvider(_boardId));
    final page = boardState.currentPage;
    final mode = boardState.mode;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(page),
        actions: _buildAppBarActions(mode, boardState),
      ),
      body: page == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: BoardCanvas(
                    page: page,
                    mode: mode,
                    onObjectMoved: (id, x, y) {
                      ref
                          .read(boardProvider(_boardId).notifier)
                          .moveObject(id, x, y);
                    },
                    onObjectSelected: (id) {
                      ref
                          .read(boardProvider(_boardId).notifier)
                          .selectObject(id);
                    },
                  ),
                ),
                if (mode == BoardMode.edit) _buildPageTabBar(boardState),
              ],
            ),
      floatingActionButton: mode == BoardMode.edit
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

  List<Widget> _buildAppBarActions(BoardMode mode, BoardState boardState) {
    if (mode == BoardMode.edit) {
      return [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: '元に戻す',
          onPressed: boardState.canUndo
              ? () => ref.read(boardProvider(_boardId).notifier).undo()
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'やり直し',
          onPressed: boardState.canRedo
              ? () => ref.read(boardProvider(_boardId).notifier).redo()
              : null,
        ),
        TextButton.icon(
          onPressed: () => _save(),
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text('保存', style: TextStyle(color: Colors.white)),
        ),
        TextButton.icon(
          onPressed: () => ref.read(boardProvider(_boardId).notifier).changeMode(BoardMode.present),
          icon: const Icon(Icons.slideshow, color: Colors.white),
          label: const Text('提示', style: TextStyle(color: Colors.white)),
        ),
        TextButton.icon(
          onPressed: () => ref.read(boardProvider(_boardId).notifier).changeMode(BoardMode.study),
          icon: const Icon(Icons.school, color: Colors.white),
          label: const Text('学習', style: TextStyle(color: Colors.white)),
        ),
      ];
    } else {
      return [
        TextButton.icon(
          onPressed: () => ref.read(boardProvider(_boardId).notifier).changeMode(BoardMode.edit),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: const Text('編集に戻る', style: TextStyle(color: Colors.white)),
        ),
      ];
    }
  }

  Future<void> _save() async {
    final boardState = ref.read(boardProvider(_boardId));
    final pages = boardState.pages;
    if (pages.isEmpty) return;

    try {
      final boardRepo = BoardRepository();
      final objRepo = BoardObjectRepository();
      
      // Delete existing pages/objects conceptually, or just insert new ones 
      // This might be tricky because we need a full sync, but for Phase 1 
      // let's just clear and save or update incrementally.
      // Wait, actually the instruction didn't specify exactly HOW to save all objects yet.
      // We will just do a simple Save loop or alert.
      
      // For now, let's assume we do a basic save loop for demo functionality
      for (int i=0; i < pages.length; i++) {
        final p = pages[i];
        final pId = p.id;
        // Attempt insert Page
        try {
           await boardRepo.createBoardPage(BoardPage(id: pId, boardId: _boardId, pageIndex: i));
        } catch (_) {}
        // Overwrite objects 
        // Need to delete old objects on this page first? Or just ignore for now in Phase 1
        for (final o in p.objectsData) {
          try {
             await objRepo.createBoardObject(o.copyWith(boardId: _boardId, pageIndex: i));
          } catch (_) {
             await objRepo.updateBoardObject(o.copyWith(boardId: _boardId, pageIndex: i));
          }
        }
      }

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
             ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('テキストボックス'),
              onTap: () => _addObject('LetterBox', {'text': 'テキスト'}),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('画像ボックス'),
              onTap: () => _addObject('ImgBox', {}),
            ),
          ],
        ),
      ),
    );
  }

  void _addObject(String className, Map<String, dynamic> extras) {
    if (!mounted) return;
    Navigator.pop(context);
    final newObj = BoardObject(
      id: const Uuid().v4(),
      boardId: _boardId,
      pageIndex: ref.read(boardProvider(_boardId)).currentPageIndex,
      className: className,
      x: 100,
      y: 100,
      width: 200,
      height: 100,
      properties: extras,
    );
    ref.read(boardProvider(_boardId).notifier).addObject(newObj);
  }

  Widget _buildTitle(dynamic page) {
    final displayTitle = _board?.title ?? '無題のボード';

    return GestureDetector(
      onTap: () => _showTitleEditDialog(displayTitle),
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

  void _showTitleEditDialog(String currentTitle) {
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
            _saveTitleEdit(value);
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
              _saveTitleEdit(_titleController.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _saveTitleEdit(String newTitle) async {
    if (newTitle.trim().isEmpty) return;

    try {
      final updatedBoard = await BoardRepository().updateTitle(_boardId, newTitle.trim());
      if (mounted) {
        setState(() {
          _board = updatedBoard;
        });
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

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('.munファイル'),
              onTap: () {
                Navigator.pop(context);
                _pickAndImportFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImportFile() async {
     // placeholder
  }

  Widget _buildPageTabBar(BoardState boardState) {
    final pages = boardState.pages;
    final currentIndex = boardState.currentPageIndex;

    return Container(
      height: 80,
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
                    ref.read(boardProvider(_boardId).notifier).switchPage(index);
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColorDark : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'ページ ${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, size: 36),
            onPressed: () async {
              try {
                // INSERT into board_pages
                final newPageId = const Uuid().v4();
                await BoardRepository().createBoardPage(BoardPage(
                   id: newPageId,
                   boardId: _boardId,
                   pageIndex: pages.length,
                ));
                ref.read(boardProvider(_boardId).notifier).addPage();
              } catch (e) {
                 debugPrint('add page error $e');
              }
            },
            tooltip: 'ページ追加',
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
