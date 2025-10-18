import 'package:flutter/material.dart';

class FullscreenViewPage extends StatelessWidget {
  final String title;
  final String? thumbnailUrl;


  final GlobalKey? repaintSourceKey;

  const FullscreenViewPage({
    super.key,
    required this.title,
    this.thumbnailUrl,
    this.repaintSourceKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context), // chạm để thoát
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnailUrl != null
                ? Image.network(thumbnailUrl!, fit: BoxFit.contain)
                : const Center(child: Icon(Icons.videocam, color: Colors.white54, size: 100)),
            Positioned(
              left: 16,
              top: 40 + MediaQuery.of(context).padding.top,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

