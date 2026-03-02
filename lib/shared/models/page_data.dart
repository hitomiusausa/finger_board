// lib/shared/models/page_data.dart
// ─────────────────────────────────────────────────────────────
// 1ページ分のデータモデル
// AS3 の SavedPageData に対応
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../features/board/data/models/board_object.dart';

/// ページ設定（旧 pageOptions）
class PageOptions {
  final bool studentsModWarning;   // 学習モード時に警告表示
  final bool forceStudentsMode;    // このページは常に学習モード
  final Map<String, dynamic> vars;        // ページ変数
  final Map<String, dynamic> customEvents; // カスタムイベント定義

  const PageOptions({
    this.studentsModWarning = false,
    this.forceStudentsMode = false,
    this.vars = const {},
    this.customEvents = const {},
  });

  factory PageOptions.fromJson(Map<String, dynamic> json) => PageOptions(
        studentsModWarning: json['studentsModWarning'] == true,
        forceStudentsMode: json['forceStudentsMode'] == true,
        vars: json['vars'] as Map<String, dynamic>? ?? {},
        customEvents: json['customEvents'] as Map<String, dynamic>? ?? {},
      );

  Map<String, dynamic> toJson() => {
        'studentsModWarning': studentsModWarning,
        'forceStudentsMode': forceStudentsMode,
        'vars': vars,
        'customEvents': customEvents,
      };
}

/// 1ページのデータクラス（旧 SavedPageData）
class PageData {
  final String id;
  final String? docId;          // 親ドキュメントの ID
  final String pageTitle;       // 旧: pageTitle
  final List<BoardObject> objectsData;   // ボード上のオブジェクト一覧
  final Map<String, dynamic> animationData; // ページアニメーション
  final String? masterId;       // マスターページ参照
  final PageOptions pageOptions;
  final List<String> assetsSoundIds;   // 旧: assets_sound
  final List<String> assetsImageIds;   // 旧: assets_image
  final bool checkOn;           // 解答表示状態
  final Map<String, dynamic> customMasterObjectsData;
  final Map<String, dynamic> pageStockObjects; // 旧: pageStockObjects

  const PageData({
    required this.id,
    this.docId,
    this.pageTitle = '',
    this.objectsData = const [],
    this.animationData = const {},
    this.masterId,
    this.pageOptions = const PageOptions(),
    this.assetsSoundIds = const [],
    this.assetsImageIds = const [],
    this.checkOn = false,
    this.customMasterObjectsData = const {},
    this.pageStockObjects = const {},
  });

  /// toJson() の出力や DB の JSONB から復元する汎用ファクトリ
  factory PageData.fromJson(Map<String, dynamic> json) {
    final List<BoardObject> objects = [];
    final rawObjs = json['objectsData'];
    if (rawObjs is List) {
      for (final o in rawObjs) {
        if (o is Map<String, dynamic>) {
          try {
            objects.add(BoardObject.fromJson(o));
          } catch (_) {}
        }
      }
    }

    return PageData(
      id: json['id'] as String? ??
          'page_${DateTime.now().millisecondsSinceEpoch}',
      docId: json['docId'] as String?,
      pageTitle: json['pageTitle'] as String? ?? '',
      objectsData: objects,
      animationData: json['animationData'] as Map<String, dynamic>? ?? {},
      masterId: json['masterId'] as String?,
      pageOptions: json['pageOptions'] is Map<String, dynamic>
          ? PageOptions.fromJson(json['pageOptions'] as Map<String, dynamic>)
          : const PageOptions(),
      checkOn: json['check_on'] == true,
      customMasterObjectsData:
          json['customMasterObjectsData'] as Map<String, dynamic>? ?? {},
      pageStockObjects:
          json['pageStockObjects'] as Map<String, dynamic>? ?? {},
    );
  }
  /// .mun デコーダーの出力（JSON）からPageData を生成
  factory PageData.fromMunJson(Map<String, dynamic> json) {
    final List<BoardObject> objects = [];
    final rawObjs = json['objectsData'];
    final pageId = json['id'] as String? ?? const Uuid().v4();

    if (rawObjs is List) {
      for (final o in rawObjs) {
        if (o is Map<String, dynamic>) {
          try {
            final className = o['className'] ?? o['class_name'] as String?;
            if (className == null || className == 'AssembleBox' || !['LetterBox', 'ImgBox', 'QuestionBox', 'LineOnBoard'].contains(className)) {
              debugPrint('Unknown class_name: $className');
              continue;
            }

            final w = (o['W'] ?? o['width'] as num?)?.toDouble() ?? 100.0;
            final h = (o['H'] ?? o['height'] as num?)?.toDouble() ?? 100.0;
            final x = (o['x'] as num?)?.toDouble() ?? 0.0;
            final y = (o['y'] as num?)?.toDouble() ?? 0.0;

            final properties = Map<String, dynamic>.from(o);
            // ログに邪魔な禁止項目を削除
            properties.remove('rotation');
            properties.remove('z_index');
            properties.remove('page_index');
            properties.remove('board_id');
            properties.remove('user_id');

            objects.add(BoardObject(
              id: const Uuid().v4(),
              pageId: pageId,
              className: className,
              x: x,
              y: y,
              width: w,
              height: h,
              properties: properties,
            ));
          } catch (e) {
            debugPrint('MunParse error: $e');
          }
        }
      }
    }

    return PageData(
      id: pageId,
      docId: json['docId'] as String?,
      pageTitle: json['pageTitle'] as String? ?? 'インポートページ',
      objectsData: objects,
      animationData: json['animationData'] as Map<String, dynamic>? ?? {},
      masterId: json['masterId'] as String?,
      pageOptions: json['pageOptions'] is Map<String, dynamic>
          ? PageOptions.fromJson(json['pageOptions'] as Map<String, dynamic>)
          : const PageOptions(),
      checkOn: json['check_on'] == true,
      customMasterObjectsData:
          json['customMasterObjectsData'] as Map<String, dynamic>? ?? {},
      pageStockObjects:
          json['pageStockObjects'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'docId': docId,
        'pageTitle': pageTitle,
        'objectsData': objectsData.map((o) => o.toJson()).toList(),
        'animationData': animationData,
        'masterId': masterId,
        'pageOptions': pageOptions.toJson(),
        'assetsSoundIds': assetsSoundIds,
        'assetsImageIds': assetsImageIds,
        'check_on': checkOn,
        'customMasterObjectsData': customMasterObjectsData,
        'pageStockObjects': pageStockObjects,
      };

  PageData copyWith({
    String? id,
    String? pageTitle,
    List<BoardObject>? objectsData,
    bool? checkOn,
    String? masterId,
    PageOptions? pageOptions,
  }) =>
      PageData(
        id: id ?? this.id,
        docId: docId,
        pageTitle: pageTitle ?? this.pageTitle,
        objectsData: objectsData ?? this.objectsData,
        animationData: animationData,
        masterId: masterId ?? this.masterId,
        pageOptions: pageOptions ?? this.pageOptions,
        assetsSoundIds: assetsSoundIds,
        assetsImageIds: assetsImageIds,
        checkOn: checkOn ?? this.checkOn,
        customMasterObjectsData: customMasterObjectsData,
        pageStockObjects: pageStockObjects,
      );
}
