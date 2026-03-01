import 'package:equatable/equatable.dart';

class Board extends Equatable {
  final String id;
  final String? userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Board({
    required this.id,
    this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
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
      if (userId != null) 'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, title, createdAt, updatedAt];
}
