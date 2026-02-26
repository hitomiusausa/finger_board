// lib/features/board/widgets/board_canvas.dart
// ─────────────────────────────────────────────────────────────
// ボードキャンバス — ドラッグ可能なオブジェクトを表示するメインキャンバス
// AS3 の FreeBoard + PageContentView に対応
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../shared/models/page_data.dart';
import '../models/board_object.dart';
import '../providers/board_provider.dart';
import 'objects/object_widget.dart';

class BoardCanvas extends StatelessWidget {
  final PageData page;
  final AppMode mode;
  final void Function(String id, double x, double y) onObjectMoved;
  final void Function(String? id) onObjectSelected;

  const BoardCanvas({
    super.key,
    required this.page,
    required this.mode,
    required this.onObjectMoved,
    required this.onObjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // キャンバス背景タップで選択解除
      onTap: () => onObjectSelected(null),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: page.objectsData.isEmpty
            ? _buildEmptyState()
            : Stack(
                children: page.objectsData
                    .where((obj) {
                      // 非表示フラグの処理
                      if (obj.hidden) return false;
                      // 学習モードで blindMode のオブジェクトは非表示
                      if (mode == AppMode.studentPlay && obj.blindMode) return false;
                      return true;
                    })
                    .map((obj) => _DraggableObject(
                          key: ValueKey(obj.id),
                          object: obj,
                          isDraggable: mode == AppMode.teacherEdit ||
                              obj.studentsModeDragEnabled,
                          onMoved: onObjectMoved,
                          onSelected: onObjectSelected,
                        ))
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'オブジェクトがありません\n右下の + ボタンで追加してください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── ドラッグ可能オブジェクトのラッパー ─────────────────────
class _DraggableObject extends StatefulWidget {
  final BoardObject object;
  final bool isDraggable;
  final void Function(String id, double x, double y) onMoved;
  final void Function(String? id) onSelected;

  const _DraggableObject({
    super.key,
    required this.object,
    required this.isDraggable,
    required this.onMoved,
    required this.onSelected,
  });

  @override
  State<_DraggableObject> createState() => _DraggableObjectState();
}

class _DraggableObjectState extends State<_DraggableObject> {
  late double _x;
  late double _y;
  double _startX = 0;
  double _startY = 0;
  double _dragStartX = 0;
  double _dragStartY = 0;

  @override
  void initState() {
    super.initState();
    _x = widget.object.x;
    _y = widget.object.y;
  }

  @override
  void didUpdateWidget(_DraggableObject old) {
    super.didUpdateWidget(old);
    // Undo/Redo 後に上位のステートから位置を更新
    if (old.object.x != widget.object.x || old.object.y != widget.object.y) {
      _x = widget.object.x;
      _y = widget.object.y;
    }
  }

  @override
  Widget build(BuildContext context) {
    final obj = widget.object;
    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onTap: () => widget.onSelected(obj.id),
        onPanStart: widget.isDraggable
            ? (details) {
                _startX = _x;
                _startY = _y;
                _dragStartX = details.globalPosition.dx;
                _dragStartY = details.globalPosition.dy;
              }
            : null,
        onPanUpdate: widget.isDraggable
            ? (details) {
                setState(() {
                  _x = _startX + (details.globalPosition.dx - _dragStartX);
                  _y = _startY + (details.globalPosition.dy - _dragStartY);
                });
              }
            : null,
        onPanEnd: widget.isDraggable
            ? (_) => widget.onMoved(obj.id, _x, _y)
            : null,
        child: SizedBox(
          width: obj.width * obj.scaleX,
          height: obj.height * obj.scaleY,
          child: ObjectWidget(object: obj),
        ),
      ),
    );
  }
}
