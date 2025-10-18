import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LocalCameraPreview extends StatefulWidget {
  final GlobalKey repaintKey; // key để chụp snapshot (RepaintBoundary)
  const LocalCameraPreview({super.key, required this.repaintKey});

  @override
  State<LocalCameraPreview> createState() => _LocalCameraPreviewState();
}

class _LocalCameraPreviewState extends State<LocalCameraPreview> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw 'Không tìm thấy camera nào trên thiết bị/emulator';
      }
      // Ưu tiên camera sau; nếu không có thì dùng camera đầu tiên
      final camDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        camDesc,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _controller = ctrl;
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      _error = e.toString();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: RepaintBoundary(
        key: widget.repaintKey,
        child: _error != null
            ? _ErrorView(message: _error!)
            : (_controller == null || !_controller!.value.isInitialized)
                ? const _LoadingView()
                : CameraPreview(_controller!),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x11000000),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x22000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'Lỗi camera: $message',
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
