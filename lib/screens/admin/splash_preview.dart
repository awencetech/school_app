import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SplashPreview extends StatelessWidget {
  const SplashPreview({
    super.key,
    this.imageBase64,
    required this.title,
    required this.subtitle,
    required this.since,
    this.quote,
    this.imageScale = 1.0,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
  });

  final String? imageBase64;
  final String title;
  final String subtitle;
  final String since;
  final String? quote;
  final double imageScale;
  final double imageOffsetX;
  final double imageOffsetY;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 132,
            width: 132,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldBorder, width: 3),
            ),
            child: ClipOval(
              child: imageBase64 == null
                  ? const SizedBox.shrink()
                  : Transform.translate(
                      offset: Offset(imageOffsetX * 40, imageOffsetY * 40),
                      child: Transform.scale(
                        scale: imageScale,
                        child: imageBase64!.trim().startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageBase64!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                placeholder: (context, url) => const Center(child: Icon(Icons.person)),
                                errorWidget: (context, url, error) => const Center(
                                  child: Icon(Icons.person),
                                ),
                              )
                            : Image.memory(
                                base64Decode(imageBase64!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.person),
                                ),
                              ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Since $since', style: AppTextStyles.subtitle.copyWith(color: AppColors.white)),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.appTitle.copyWith(color: AppColors.white)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
          if (quote != null && quote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${quote!}"', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.95), fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close Preview'),
          ),
        ],
      ),
    );
  }
}
