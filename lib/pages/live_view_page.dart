import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/camera.dart';
import '../utils/snapshot_saver.dart';

class LiveViewPage extends StatefulWidget {
  final Camera camera;
  const LiveViewPage({super.key, required this.camera});

  @override
  State<LiveViewPage> createState() => _LiveViewPageState();
}

class _LiveViewPageState extends State<LiveViewPage> {
  CameraController? _controller;
  Future<void>? _initFut;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.camera.isLocal) _bootLocalCamera();
  }

  Future<void> _bootLocalCamera() async {
    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        setState(() => _error = 'Chưa có quyền camera. Vào App settings để cấp quyền.');
        return;
      }

      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _error = 'Không tìm thấy camera trên thiết bị/emulator.');
        return;
      }

      final camDesc = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      _controller = CameraController(camDesc, ResolutionPreset.medium, enableAudio: false);
      _initFut = _controller!.initialize();
      setState(() {});
    } catch (e) {
      setState(() => _error = 'Lỗi khởi tạo camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureOnce() async {
    if (!widget.camera.isLocal) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera demo không hỗ trợ chụp thật.')),
      );
      return;
    }
    try {
      if (_controller == null || !_controller!.value.isInitialized) throw 'Camera chưa sẵn sàng';
      final shot = await _controller!.takePicture();
      final saved = await SnapshotSaver.saveXFile(shot, cameraName: widget.camera.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu: ${saved.split('/').last}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chụp: $e')),
      );
    }
  }

  Future<void> _captureBurst() async {
    if (!widget.camera.isLocal) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera demo không hỗ trợ chụp thật.')),
      );
      return;
    }
    try {
      if (_controller == null || !_controller!.value.isInitialized) throw 'Camera chưa sẵn sàng';
      for (var i = 0; i < 3; i++) {
        final shot = await _controller!.takePicture();
        await SnapshotSaver.saveXFile(shot, cameraName: widget.camera.name);
        await Future.delayed(const Duration(milliseconds: 600));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chụp loạt 3 ảnh')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi burst: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = widget.camera;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(cam.name, style: const TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Nhấn: chụp 1 ảnh • Giữ: chụp 3 ảnh',
              child: GestureDetector(
                onLongPress: _captureBurst,
                child: IconButton(
                  onPressed: _captureOnce,
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(child: cam.isLocal ? _buildLocal() : _buildDemoThumb(cam)),
    );
  }

  Widget _buildDemoThumb(Camera cam) => AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(cam.thumbnailUrl, fit: BoxFit.cover),
      );

  Widget _buildLocal() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (_controller == null || _initFut == null) {
      return const Text('Đang khởi tạo camera...', style: TextStyle(color: Colors.white));
    }
    return FutureBuilder(
      future: _initFut,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          );
        }
        if (snap.hasError) {
          return Text('Lỗi: ${snap.error}', style: const TextStyle(color: Colors.redAccent));
        }
        return const CircularProgressIndicator(color: Colors.white);
      },
    );
  }
}
