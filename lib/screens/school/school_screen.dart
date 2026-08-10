import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff_member.dart';
import '../../services/dummy_data_service.dart';
import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards/staff_profile_card.dart';

/// School tab screen showing key staff profiles.
class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  List<StaffMember> _buildStaffFromConfig(SchoolConfigService config) {
    final members = <StaffMember>[];

    if (config.founderName.isNotEmpty ||
        config.founderDesignation.isNotEmpty ||
        config.founderVisionTitle.isNotEmpty ||
        config.founderVisionDescription.isNotEmpty ||
        (config.founderPhotoBase64?.isNotEmpty ?? false)) {
      members.add(
        StaffMember(
          name: config.founderName.isNotEmpty ? config.founderName : 'Founder',
          designation: config.founderDesignation,
          heading: config.founderVisionTitle,
          description: config.founderVisionDescription,
          image: config.founderPhotoBase64 ?? '',
          imageOnLeft: true,
        ),
      );
    }

    if (config.secretaryName.isNotEmpty ||
        config.secretaryDesignation.isNotEmpty ||
        config.secretaryWelcomeTitle.isNotEmpty ||
        config.secretaryWelcomeMessage.isNotEmpty ||
        (config.secretaryPhotoBase64?.isNotEmpty ?? false)) {
      members.add(
        StaffMember(
          name: config.secretaryName.isNotEmpty ? config.secretaryName : 'Secretary',
          designation: config.secretaryDesignation,
          heading: config.secretaryWelcomeTitle,
          description: config.secretaryWelcomeMessage,
          image: config.secretaryPhotoBase64 ?? '',
          imageOnLeft: false,
        ),
      );
    }

    if (config.headmasterName.isNotEmpty ||
        config.headmasterDesignation.isNotEmpty ||
        config.headmasterMessageTitle.isNotEmpty ||
        config.headmasterMessage.isNotEmpty ||
        (config.headmasterPhotoBase64?.isNotEmpty ?? false)) {
      members.add(
        StaffMember(
          name: config.headmasterName.isNotEmpty ? config.headmasterName : 'Headmaster',
          designation: config.headmasterDesignation,
          heading: config.headmasterMessageTitle,
          description: config.headmasterMessage,
          image: config.headmasterPhotoBase64 ?? '',
          imageOnLeft: true,
        ),
      );
    }

    for (var i = 0; i < config.managementMembers.length; i++) {
      final member = config.managementMembers[i];
      members.add(
        StaffMember(
          name: member.name,
          designation: member.designation,
          heading: member.title,
          description: member.description,
          image: member.photoBase64,
          imageOnLeft: i.isEven,
        ),
      );
    }

    return members;
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();

    return SafeArea(
      child: FutureBuilder<List<StaffMember>>(
        future: DummyDataService.getLeadership(),
        initialData: DummyDataService.fallbackLeadership,
        builder: (context, snapshot) {
          final defaultStaff = snapshot.data ?? DummyDataService.fallbackLeadership;
          final staff = _buildStaffFromConfig(config).isNotEmpty ? _buildStaffFromConfig(config) : defaultStaff;

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
