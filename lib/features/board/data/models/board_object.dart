import 'package:equatable/equatable.dart';

class BoardObject extends Equatable {
  final String id;
  final String pageId;
  final int pageIndex;
  final String className; // 'AssembleBox', 'ImgBox', 'QBox'
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double? frameMargin;
  final double? frameRoundness;
  final List<String>? correctAnswers;
  final Map<String, dynamic>? properties;

  const BoardObject({
    required this.id,
    required this.pageId,
    required this.pageIndex,
    required this.className,
    this.x = 0.0,
    this.y = 0.0,
    this.width = 100.0,
    this.height = 100.0,
    this.rotation = 0.0,
    this.frameMargin,
    this.frameRoundness,
    this.correctAnswers,
    this.properties,
  });

  factory BoardObject.fromJson(Map<String, dynamic> json) {
    return BoardObject(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      pageIndex: json['page_index'] as int? ?? 0,
      className: json['class_name'] as String,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 100.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      frameMargin: (json['frame_margin'] as num?)?.toDouble(),
      frameRoundness: (json['frame_roundness'] as num?)?.toDouble(),
      correctAnswers: json['correct_answers'] != null
          ? List<String>.from(json['correct_answers'] as List)
          : null,
      properties: json['properties'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_id': pageId,
      'page_index': pageIndex,
      'class_name': className,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      if (frameMargin != null) 'frame_margin': frameMargin,
      if (frameRoundness != null) 'frame_roundness': frameRoundness,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
      if (properties != null) 'properties': properties,
    };
  }

  BoardObject copyWith({
    String? id,
    String? pageId,
    int? pageIndex,
    String? className,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? frameMargin,
    double? frameRoundness,
    List<String>? correctAnswers,
    Map<String, dynamic>? properties,
  }) {
    return BoardObject(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      pageIndex: pageIndex ?? this.pageIndex,
      className: className ?? this.className,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      frameMargin: frameMargin ?? this.frameMargin,
      frameRoundness: frameRoundness ?? this.frameRoundness,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      properties: properties ?? this.properties,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pageId,
        pageIndex,
        className,
        x,
        y,
        width,
        height,
        rotation,
        frameMargin,
        frameRoundness,
        correctAnswers,
        properties,
      ];
}
