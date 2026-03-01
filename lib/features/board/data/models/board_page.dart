import 'package:equatable/equatable.dart';

class BoardPage extends Equatable {
  final String id;
  final String boardId;
  final int pageIndex;
  final String? backgroundType;
  final String? backgroundValue;

  const BoardPage({
    required this.id,
    required this.boardId,
    required this.pageIndex,
    this.backgroundType,
    this.backgroundValue,
  });

  factory BoardPage.fromJson(Map<String, dynamic> json) {
    return BoardPage(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      pageIndex: json['page_index'] as int? ?? 0,
      backgroundType: json['background_type'] as String?,
      backgroundValue: json['background_value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'page_index': pageIndex,
      if (backgroundType != null) 'background_type': backgroundType,
      if (backgroundValue != null) 'background_value': backgroundValue,
    };
  }

  @override
  List<Object?> get props => [
        id,
        boardId,
        pageIndex,
        backgroundType,
        backgroundValue,
      ];
}
