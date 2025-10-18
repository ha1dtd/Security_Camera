import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageWatermark {
  /// Nhận PNG bytes, vẽ watermark [text] ở góc phải dưới, trả về PNG bytes mới.
  static Future<Uint8List> addWatermarkPng(Uint8List pngBytes, String text) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final base = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, base.width.toDouble(), base.height.toDouble()));

    // vẽ ảnh gốc
    canvas.drawImage(base, Offset.zero, Paint());

    // vẽ nền mờ + text
    const pad = 12.0;
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: (base.width / 40).clamp(12, 28).toDouble(),
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(1,1))],
    );

    final tp = _layoutText(text, textStyle);
    final bgW = tp.width + pad * 2;
    final bgH = tp.height + pad * 2;
    final dx = base.width - bgW - 16;
    final dy = base.height - bgH - 16;

    final r = RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, bgW, bgH), const Radius.circular(10));
    canvas.drawRRect(r, Paint()..color = const Color(0x80000000));
    tp.paint(canvas, Offset(dx + pad, dy + pad));

    final picture = recorder.endRecording();
    final img = await picture.toImage(base.width, base.height);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  static TextPainter _layoutText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout();
    return painter;
  }
}
