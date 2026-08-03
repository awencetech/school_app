import 'package:flutter/material.dart';

import '../../models/staff_member.dart';
import '../../services/dummy_data_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards/staff_profile_card.dart';

/// School tab screen showing key staff profiles.
class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<StaffMember>>(
        future: DummyDataService.getLeadership(),
        initialData: DummyDataService.fallbackLeadership,
        builder: (context, snapshot) {
          final staff = snapshot.data ?? DummyDataService.fallbackLeadership;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < staff.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: StaffProfileCard(
                      image: staff[i].image,
                      name: staff[i].name,
                      designation: staff[i].designation,
                      heading: staff[i].heading,
                      description: staff[i].description,
                      imageOnLeft: i.isEven,
                    ),
                  ),
                  const Divider(color: AppColors.divider, thickness: 1),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
