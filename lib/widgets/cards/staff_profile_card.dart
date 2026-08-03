import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Reusable staff profile card used on the School tab.
class StaffProfileCard extends StatelessWidget {
  const StaffProfileCard({
    super.key,
    required this.image,
    required this.name,
    required this.designation,
    required this.heading,
    required this.description,
    required this.imageOnLeft,
  });

  final String image;
  final String name;
  final String designation;
  final String heading;
  final String description;
  final bool imageOnLeft;

  @override
  Widget build(BuildContext context) {
    final paragraphs = description
        .split('\n\n')
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);

    final imageWidget = Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            color: const Color(0xFF2F66D5),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
              child: image.isEmpty
                  ? Image.asset(
                      'assets/images/founder.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppColors.divider);
                      },
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/founder.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: AppColors.divider);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );

    final content = Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 0,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF000000),
                ),
              ),
              Text(
                designation,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF000000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            heading,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < paragraphs.length; i++) ...[
            Text(
              paragraphs[i],
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.25,
                letterSpacing: 0,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.left,
            ),
            if (i != paragraphs.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageOnLeft) ...[
          imageWidget,
          const SizedBox(width: 12),
        ],
        content,
        if (!imageOnLeft) ...[
          const SizedBox(width: 12),
          imageWidget,
        ],
      ],
    );
  }
}

