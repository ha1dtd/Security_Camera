// lib/pages/gallery_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // <-- THÊM: để share nhiều ảnh
import '../utils/snapshot_saver.dart';
import '../utils/favorites_store.dart';
import 'image_viewer_page.dart';

enum SortOrder { newestFirst, oldestFirst }

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _loading = true;

  // Dữ liệu gốc
  List<File> _all = [];
  // Tập đường dẫn được yêu thích
  Set<String> _favPaths = {};
  // Chế độ chọn nhiều
  final Set<String> _selected = {};
  SortOrder _order = SortOrder.newestFirst;

  bool get _inSelection => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadAll(reloadFav: true);
  }

  Future<void> _loadAll({bool reloadFav = false}) async {
    setState(() => _loading = true);

    // 1) load file
    final files = await SnapshotSaver.listAll(); // trả List<File>
    // 2) sort local theo _order
    files.sort((a, b) {
      final am = a.lastModifiedSync().millisecondsSinceEpoch;
      final bm = b.lastModifiedSync().millisecondsSinceEpoch;
      return _order == SortOrder.newestFirst ? bm.compareTo(am) : am.compareTo(bm);
    });

    // 3) load yêu thích
    Set<String> favSet = _favPaths;
    if (reloadFav || _favPaths.isEmpty) {
      favSet = await FavoritesStore.getFavoritesSet();
    }

    setState(() {
      _all = files;
      _favPaths = favSet;
      _loading = false;
      // làm sạch các chọn đã mất
      _selected.removeWhere((p) => !_all.any((f) => f.path == p));
    });
  }

  // ----- ACTIONS (app bar) -----
  Future<void> _onRefresh() => _loadAll(reloadFav: true);

  void _startSelectionMode() {
    if (!_inSelection) setState(() {});
  }

  void _toggleSelect(String path) {
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        _selected.add(path);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  void _selectAllInCurrentTab() {
    final list = _currentList();
    setState(() {
      _selected.addAll(list.map((e) => e.path));
    });
  }

  List<File> _currentList() {
    if (_tab.index == 1) {
      // Yêu thích
      return _all.where((f) => _favPaths.contains(f.path)).toList();
    }
    return _all;
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ảnh đã chọn?'),
        content: Text('Bạn chắc chắn xoá ${_selected.length} ảnh?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true) return;

    for (final p in _selected) {
      await SnapshotSaver.deleteFile(p);
      _favPaths.remove(p);
    }
    _selected.clear();
    await _loadAll(reloadFav: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá các ảnh đã chọn')),
      );
    }
  }

  Future<void> _toggleFavoriteSelected() async {
    if (_selected.isEmpty) return;
    for (final p in _selected) {
      await FavoritesStore.toggleFavorite(p);
    }
    _selected.clear();
    await _loadAll(reloadFav: true);
  }

  // <-- THÊM: Share đồng loạt các ảnh đang chọn
  Future<void> _shareSelected() async {
    if (_selected.isEmpty) return;
    final files = _selected.map((p) => XFile(p)).toList();
    await Share.shareXFiles(files, text: 'Ảnh đã chọn');
    // giữ nguyên trạng thái chọn sau khi share (nếu muốn tự bỏ chọn thì mở comment dưới)
    // _clearSelection();
  }

  void _changeSort(SortOrder order) {
    if (_order == order) return;
    setState(() => _order = order);
    // chỉ cần sắp xếp lại local, không phải gọi I/O
    _all.sort((a, b) {
      final am = a.lastModifiedSync().millisecondsSinceEpoch;
      final bm = b.lastModifiedSync().millisecondsSinceEpoch;
      return _order == SortOrder.newestFirst ? bm.compareTo(am) : am.compareTo(bm);
    });
  }

  // ----- BUILD -----
  @override
  Widget build(BuildContext context) {
    final title = _inSelection ? '${_selected.length} đã chọn' : 'Playback';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: _buildActions(),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Yêu thích'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _onRefresh,
                child: TabBarView(
                  children: [
                    _buildGrid(_all),
                    _buildGrid(_all.where((f) => _favPaths.contains(f.path)).toList()),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_inSelection) {
      return [
        // THÊM: nút Share khi đang chọn nhiều
        IconButton(
          tooltip: 'Chia sẻ ảnh đã chọn',
          onPressed: _shareSelected,
          icon: const Icon(Icons.ios_share),
        ),
        IconButton(
          tooltip: 'Đánh dấu yêu thích / bỏ yêu thích',
          onPressed: _toggleFavoriteSelected,
          icon: const Icon(Icons.star),
        ),
        IconButton(
          tooltip: 'Xoá đã chọn',
          onPressed: _deleteSelected,
          icon: const Icon(Icons.delete_outline),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'all') _selectAllInCurrentTab();
            if (v == 'clear') _clearSelection();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'all', child: Text('Chọn tất cả')),
            PopupMenuItem(value: 'clear', child: Text('Bỏ chọn')),
          ],
        ),
      ];
    }
    // Không ở chế độ chọn: có làm mới + sắp xếp + nút vào chọn nhiều
    return [
      IconButton(
        tooltip: 'Làm mới',
        onPressed: _onRefresh,
        icon: const Icon(Icons.refresh),
      ),
      PopupMenuButton<SortOrder>(
        tooltip: 'Sắp xếp',
        initialValue: _order,
        onSelected: _changeSort,
        itemBuilder: (_) => [
          CheckedPopupMenuItem(
            value: SortOrder.newestFirst,
            checked: _order == SortOrder.newestFirst,
            child: const Text('Mới nhất → Cũ nhất'),
          ),
          CheckedPopupMenuItem(
            value: SortOrder.oldestFirst,
            checked: _order == SortOrder.oldestFirst,
            child: const Text('Cũ nhất → Mới nhất'),
          ),
        ],
        icon: const Icon(Icons.sort),
      ),
      IconButton(
        tooltip: 'Chọn nhiều',
        onPressed: _startSelectionMode,
        icon: const Icon(Icons.checklist),
      ),
    ];
  }

  Widget _buildGrid(List<File> files) {
    if (files.isEmpty) {
      return const Center(child: Text('Chưa có ảnh', style: TextStyle(color: Colors.white70)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final f = files[i];
        final path = f.path;
        final isFav = _favPaths.contains(path);
        final isSel = _selected.contains(path);

        return GestureDetector(
          onLongPress: () => _toggleSelect(path),
          onTap: () async {
            if (_inSelection) {
              _toggleSelect(path);
              return;
            }
            // Mở viewer; nếu có thay đổi (xoá/đổi yêu thích) -> reload
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => ImageViewerPage(file: f)),
            );
            if (changed == true) {
              // Đồng bộ lại (yêu cầu nhất quán)
              await _loadAll(reloadFav: true);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh
              Image.file(f, fit: BoxFit.cover),
              // ⭐ chỉ hiện nếu là ảnh yêu thích
              if (isFav)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.star, color: Colors.amber, size: 18),
                ),
              // Khung chọn nhiều
              if (isSel)
                Container(
                  color: Colors.black26,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.check_circle, color: Colors.lightBlueAccent),
                ),
            ],
          ),
        );
      },
    );
  }
}
