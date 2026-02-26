// lib/features/board/widgets/objects/object_widget.dart
// ─────────────────────────────────────────────────────────────
// オブジェクト種別に応じた表示ウィジェット
// AS3 の各 Box クラス（LetterBox / ImgBox / QuestionBox など）に対応
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/board_object.dart';

class ObjectWidget extends StatelessWidget {
  final BoardObject object;

  const ObjectWidget({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    return switch (object.className) {
      'LetterBox'    => _LetterBoxWidget(object: object),
      'ImgBox'       => _ImgBoxWidget(object: object),
      'QuestionBox'  => _QuestionBoxWidget(object: object),
      'AssembleBox'  => _AssembleBoxWidget(object: object),
      'LineOnBoard'  => _LineWidget(object: object),
      _ => _DefaultBoxWidget(object: object),
    };
  }
}

// ── LetterBox — テキストボックス ─────────────────────────────
class _LetterBoxWidget extends StatelessWidget {
  final BoardObject object;
  const _LetterBoxWidget({required this.object});

  @override
  Widget build(BuildContext context) {
    final text = object.extra['text'] as String? ?? '';
    return Container(
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
    );
  }
}

// ── ImgBox — 画像ボックス ─────────────────────────────────────
class _ImgBoxWidget extends StatelessWidget {
  final BoardObject object;
  const _ImgBoxWidget({required this.object});

  @override
  Widget build(BuildContext context) {
    final imageUrl = object.extra['imageUrl'] as String?;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.orange[300]!, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: imageUrl != null
          ? Image.network(imageUrl, fit: BoxFit.cover)
          : const Icon(Icons.image, size: 48, color: Colors.grey),
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
      child: Stack(
        children: object.children
            .map((child) => Positioned(
                  left: child.x,
                  top: child.y,
                  width: child.width,
                  height: child.height,
                  child: ObjectWidget(object: child),
                ))
            .toList(),
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
