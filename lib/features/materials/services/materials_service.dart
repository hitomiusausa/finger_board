// lib/features/materials/services/materials_service.dart
// ─────────────────────────────────────────────────────────────
// 教材の CRUD サービス（Supabase）
// エラーはそのまま throw → Provider 側で AsyncValue.guard
// ─────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teaching_material.dart';
import '../../../shared/models/page_data.dart';

class MaterialsService {
  final SupabaseClient _client;

  MaterialsService(this._client);

  /// 教材を新規作成して返す
  Future<TeachingMaterial> createMaterial(String title) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('materials')
        .insert({
          'owner_id': userId,
          'title': title,
          'is_public': false,
        })
        .select()
        .single();
    return TeachingMaterial.fromJson(response);
  }

  /// 自分の教材一覧を取得
  Future<List<TeachingMaterial>> getMaterials() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('materials')
        .select()
        .eq('owner_id', userId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((e) => TeachingMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ページを upsert（id が既存なら更新、なければ挿入）
  Future<void> savePage({
    required String materialId,
    required int pageOrder,
    required PageData pageData,
  }) async {
    await _client.from('pages').upsert({
      'id': pageData.id,
      'material_id': materialId,
      'page_order': pageOrder,
      'title': pageData.pageTitle,
      'objects': pageData.toJson(),
    });
  }

  /// 教材のページ一覧を取得
  Future<List<PageData>> getPages(String materialId) async {
    final response = await _client
        .from('pages')
        .select()
        .eq('material_id', materialId)
        .order('page_order');

    return (response as List).map((e) {
      final row = e as Map<String, dynamic>;
      final objects = row['objects'] as Map<String, dynamic>? ?? {};
      
      // ページレベルのメタデータ（id, title）を復元
      final pageData = PageData.fromJson(objects);
      return pageData.copyWith(
        id: row['id'] as String? ?? pageData.id,
        pageTitle: row['title'] as String? ?? pageData.pageTitle,
      );
    }).toList();
  }

  /// 教材タイトルを更新
  Future<void> updateMaterialTitle(String materialId, String newTitle) async {
    await _client
        .from('materials')
        .update({'title': newTitle})
        .eq('id', materialId);
  }

  /// 全ページを一括保存（既存ページは削除してから保存）
  Future<void> saveAllPages({
    required String materialId,
    required List<PageData> pages,
  }) async {
    // 既存のページをすべて削除
    await _client
        .from('pages')
        .delete()
        .eq('material_id', materialId);

    // 新しいページをすべて挿入
    final insertData = pages.asMap().entries.map((entry) {
      final index = entry.key;
      final page = entry.value;
      return {
        'id': page.id,
        'material_id': materialId,
        'page_order': index,
        'title': page.pageTitle,
        'objects': page.toJson(),
      };
    }).toList();

    if (insertData.isNotEmpty) {
      await _client.from('pages').insert(insertData);
    }
  }
}
