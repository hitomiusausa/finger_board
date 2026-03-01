import 'package:equatable/equatable.dart';

class BoardObjectChild extends Equatable {
  final String id;
  final String boardObjectId;
  final String text;
  final double scaleX;
  final double scaleY;
  final int childIndex;

  // Phase 1 では定義のみ（将来の縦書き対応用）
  final bool? isVertical;

  // Phase 1 では定義のみ（将来のルビ対応用）
  final String? subText;

  const BoardObjectChild({
    required this.id,
    required this.boardObjectId,
    required this.text,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    required this.childIndex,
    this.isVertical,
    this.subText,
  });

  factory BoardObjectChild.fromJson(Map<String, dynamic> json) {
    return BoardObjectChild(
      id: json['id'] as String,
      boardObjectId: json['board_object_id'] as String,
      text: json['text'] as String? ?? '',
      scaleX: (json['scale_x'] as num?)?.toDouble() ?? 1.0,
      scaleY: (json['scale_y'] as num?)?.toDouble() ?? 1.0,
      childIndex: json['child_index'] as int? ?? 0,
      isVertical: json['is_vertical'] as bool?,
      subText: json['sub_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_object_id': boardObjectId,
      'text': text,
      'scale_x': scaleX,
      'scale_y': scaleY,
      'child_index': childIndex,
      if (isVertical != null) 'is_vertical': isVertical,
      if (subText != null) 'sub_text': subText,
    };
  }

  @override
  List<Object?> get props => [
        id,
        boardObjectId,
        text,
        scaleX,
        scaleY,
        childIndex,
        isVertical,
        subText,
      ];
}
