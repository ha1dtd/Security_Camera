import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class SnapshotSaver {
  static const _folder = 'Snapshots';

  /// Thư mục chứa ảnh trong bộ nhớ nội bộ của app:
  /// /data/user/0/<package>/files/Snapshots
  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/$_folder');
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
    // Không cần WRITE_EXTERNAL_STORAGE vì lưu nội bộ app.
  }

  /// Lưu ảnh từ XFile (camera.takePicture) -> trả về đường dẫn file .jpg
  static Future<String> saveXFile(XFile shot, {String cameraName = 'cam'}) async {
    final dir = await _dir();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final safe = cameraName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final dest = '${dir.path}/$ts\_$safe.jpg';
    await shot.saveTo(dest);
    return dest;
  }

  /// Liệt kê tất cả ảnh (jpg/png), sắp xếp mới nhất trước
  static Future<List<File>> listAll() async {
    final dir = await _dir();
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();
    files.removeWhere((f) {
      final name = f.path.toLowerCase();
      return !(name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'));
    });
    files.sort((a, b) => (b.statSync().modified).compareTo(a.statSync().modified));
    return files;
  }

  /// Xoá 1 file theo path
  static Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }

  /// Xoá tất cả ảnh (nếu muốn reset)
  static Future<void> deleteAll() async {
    final dir = await _dir();
    if (!await dir.exists()) return;
    for (final e in dir.listSync()) {
      if (e is File) e.deleteSync();
    }
  }
}
