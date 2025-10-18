import 'package:flutter/material.dart';

class LivePreview extends StatelessWidget {
  final String title;
  final String thumbnailUrl;
  final bool online;
  final GlobalKey repaintKey; // <— bắt buộc

  const LivePreview({
    super.key,
    required this.title,
    required this.thumbnailUrl,
    required this.online,
    required this.repaintKey, // <— bắt buộc
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // KHU VỰC CHỤP: bọc bằng RepaintBoundary với key nhận từ ngoài
          RepaintBoundary(
            key: repaintKey,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      thumbnailUrl,
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
                        child: const Icon(Icons.broken_image_outlined, size: 40, color: Colors.white70),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xAA000000), Color(0x00000000)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: online ? Colors.greenAccent : Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(blurRadius: 8)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
