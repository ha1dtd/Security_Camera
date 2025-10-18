import 'package:flutter/foundation.dart';

@immutable
class Camera {
  final String id;
  final String name;
  final String location;
  final bool online;
  final String thumbnailUrl;

  /// Đánh dấu cam là "cam thiết bị" (local webcam / camera emulator).
  final bool isLocal;

  const Camera({
    required this.id,
    required this.name,
    required this.location,
    required this.online,
    required this.thumbnailUrl,
    this.isLocal = false, // mặc định false nếu không truyền
  });
}
