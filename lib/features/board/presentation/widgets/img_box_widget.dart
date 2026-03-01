import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/board_object.dart';

class ImgBoxWidget extends StatelessWidget {
  final BoardObject boardObject;

  const ImgBoxWidget({super.key, required this.boardObject});

  @override
  Widget build(BuildContext context) {
    if (boardObject.className != 'ImgBox') {
      return const SizedBox.shrink();
    }

    final properties = boardObject.properties ?? {};
    final sourceType = properties['sourceType'] as int?;

    Widget imageWidget;

    if (sourceType == 3) {
      // SVG 形式
      final svgString = properties['svgString'] as String?;
      if (svgString != null && svgString.isNotEmpty) {
        imageWidget = SvgPicture.string(
          svgString,
          fit: BoxFit.contain,
        );
      } else {
        imageWidget = const Icon(Icons.broken_image, color: Colors.grey);
      }
    } else if (sourceType == 1 || sourceType == 2) {
      // Supabase Storage から取得する画像形式
      final storagePath = properties['storagePath'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        // 注: 'images' バケットは仮の名前です。実際のバケット名に合わせて調整が必要な場合があります。
        final imageUrl = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(storagePath);
        
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.grey),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
         imageWidget = const Icon(Icons.image_not_supported, color: Colors.grey);
      }
    } else {
      // 未知の sourceType、または設定されていない場合
      imageWidget = const Icon(Icons.image_not_supported, color: Colors.grey);
    }

    return Positioned(
      left: boardObject.x,
      top: boardObject.y,
      width: boardObject.width,
      height: boardObject.height,
      child: Container(
        decoration: BoxDecoration(
           // 枠の設定などが必要な場合に備えて
           // border: ...
           borderRadius: boardObject.frameRoundness != null
                ? BorderRadius.circular(boardObject.frameRoundness!)
                : null,
        ),
        padding: boardObject.frameMargin != null
            ? EdgeInsets.all(boardObject.frameMargin!)
            : null,
        child: imageWidget,
      ),
    );
  }
}
