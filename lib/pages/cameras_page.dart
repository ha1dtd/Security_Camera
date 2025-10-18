// lib/pages/cameras_page.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/camera.dart';
import '../utils/app_route_observer.dart';
import 'live_view_page.dart';

class CamerasPage extends StatelessWidget {
  const CamerasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cams = context.watch<AppState>().cameras;

    return Scaffold(
      appBar: AppBar(title: const Text('Cameras')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: cams.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 16 / 10,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, i) {
            final c = cams[i];

            // Ô đầu tiên LIVE, các ô còn lại thumbnail — GIỮ NGUYÊN
            if (i == 0 && c.isLocal) {
              return _LiveCameraTile(camera: c);
            }
            return _CameraThumbTile(camera: c);
          },
        ),
      ),
    );
  }
}

/// Ô THUMB (giữ nguyên)
class _CameraThumbTile extends StatelessWidget {
  const _CameraThumbTile({required this.camera});
  final Camera camera;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LiveViewPage(camera: camera)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                camera.thumbnailUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0x11000000),
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? (progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!)
                          : null,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0x22000000),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color:
                          camera.online ? Colors.greenAccent : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      camera.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                camera.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô LIVE: pause/resume theo route & lifecycle, KHÔNG thay đổi feature; chỉ vá an toàn
class _LiveCameraTile extends StatefulWidget {
  const _LiveCameraTile({required this.camera});
  final Camera camera;

  @override
  State<_LiveCameraTile> createState() => _LiveCameraTileState();
}

class _LiveCameraTileState extends State<_LiveCameraTile>
    with WidgetsBindingObserver, RouteAware, AutomaticKeepAliveClientMixin {
  CameraController? _controller;
  Future<void>? _init;
  String? _error;

  bool _wantActive = true;
  bool _starting = false;
  bool _subscribed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addPostFrameCallback((_) => _ensureStarted());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_subscribed && route != null) {
      appRouteObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    if (_subscribed) {
      appRouteObserver.unsubscribe(this);
      _subscribed = false;
    }
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  // RouteAware
  @override
  void didPushNext() {
    _wantActive = false;
    _stop();
  }

  @override
  void didPopNext() {
    _wantActive = true;
    // Tránh race: đợi một frame rồi hãy start lại
    SchedulerBinding.instance.addPostFrameCallback((_) => _ensureStarted());
  }

  // Lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _wantActive = true;
      SchedulerBinding.instance.addPostFrameCallback((_) => _ensureStarted());
    } else if (state == AppLifecycleState.paused) {
      _wantActive = false;
      _stop();
    }
  }

  Future<void> _ensureStarted() async {
    if (!_wantActive || _starting || !mounted) return;
    if (_controller?.value.isInitialized == true) return;

    _starting = true;
    try {
      setState(() => _error = null);

      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        setState(() => _error = 'Chưa được cấp quyền camera.');
        return;
      }

      final cams = await availableCameras();
      if (!mounted) return;
      if (cams.isEmpty) {
        setState(() => _error = 'Không tìm thấy camera trên thiết bị');
        return;
      }

      final desc = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      final ctrl =
          CameraController(desc, ResolutionPreset.medium, enableAudio: false);
      _controller = ctrl;
      _init = ctrl.initialize();
      if (mounted) setState(() {});

      await _init;
      if (!mounted) return;

      if (_controller != ctrl) {
        await ctrl.dispose();
      } else {
        setState(() {}); // sẵn sàng
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể khởi tạo camera: $e');
    } finally {
      _starting = false;
    }
  }

  Future<void> _stop() async {
    final c = _controller;
    _controller = null;
    _init = null;
    try {
      await c?.dispose();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _openFull() async {
    await _stop(); // nhường tài nguyên
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveViewPage(camera: widget.camera)),
    );
    if (!mounted) return;
    _wantActive = true;
    // Đợi layout ổn định rồi khởi động lại để tránh race
    SchedulerBinding.instance.addPostFrameCallback((_) => _ensureStarted());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InkWell(
      onTap: _openFull,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Positioned.fill(child: _buildPreviewBody()),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.camera.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                widget.camera.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBody() {
    if (_error != null) {
      return Container(
        color: const Color(0x22000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
    if (_init == null || _controller == null) {
      return const _LoadingShimmer();
    }

    return FutureBuilder(
      future: _init,
      builder: (context, snap) {
        final ready =
            (snap.connectionState == ConnectionState.done) &&
            (_controller?.value.isInitialized == true);

        if (ready) {
          // Dùng aspectRatio thay vì previewSize để loại lỗi null
          final ratio = _controller!.value.aspectRatio;
          final safeRatio = (ratio.isFinite && ratio > 0) ? ratio : (16 / 9);

          return LayoutBuilder(
            builder: (ctx, box) {
              // Phủ kín tile theo BoxFit.cover nhưng KHÔNG đụng tới previewSize
              final w = box.maxWidth;
              final h = box.maxHeight;
              final targetH = w / safeRatio;

              return ClipRect(
                child: OverflowBox(
                  maxWidth: w,
                  maxHeight: h,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: w,
                      height: targetH,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              );
            },
          );
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        return const _LoadingShimmer();
      },
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x22000000),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

