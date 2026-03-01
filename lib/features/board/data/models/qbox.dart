import 'package:equatable/equatable.dart';

class QBox extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QBox({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QBox.fromJson(Map<String, dynamic> json) {
    return QBox(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt];
}
