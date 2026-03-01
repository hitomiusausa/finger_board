import 'package:equatable/equatable.dart';

class QBoxPage extends Equatable {
  final String id;
  final String qboxId;
  final int pageIndex;
  final String? backgroundType;
  final String? backgroundValue;

  const QBoxPage({
    required this.id,
    required this.qboxId,
    required this.pageIndex,
    this.backgroundType,
    this.backgroundValue,
  });

  factory QBoxPage.fromJson(Map<String, dynamic> json) {
    return QBoxPage(
      id: json['id'] as String,
      qboxId: json['qbox_id'] as String,
      pageIndex: json['page_index'] as int? ?? 0,
      backgroundType: json['background_type'] as String?,
      backgroundValue: json['background_value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qbox_id': qboxId,
      'page_index': pageIndex,
      if (backgroundType != null) 'background_type': backgroundType,
      if (backgroundValue != null) 'background_value': backgroundValue,
    };
  }

  @override
  List<Object?> get props => [
        id,
        qboxId,
        pageIndex,
        backgroundType,
        backgroundValue,
      ];
}
