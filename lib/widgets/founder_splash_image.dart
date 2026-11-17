import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FounderSplashImage extends StatelessWidget {
  const FounderSplashImage({
    super.key,
    this.imageBase64,
    this.allowRemoteImage = true,
  });

  final String? imageBase64;
  final bool allowRemoteImage;

  static const String localAssetPath = 'assets/images/founder.png';
  static const Color _portraitBlue = Color(0xFF0B2D70);
  static const double _borderWidth = 2.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final imageWidth =
            (availableWidth * 0.52).clamp(154.0, 230.0).toDouble();
        final imageHeight = imageWidth * 1.25;

        return SizedBox(
          width: imageWidth,
          height: imageHeight,
          child: DecoratedBox(
            decoration: const ShapeDecoration(
              color: _portraitBlue,
              shape: OvalBorder(
                side: BorderSide(
                  color: Color(0xFFD9B56A),
                  width: _borderWidth,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipOval(child: _image()),
            ),
          ),
        );
      },
    );
  }

  Widget _image() {
    final trimmed = imageBase64?.trim() ?? '';
    if (allowRemoteImage && trimmed.isNotEmpty) {
      if (trimmed.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: trimmed,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          placeholder: (context, url) => _localImage(),
          errorWidget: (context, url, error) => _localImage(),
        );
      }

      try {
        return Image.memory(
          base64Decode(trimmed),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => _localImage(),
        );
      } catch (_) {
        return _localImage();
      }
    }

    return _localImage();
  }

  Widget _localImage() {
    return Image.asset(
      localAssetPath,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: _portraitBlue),
    );
  }
}
