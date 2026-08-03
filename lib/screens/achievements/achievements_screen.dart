import 'package:flutter/material.dart';

import '../../models/student_achievement.dart';
import '../../services/dummy_data_service.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        FutureBuilder<List<StudentAchievement>>(
          future: DummyDataService.getGradeX(),
          initialData: DummyDataService.fallbackGradeX,
          builder: (context, snapshot) {
            final students = snapshot.data ?? DummyDataService.fallbackGradeX;
            return Column(
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return StudentAchievementCard(
                      image: student.imageUrl ?? '',
                      studentName: student.name,
                      marks: student.marks,
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<StudentAchievement>>(
          future: DummyDataService.getGradeXII(),
          initialData: DummyDataService.fallbackGradeXII,
          builder: (context, snapshot) {
            final students = snapshot.data ?? DummyDataService.fallbackGradeXII;
            return Column(
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return StudentAchievementCard(
                      image: student.imageUrl ?? '',
                      studentName: student.name,
                      marks: student.marks,
                    );
                  },
                ),
              ],
            );
          },
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
        const SportsAchievementCard(
          image: '',
          title: 'Student Name',
          description: 'Achievements Description',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
