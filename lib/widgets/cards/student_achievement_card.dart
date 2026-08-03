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
  });

  final String image;
  final String studentName;
  final String marks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(
                    color: const Color(0xFFCFCFCF),
                    width: 1,
                  ),
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
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Text(
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
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Text(
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
            ),
          ],
        );
      },
    );
  }
}
