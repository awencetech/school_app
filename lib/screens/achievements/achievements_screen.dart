import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/cards/student_achievement_card.dart';
import '../../widgets/cards/sports_achievement_card.dart';

/// Achievements tab screen showing academic and sports highlights.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _AchievementsBody(),
        ),
      ),
    );
  }
}

class _AchievementsBody extends StatelessWidget {
  const _AchievementsBody();

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();
    final gradeXStudents = config.gradeXTopper;
    final gradeXIIStudents = config.gradeXIITopper;
    final sports = config.sportsAchievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Grade X',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (gradeXStudents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No Grade X toppers added yet.'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: gradeXStudents.length,
                itemBuilder: (context, index) {
                  final student = gradeXStudents[index];
                  return StudentAchievementCard(
                    image: student.photoBase64,
                    studentName: student.studentName,
                    marks: student.marks,
                    fit: BoxFit.cover,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Grade XII',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (gradeXIIStudents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No Grade XII toppers added yet.'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: gradeXIIStudents.length,
                itemBuilder: (context, index) {
                  final student = gradeXIIStudents[index];
                  return StudentAchievementCard(
                    image: student.photoBase64,
                    studentName: student.studentName,
                    marks: student.marks,
                    fit: BoxFit.cover,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Sports Achievements',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (sports.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No sports achievements added yet.'),
          )
        else
          ...sports.map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SportsAchievementCard(
                image: achievement.imageBase64,
                title: achievement.studentName,
                description: achievement.description,
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
