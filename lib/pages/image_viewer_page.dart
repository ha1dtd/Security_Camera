import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/snapshot_saver.dart';
import '../utils/favorites_store.dart';

class ImageViewerPage extends StatefulWidget {
  final File file;
  const ImageViewerPage({super.key, required this.file});

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  bool _fav = false;

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    final f = await FavoritesStore.isFav(widget.file.path);
    if (mounted) setState(() => _fav = f);
  }

  Future<void> _toggleFav() async {
    await FavoritesStore.toggle(widget.file.path);
    if (mounted) setState(() => _fav = !_fav);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_fav ? 'Đã thêm vào yêu thích' : 'Đã bỏ yêu thích')),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ảnh?'),
        content: const Text('Bạn có chắc chắn muốn xoá ảnh này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok == true) {
      await FavoritesStore.remove(widget.file.path);
      await SnapshotSaver.deleteFile(widget.file.path);
      if (!mounted) return;
      Navigator.pop(context, true); // trả về true để Gallery refresh
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles([XFile(widget.file.path)], text: 'Snapshot');
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.file.uri.pathSegments.isNotEmpty
        ? widget.file.uri.pathSegments.last
        : 'Ảnh';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: _fav ? 'Bỏ yêu thích' : 'Yêu thích',
            icon: Icon(_fav ? Icons.star : Icons.star_border, color: Colors.amber),
            onPressed: _toggleFav,
          ),
          IconButton(
            tooltip: 'Chia sẻ',
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _share,
          ),
          IconButton(
            tooltip: 'Xoá ảnh',
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _delete,
          ),
        ],
      ),
      body: Hero(
        tag: widget.file.path,
        child: PhotoView(
          imageProvider: FileImage(widget.file),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}
