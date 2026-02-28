// lib/features/materials/models/teaching_material.dart
// ─────────────────────────────────────────────────────────────
// 教材データモデル（materials テーブルに対応）
// クラス名は Flutter の Material ウィジェットとの衝突を避けて
// TeachingMaterial とする
// ─────────────────────────────────────────────────────────────

class TeachingMaterial {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final bool isPublic;
  final String? forkedFrom;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeachingMaterial({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description = '',
    this.isPublic = false,
    this.forkedFrom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeachingMaterial.fromJson(Map<String, dynamic> json) =>
      TeachingMaterial(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isPublic: json['is_public'] as bool? ?? false,
        forkedFrom: json['forked_from'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'is_public': isPublic,
        'forked_from': forkedFrom,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  TeachingMaterial copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    bool? isPublic,
    String? forkedFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TeachingMaterial(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        title: title ?? this.title,
        description: description ?? this.description,
        isPublic: isPublic ?? this.isPublic,
        forkedFrom: forkedFrom ?? this.forkedFrom,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
