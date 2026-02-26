// lib/features/board/models/board_object.dart
// ─────────────────────────────────────────────────────────────
// ボード上オブジェクトのデータモデル
// AS3 の ObjOnBoard / BoxOnBoard / loadObj クラス群に対応
// ─────────────────────────────────────────────────────────────

/// リモートスイッチ設定（旧 remoteSwitchSettings）
class RemoteSwitchSettings {
  final int remoteSwitchType;   // 0=無効, 1=シングル, 2=スキャン
  final String? remoteSwitchId;
  final Map<String, dynamic> animation;

  const RemoteSwitchSettings({
    this.remoteSwitchType = 0,
    this.remoteSwitchId,
    this.animation = const {},
  });

  factory RemoteSwitchSettings.fromJson(Map<String, dynamic> json) =>
      RemoteSwitchSettings(
        remoteSwitchType: (json['remoteSwitchType'] as num?)?.toInt() ?? 0,
        remoteSwitchId: json['remoteSwitchID'] as String?,
        animation: (json['animation'] as Map<String, dynamic>?) ?? {},
      );

  Map<String, dynamic> toJson() => {
        'remoteSwitchType': remoteSwitchType,
        'remoteSwitchID': remoteSwitchId,
        'animation': animation,
      };
}

/// ボード上オブジェクトの基底データクラス
/// JSON スキーマは mun_output/schema.json の object_fields から生成
class BoardObject {
  final String id;
  final String className;      // AS3 LoadObj の switch に対応するクラス名

  // ── 配置 ──────────────────────────────────────────────
  final double x;
  final double y;
  final double width;          // 旧: W
  final double height;         // 旧: H
  final double scaleX;
  final double scaleY;
  final double angle;          // rotation（旧: angle）

  // ── 表示 ──────────────────────────────────────────────
  final bool blindMode;        // 学習モードで非表示にするか
  final bool hidden;           // 常に非表示
  final bool disable;          // 操作不可
  final int displayIndex;      // 重なり順（z-order）
  final int objectCode;        // オブジェクト種別番号

  // ── インタラクション ────────────────────────────────
  final String? answer;        // 正解文字列
  final List<dynamic> answerArr; // 正解選択肢リスト
  final bool flgPushMode;      // タッチで押すモード
  final bool studentsModeDragEnabled; // 学習モードでドラッグ可能か

  // ── サウンド ────────────────────────────────────────
  final String? soundId;
  final String? audioFileExtension;

  // ── リモートスイッチ ────────────────────────────────
  final RemoteSwitchSettings remoteSwitchSettings;

  // ── アニメーション ──────────────────────────────────
  final Map<String, dynamic> animationData;

  // ── 子オブジェクト（BoxOnBoard.Ary 相当）──────────
  final List<BoardObject> children; // 旧: aryChildData

  // ── クラス固有フィールド（拡張で上書き）──────────
  final Map<String, dynamic> extra; // クラス固有の追加フィールド

  const BoardObject({
    required this.id,
    required this.className,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 100,
    this.scaleX = 1,
    this.scaleY = 1,
    this.angle = 0,
    this.blindMode = false,
    this.hidden = false,
    this.disable = false,
    this.displayIndex = 0,
    this.objectCode = 0,
    this.answer,
    this.answerArr = const [],
    this.flgPushMode = false,
    this.studentsModeDragEnabled = false,
    this.soundId,
    this.audioFileExtension,
    this.remoteSwitchSettings = const RemoteSwitchSettings(),
    this.animationData = const {},
    this.children = const [],
    this.extra = const {},
  });

  factory BoardObject.fromJson(Map<String, dynamic> json) {
    final List<BoardObject> kids = [];
    final childData = json['aryChildData'];
    if (childData is List) {
      for (final c in childData) {
        if (c is Map<String, dynamic>) kids.add(BoardObject.fromJson(c));
      }
    }

    final rsRaw = json['remoteSwitchSettings'];
    final rs = rsRaw is Map<String, dynamic>
        ? RemoteSwitchSettings.fromJson(rsRaw)
        : const RemoteSwitchSettings();

    return BoardObject(
      id: json['objectCode']?.toString() ?? UniqueKey().toString(),
      className: json['className'] as String? ?? 'Unknown',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['W'] as num?)?.toDouble() ?? 100,
      height: (json['H'] as num?)?.toDouble() ?? 100,
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1,
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      blindMode: json['blindMode'] == true,
      hidden: json['hidden'] == true,
      disable: json['disable'] == true,
      displayIndex: (json['displayIndex'] as num?)?.toInt() ?? 0,
      objectCode: (json['objectCode'] as num?)?.toInt() ?? 0,
      answer: json['answer'] as String?,
      answerArr: json['answerArr'] as List? ?? [],
      flgPushMode: json['flgPushMode'] == true,
      studentsModeDragEnabled: json['studentsModeDragEnabled'] == true,
      soundId: json['soundID'] as String?,
      audioFileExtension: json['audioFieExtension'] as String?,
      remoteSwitchSettings: rs,
      animationData: json['animationData'] as Map<String, dynamic>? ?? {},
      children: kids,
      extra: Map<String, dynamic>.from(json)
        ..remove('aryChildData')
        ..remove('remoteSwitchSettings'),
    );
  }

  Map<String, dynamic> toJson() => {
        'className': className,
        'x': x, 'y': y, 'W': width, 'H': height,
        'scaleX': scaleX, 'scaleY': scaleY, 'angle': angle,
        'blindMode': blindMode, 'hidden': hidden, 'disable': disable,
        'displayIndex': displayIndex, 'objectCode': objectCode,
        'answer': answer, 'answerArr': answerArr,
        'flgPushMode': flgPushMode,
        'studentsModeDragEnabled': studentsModeDragEnabled,
        'soundID': soundId, 'audioFieExtension': audioFileExtension,
        'remoteSwitchSettings': remoteSwitchSettings.toJson(),
        'animationData': animationData,
        'aryChildData': children.map((c) => c.toJson()).toList(),
        ...extra,
      };

  BoardObject copyWith({
    String? id, String? className,
    double? x, double? y, double? width, double? height,
    double? scaleX, double? scaleY, double? angle,
    bool? blindMode, bool? hidden, bool? disable,
    int? displayIndex, int? objectCode,
    List<BoardObject>? children,
  }) =>
      BoardObject(
        id: id ?? this.id,
        className: className ?? this.className,
        x: x ?? this.x, y: y ?? this.y,
        width: width ?? this.width, height: height ?? this.height,
        scaleX: scaleX ?? this.scaleX, scaleY: scaleY ?? this.scaleY,
        angle: angle ?? this.angle,
        blindMode: blindMode ?? this.blindMode,
        hidden: hidden ?? this.hidden, disable: disable ?? this.disable,
        displayIndex: displayIndex ?? this.displayIndex,
        objectCode: objectCode ?? this.objectCode,
        answer: answer, answerArr: answerArr,
        flgPushMode: flgPushMode,
        studentsModeDragEnabled: studentsModeDragEnabled,
        soundId: soundId, audioFileExtension: audioFileExtension,
        remoteSwitchSettings: remoteSwitchSettings,
        animationData: animationData,
        children: children ?? this.children,
        extra: extra,
      );
}

// ─── UniqueKey ダミー（Dart の flutter 依存を避けるため） ─────
class UniqueKey {
  static int _counter = 0;
  @override
  String toString() => 'obj_${_counter++}';
}
