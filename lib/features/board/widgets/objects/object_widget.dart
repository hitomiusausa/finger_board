// lib/features/board/widgets/objects/object_widget.dart
// ─────────────────────────────────────────────────────────────
// オブジェクト種別に応じた表示ウィジェット
// AS3 の各 Box クラス（LetterBox / ImgBox / QuestionBox など）に対応
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../data/models/board_object.dart';
import '../../providers/board_provider.dart';

class ObjectWidget extends StatelessWidget {
  final BoardObject object;
  final BoardMode mode;

  const ObjectWidget({super.key, required this.object, required this.mode});

  @override
  Widget build(BuildContext context) {
    return switch (object.className) {
      'LetterBox'    => _LetterBoxWidget(object: object, mode: mode),
      'ImgBox'       => _ImgBoxWidget(object: object, mode: mode),
      'QuestionBox'  => _QuestionBoxWidget(object: object),
      'AssembleBox'  => _AssembleBoxWidget(object: object),
      'LineOnBoard'  => _LineWidget(object: object),
      _ => _DefaultBoxWidget(object: object),
    };
  }
}

// ── LetterBox — テキストボックス ─────────────────────────────
class _LetterBoxWidget extends StatefulWidget {
  final BoardObject object;
  final BoardMode mode;
  const _LetterBoxWidget({required this.object, required this.mode});

  @override
  State<_LetterBoxWidget> createState() => _LetterBoxWidgetState();
}

class _LetterBoxWidgetState extends State<_LetterBoxWidget> {
  bool _isHighlighted = false;
  bool? _isCorrect; // null=未回答, true=正解, false=不正解

  void _onTap() {
    if (widget.mode == BoardMode.present) {
      setState(() => _isHighlighted = !_isHighlighted);
    } else if (widget.mode == BoardMode.study) {
      final answerType = widget.object.properties?['answerType'] as String?;
      if (answerType == 'tap') {
        setState(() => _isCorrect = !(_isCorrect ?? false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.object.properties?['text'] as String? ?? '';
    
    return GestureDetector(
      onTap: widget.mode == BoardMode.present || (widget.mode == BoardMode.study && widget.object.properties?['answerType'] == 'tap')
          ? _onTap
          : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue[300]!, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isHighlighted)
            Positioned.fill(
              child: Container(color: Colors.yellow.withValues(alpha: 0.4)),
            ),
          if (_isCorrect != null)
            Positioned.fill(
              child: Container(
                color: _isCorrect! ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                child: Center(
                  child: Icon(
                    _isCorrect! ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── ImgBox — 画像ボックス ─────────────────────────────────────
class _ImgBoxWidget extends StatefulWidget {
  final BoardObject object;
  final BoardMode mode;
  const _ImgBoxWidget({required this.object, required this.mode});

  @override
  State<_ImgBoxWidget> createState() => _ImgBoxWidgetState();
}

class _ImgBoxWidgetState extends State<_ImgBoxWidget> {
  bool _isHighlighted = false;
  bool? _isCorrect; // null=未回答, true=正解, false=不正解

  void _onTap() {
    if (widget.mode == BoardMode.present) {
      setState(() => _isHighlighted = !_isHighlighted);
    } else if (widget.mode == BoardMode.study) {
      final answerType = widget.object.properties?['answerType'] as String?;
      if (answerType == 'tap') {
        setState(() => _isCorrect = !(_isCorrect ?? false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.object.properties?['imageUrl'] as String?;
    return GestureDetector(
      onTap: widget.mode == BoardMode.present || (widget.mode == BoardMode.study && widget.object.properties?['answerType'] == 'tap')
          ? _onTap
          : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.orange[300]!, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: imageUrl != null
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 48, color: Colors.grey),
          ),
          if (_isHighlighted)
            Positioned.fill(
              child: Container(color: Colors.yellow.withValues(alpha: 0.4)),
            ),
          if (_isCorrect != null)
            Positioned.fill(
              child: Container(
                color: _isCorrect! ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                child: Center(
                  child: Icon(
                    _isCorrect! ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── QuestionBox — 問題ボックス ────────────────────────────────
class _QuestionBoxWidget extends StatelessWidget {
  final BoardObject object;
  const _QuestionBoxWidget({required this.object});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        border: Border.all(color: Colors.amber[400]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.quiz, size: 32, color: Colors.amber),
      ),
    );
  }
}

// ── AssembleBox — 組み立てボックス（子を持つコンテナ）─────────
class _AssembleBoxWidget extends StatelessWidget {
  final BoardObject object;
  const _AssembleBoxWidget({required this.object});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Stack(
        children: [], // Phase 1: Not fully supporting children yet
      ),
    );
  }
}

// ── LineOnBoard — 直線 ───────────────────────────────────────
class _LineWidget extends StatelessWidget {
  final BoardObject object;
  const _LineWidget({required this.object});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LinePainter());
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      Paint()..color = Colors.black..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── デフォルト（未知のクラス名）────────────────────────────
class _DefaultBoxWidget extends StatelessWidget {
  final BoardObject object;
  const _DefaultBoxWidget({required this.object});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[400]!, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          object.className,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
