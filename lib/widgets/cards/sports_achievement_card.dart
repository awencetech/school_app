import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Compact sports achievement row used on the exploit screen.
class SportsAchievementCard extends StatelessWidget {
  const SportsAchievementCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  final String image;
  final String title;
  final String description;

  Widget _buildImage(String image) {
    final trimmed = image.trim();
    if (trimmed.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.hintText,
        ),
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppColors.divider),
        errorWidget: (context, url, error) {
          return const Center(
            child: Icon(
              Icons.image_outlined,
              color: AppColors.hintText,
            ),
          );
        },
      );
    }

    UriData? uriData;
    try {
      uriData = UriData.parse(trimmed);
    } catch (_) {
      uriData = null;
    }
    if (uriData != null && uriData.contentAsBytes().isNotEmpty) {
      return Image.memory(
        uriData.contentAsBytes(),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final normalized = trimmed.toLowerCase().startsWith('data:')
        ? trimmed.substring(trimmed.indexOf(',') + 1).replaceAll(RegExp(r'\s+'), '')
        : trimmed.replaceAll(RegExp(r'\s+'), '');

    try {
      final bytes = base64Decode(normalized);
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.hintText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                color: AppColors.white,
                child: image.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.hintText,
                        ),
                      )
                    : _buildImage(image),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF616161),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
