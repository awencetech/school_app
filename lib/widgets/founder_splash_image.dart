import 'dart:convert';
import 'package:flutter/material.dart';

class FounderSplashImage extends StatelessWidget {
  const FounderSplashImage({
    super.key,
    required this.imageBase64,
  });

  final String? imageBase64;

  static const double _srcW = 928.0;
  static const double _srcH = 1137.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = _srcW / _srcH;
    final imageWidth = (screenWidth * 0.45).clamp(120.0, 320.0);

    Widget child;
    if (imageBase64 != null && imageBase64!.trim().isNotEmpty) {
      final trimmed = imageBase64!.trim();
      if (trimmed.startsWith('http')) {
        child = Image.network(
          trimmed,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        );
      } else {
        try {
          child = Image.memory(
            base64Decode(trimmed),
            fit: BoxFit.contain,
            alignment: Alignment.center,
          );
        } catch (_) {
          child = const SizedBox.shrink();
        }
      }
    } else {
      child = Image.asset('assets/images/founder.png', fit: BoxFit.contain);
    }

    return SizedBox(
      width: imageWidth,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: child,
      ),
    );
  }
}
