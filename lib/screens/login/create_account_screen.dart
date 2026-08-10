import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/textfields/custom_text_field.dart';

/// Create account screen matching the provided registration reference.
class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Create Account'),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Create an Account',
                      style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CustomTextField(
                    label: 'Username',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  const CustomTextField(
                    label: 'Email',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  const CustomTextField(
                    label: 'Password',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  const CustomTextField(
                    label: 'Password (Again)',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Click here to Register Now!',
                    backgroundColor: AppColors.blueButton,
                    textColor: AppColors.white,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'By clicking Register, you agree to our Privacy Policy and Terms of Use',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'If you already have an account sign in',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Contact our school to get information about registration if you face issues',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
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
