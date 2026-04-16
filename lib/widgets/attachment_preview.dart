import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

class AttachmentPreview extends StatelessWidget {
  final String? networkUrl;
  final Uint8List? localData;
  final String? type; // "image" or "video"
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final double size;

  const AttachmentPreview({
    super.key,
    this.networkUrl,
    this.localData,
    this.type,
    this.onRemove,
    this.onTap,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.card,
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildContent(),
          ),
          if (onRemove != null)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (localData != null) {
      if (type == 'video') {
        return const Center(
          child: Icon(Icons.videocam_rounded, size: 32, color: AppColors.textSecondary),
        );
      }
      return Image.memory(localData!, fit: BoxFit.cover);
    }

    if (networkUrl != null) {
      if (type == 'video') {
        return const Center(
          child: Icon(Icons.play_circle_outline, size: 32, color: AppColors.textSecondary),
        );
      }
      return CachedNetworkImage(
        imageUrl: networkUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.broken_image, color: AppColors.textSecondary),
      );
    }

    return const Center(
      child: Icon(Icons.image, color: AppColors.textSecondary),
    );
  }
}
