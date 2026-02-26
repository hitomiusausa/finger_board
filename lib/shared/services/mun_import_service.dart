// lib/shared/services/mun_import_service.dart
// ─────────────────────────────────────────────────────────────
// .mun ファイルのインポートサービス
// Python の mun_to_json.py が出力した JSON を PageData に変換する
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/page_data.dart';

/// .mun デコード済み JSON → PageData への変換結果
class MunImportResult {
  final bool success;
  final List<PageData> pages;
  final String? errorMessage;
  final String? docTitle;

  const MunImportResult({
    required this.success,
    this.pages = const [],
    this.errorMessage,
    this.docTitle,
  });

  factory MunImportResult.error(String message) =>
      MunImportResult(success: false, errorMessage: message);
}

/// .mun → JSON 変換を Python スクリプト経由で行い、PageData を生成するサービス
class MunImportService {
  /// Python スクリプトのパス（mun_to_json.py を同梱している想定）
  static const String _scriptPath =
      // アプリバンドル内または開発時の相対パス
      'mun_converter/mun_to_json.py';

  /// .mun ファイルを読み込んで PageData に変換する
  ///
  /// [munFilePath]: .mun ファイルの絶対パス
  /// [pythonPath]: Python 実行ファイルのパス（デフォルト: python3）
  static Future<MunImportResult> importFile(
    String munFilePath, {
    String pythonPath = 'python3',
  }) async {
    try {
      final file = File(munFilePath);
      if (!await file.exists()) {
        return MunImportResult.error('ファイルが見つかりません: $munFilePath');
      }

      // Python スクリプトで .mun → JSON に変換
      final tmpOut = '${munFilePath}_tmp_import.json';
      final result = await Process.run(
        pythonPath,
        [_scriptPath, munFilePath, '-o', tmpOut],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        return MunImportResult.error(
          '.mun デコード失敗: ${result.stderr}',
        );
      }

      // JSON を読み込み
      final jsonFile = File(tmpOut);
      if (!await jsonFile.exists()) {
        return MunImportResult.error('変換後 JSON が生成されませんでした');
      }

      final jsonStr = await jsonFile.readAsString();
      await jsonFile.delete(); // 一時ファイルを削除

      final Map<String, dynamic> jsonData =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      // PageData に変換
      final page = PageData.fromMunJson(jsonData);

      // ドキュメントタイトル（ファイル名から）
      final filename = File(munFilePath).uri.pathSegments.last;
      final docTitle = filename.replaceAll('.mun', '');

      return MunImportResult(
        success: true,
        pages: [page],
        docTitle: docTitle,
      );
    } catch (e) {
      return MunImportResult.error('インポートエラー: $e');
    }
  }

  /// 既にデコード済みの JSON Map から PageData を生成する（Python 不要）
  ///
  /// mun_to_json.py の出力を Flutter 側で直接読む場合に使用
  static MunImportResult importFromJson(
    Map<String, dynamic> munJson, {
    String? filename,
  }) {
    try {
      final page = PageData.fromMunJson(munJson);
      final docTitle = filename?.replaceAll('.mun', '').replaceAll('.json', '');
      return MunImportResult(
        success: true,
        pages: [page],
        docTitle: docTitle,
      );
    } catch (e) {
      return MunImportResult.error('JSON パースエラー: $e');
    }
  }

  /// デコード済みの JSON ファイル（.json）を読み込んで PageData に変換する
  static Future<MunImportResult> importFromJsonFile(
    String jsonFilePath,
  ) async {
    try {
      final file = File(jsonFilePath);
      if (!await file.exists()) {
        return MunImportResult.error('ファイルが見つかりません: $jsonFilePath');
      }

      final jsonStr = await file.readAsString();
      final Map<String, dynamic> jsonData =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      final filename = File(jsonFilePath).uri.pathSegments.last;
      return importFromJson(jsonData, filename: filename);
    } catch (e) {
      return MunImportResult.error('読み込みエラー: $e');
    }
  }

  /// バイト列（Uint8List）から JSON を読み込んで PageData を生成する（Web 対応）
  static MunImportResult importFromBytes(
    Uint8List bytes, {
    String? filename,
  }) {
    try {
      final jsonStr = utf8.decode(bytes);
      final Map<String, dynamic> jsonData =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return importFromJson(jsonData, filename: filename);
    } catch (e) {
      return MunImportResult.error('読み込みエラー: $e');
    }
  }

  /// デモ用: テスト JSON データから PageData を生成する
  static MunImportResult importDemo() {
    const demoJson = {
      'pageTitle': 'デモページ',
      'objectsData': [
        {
          'className': 'LetterBox',
          'x': 100.0,
          'y': 100.0,
          'W': 200.0,
          'H': 80.0,
          'objectCode': 1,
          'displayIndex': 1,
          'scaleX': 1.0,
          'scaleY': 1.0,
          'angle': 0.0,
          'text': 'こんにちは！',
        },
        {
          'className': 'AssembleBox',
          'x': 350.0,
          'y': 150.0,
          'W': 300.0,
          'H': 200.0,
          'objectCode': 2,
          'displayIndex': 2,
          'scaleX': 1.0,
          'scaleY': 1.0,
          'angle': 0.0,
          'blindMode': false,
          'isMagnetBox': true,
          'aryChildData': [],
        },
        {
          'className': 'QuestionBox',
          'x': 200.0,
          'y': 350.0,
          'W': 180.0,
          'H': 120.0,
          'objectCode': 3,
          'displayIndex': 3,
          'scaleX': 1.0,
          'scaleY': 1.0,
          'angle': 0.0,
          'answer': 'りんご',
        },
      ],
      'check_on': false,
      'animationData': null,
    };
    return importFromJson(demoJson, filename: 'demo.mun');
  }
}
