import 'package:flutter/material.dart';
import '../../data/models/board_object_child.dart';

class LetterBoxWidget extends StatelessWidget {
  final BoardObjectChild child;
  final double baseFontSize;

  const LetterBoxWidget({
    super.key,
    required this.child,
    this.baseFontSize = 24.0, // 基本となるフォントサイズ（必要に応じて調整）
  });

  @override
  Widget build(BuildContext context) {
    // scaleX を使用して fontSize を調整
    final fontSize = baseFontSize * child.scaleX;

    // Phase 1: 横書きのみの実装
    // child.text を Text ウィジェットで表示
    return Text(
      child.text,
      style: TextStyle(
        fontSize: fontSize,
        // Phase 1 では横書き固定のため、特殊な設定は不要
      ),
      textAlign: TextAlign.center, // デフォルトで中央揃えにしておく
    );
  }
}
