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

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
          ),
          child: image.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.hintText,
                  ),
                )
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.hintText,
                      ),
                    );
                  },
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
