import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Compact student achievement card used in the 3-per-row achievements grid.
class StudentAchievementCard extends StatelessWidget {
  const StudentAchievementCard({
    super.key,
    required this.image,
    required this.studentName,
    required this.marks,
    this.fit = BoxFit.cover,
  });

  final String image;
  final String studentName;
  final String marks;
  final BoxFit fit;

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
      return Image.network(
        trimmed,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
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
        fit: fit,
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
        fit: fit,
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
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AspectRatio(
              aspectRatio: 4 / 5,
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
        const SizedBox(height: 8),
        Text(
          studentName,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF222222),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          marks,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF616161),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
