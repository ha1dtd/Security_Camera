import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class WidgetScreenshot {
  /// Chụp PNG của widget được bọc bởi RepaintBoundary(GlobalKey).
  static Future<Uint8List> captureOfKey(GlobalKey key, {double pixelRatio = 2.0}) async {
    final ctx = key.currentContext;
    if (ctx == null) {
      throw 'Preview chưa sẵn sàng (context null)';
    }
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw 'Key không trỏ tới RepaintBoundary';
    }
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw 'Không tạo được PNG';
    }
    return byteData.buffer.asUint8List();
  }
}
