import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/official_support_contact.dart';
import '../../widgets/help_menu_screen.dart';

/// Support tab screen with help/contact details and clickable links.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Help and Contact Support',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'School contact information is currently unavailable.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Text(
                'For feedback, support or queries',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Text(
                'For account deletion requests or password assistance, contact '
                '$officialSupportEmail. School records may be subject to '
                'separate retention requirements.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => openOfficialSupportRequest(
                      context,
                      subject: 'MMHS account deletion request',
                      body: 'I am requesting review of deletion of my MMHS app account. '
                          'I will identify the account using a school-approved identifier. '
                          'I understand that school records may be retained separately '
                          'under school requirements. I will not include passwords or '
                          'sign-in tokens.',
                    ),
                    icon: const Icon(Icons.person_remove_outlined),
                    label: const Text('Request account deletion'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => openOfficialSupportRequest(
                      context,
                      subject: 'MMHS password assistance request',
                      body: 'Please contact me about resetting my MMHS account password. '
                          'I will identify my account using a school-approved identifier. '
                          'I will not include passwords or sign-in tokens.',
                    ),
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Password assistance'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'or ',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  InkWell(
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.supportQuery),
                    child: Text(
                      'Click here to send query',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.blueButton,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: AppColors.divider, thickness: 1),
              const SizedBox(height: 20),
              Text(
                'Learn more about our data practices',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
                child: Text(
                  'Read our Privacy Policy',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.blueButton,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider, thickness: 1),
              const SizedBox(height: 20),
              const HelpContentScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
