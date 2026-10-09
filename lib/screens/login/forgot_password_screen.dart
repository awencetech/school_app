import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/official_support_contact.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        ),
        title: const Text('MMHS'),
        titleTextStyle: AppTextStyles.appTitle,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Password assistance',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MMHS account passwords are managed by the school. '
                    'Contact the school administrator to request help resetting '
                    'your MMHS password. If you sign in with Google, use Google’s '
                    'account recovery process for your Google password.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Do not send your current password, a sign-in token, or other '
                    'secret information by email.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => openOfficialSupportRequest(
                      context,
                      subject: 'MMHS password assistance request',
                      body: 'Please contact me about resetting my MMHS account password. '
                          'I will identify my account using a school-approved identifier. '
                          'I will not include my password or sign-in tokens.',
                    ),
                    child: const Text('Contact school administrator'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
