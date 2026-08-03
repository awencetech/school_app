import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Student achievement card with photo, name and marks.
class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.name,
    required this.marks,
    this.imageUrl,
  });

  final String name;
  final String marks;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldBorder, width: 1.5),
              ),
              child: ClipOval(
                child: imageUrl == null
                    ? Container(
                        color: AppColors.background,
                        child: const Icon(Icons.person, color: AppColors.hintText),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.subtitle),
                  const SizedBox(height: 4),
                  Text('Marks: $marks', style: AppTextStyles.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

