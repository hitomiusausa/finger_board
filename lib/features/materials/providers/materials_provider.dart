// lib/features/materials/providers/materials_provider.dart
// ─────────────────────────────────────────────────────────────
// 教材の状態管理（Riverpod）
// エラーは全て AsyncValue で管理
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/teaching_material.dart';
import '../services/materials_service.dart';

// ── Service Provider ──────────────────────────────────────────
final materialsServiceProvider = Provider<MaterialsService>(
  (ref) => MaterialsService(supabase),
);

// ── 教材一覧 ──────────────────────────────────────────────────
final materialsProvider =
    AutoDisposeAsyncNotifierProvider<MaterialsNotifier, List<TeachingMaterial>>(
  MaterialsNotifier.new,
);

class MaterialsNotifier
    extends AutoDisposeAsyncNotifier<List<TeachingMaterial>> {
  @override
  Future<List<TeachingMaterial>> build() {
    return ref.read(materialsServiceProvider).getMaterials();
  }

  /// 一覧を再取得
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(materialsServiceProvider).getMaterials(),
    );
  }
}

// ── 現在編集中の教材 ──────────────────────────────────────────
final currentMaterialProvider = StateProvider<TeachingMaterial?>((ref) => null);

// ── 教材作成アクション ────────────────────────────────────────
final createMaterialProvider =
    AutoDisposeAsyncNotifierProvider<CreateMaterialNotifier, TeachingMaterial?>(
  CreateMaterialNotifier.new,
);

class CreateMaterialNotifier
    extends AutoDisposeAsyncNotifier<TeachingMaterial?> {
  @override
  FutureOr<TeachingMaterial?> build() => null;

  Future<void> create(String title) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(materialsServiceProvider).createMaterial(title),
    );
  }
}

// ── 教材タイトル更新アクション ────────────────────────────────────
final updateMaterialTitleProvider =
    AutoDisposeAsyncNotifierProvider<UpdateMaterialTitleNotifier, void>(
  UpdateMaterialTitleNotifier.new,
);

class UpdateMaterialTitleNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateTitle(String materialId, String newTitle) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(materialsServiceProvider).updateMaterialTitle(materialId, newTitle);
      
      // 現在の教材が更新対象と同じなら、currentMaterialProviderも更新
      final currentMaterial = ref.read(currentMaterialProvider);
      if (currentMaterial?.id == materialId) {
        ref.read(currentMaterialProvider.notifier).state = currentMaterial?.copyWith(title: newTitle);
      }
      
      // 教材一覧も更新
      ref.read(materialsProvider.notifier).refresh();
    });
  }
}
