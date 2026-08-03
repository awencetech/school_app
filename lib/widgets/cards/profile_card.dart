import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Staff profile card used in the School screen (Founder/Secretary/Principal).
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.position,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final String position;
  final String description;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl == null
                        ? Container(
                            color: AppColors.background,
                            child: const Icon(Icons.person,
                                color: AppColors.hintText),
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
                      Text(position,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}

