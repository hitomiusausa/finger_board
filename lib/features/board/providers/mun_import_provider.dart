// lib/features/board/providers/mun_import_provider.dart
// ─────────────────────────────────────────────────────────────
// .mun / .json ファイルインポートの状態管理
// エラーは AsyncValue.guard で管理
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/mun_import_service.dart';

final munImportProvider =
    AutoDisposeAsyncNotifierProvider<MunImportNotifier, MunImportResult?>(
  MunImportNotifier.new,
);

class MunImportNotifier extends AutoDisposeAsyncNotifier<MunImportResult?> {
  @override
  FutureOr<MunImportResult?> build() => null;

  /// Web 環境: bytes からインポート
  Future<void> importFromBytes(Uint8List bytes, String filename) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => MunImportService.importFromBytes(bytes, filename: filename),
    );
  }

  /// Native 環境: ファイルパスからインポート
  Future<void> importFromPath(String path) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => MunImportService.importFromJsonFile(path),
    );
  }
}
