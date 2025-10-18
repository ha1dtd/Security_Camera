// lib/utils/favorites_store.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu danh sách ảnh yêu thích bằng SharedPreferences.
/// Mỗi ảnh được nhận diện bằng đường dẫn tuyệt đối (path).
class FavoritesStore {
  static const String _kFavKey = 'favorite_paths';

  /// Lấy toàn bộ danh sách yêu thích (Set để tra nhanh, không trùng).
  static Future<Set<String>> getFavoritesSet() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kFavKey) ?? const <String>[];
    return list.toSet();
  }

  /// API mới — kiểm tra có yêu thích không.
  static Future<bool> isFavorite(String path) async {
    final set = await getFavoritesSet();
    return set.contains(path);
  }

  /// API mới — đặt trạng thái yêu thích.
  static Future<void> setFavorite(String path, bool fav) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getFavoritesSet();
    if (fav) {
      set.add(path);
    } else {
      set.remove(path);
    }
    await prefs.setStringList(_kFavKey, set.toList());
  }

  /// API mới — đảo trạng thái yêu thích, trả về trạng thái mới.
  static Future<bool> toggleFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getFavoritesSet();
    final nowFav = !set.contains(path);
    if (nowFav) {
      set.add(path);
    } else {
      set.remove(path);
    }
    await prefs.setStringList(_kFavKey, set.toList());
    return nowFav;
  }

  /// API mới — gỡ path nếu có (khi ảnh bị xoá).
  static Future<void> removeIfExists(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getFavoritesSet();
    if (set.remove(path)) {
      await prefs.setStringList(_kFavKey, set.toList());
    }
  }

  /// API mới — xoá toàn bộ danh sách yêu thích.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFavKey);
  }

  // ====== ALIASES để tương thích code cũ (image_viewer_page.dart) ======

  /// alias cho `isFavorite`
  static Future<bool> isFav(String path) => isFavorite(path);

  /// alias cho `toggleFavorite`
  static Future<bool> toggle(String path) => toggleFavorite(path);

  /// alias cho `removeIfExists`
  static Future<void> remove(String path) => removeIfExists(path);
}
