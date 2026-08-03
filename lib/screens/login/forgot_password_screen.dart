import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/textfields/custom_text_field.dart';

/// Forgot password recovery screen matching the provided design reference.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        ),
        title: const Text('SCHOOL NAME'),
        titleTextStyle: AppTextStyles.appTitle,
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
                      'Recover Your Password',
                      style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CustomTextField(
                    label: 'Student ID',
                    hintText: 'Admission Number',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Reset Password',
                    backgroundColor: AppColors.orangeButton,
                    textColor: AppColors.white,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.createAccount),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body,
                        children: const [
                          TextSpan(text: 'Don\'t have an account? '),
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(
                              color: AppColors.blueButton,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Contact your school if you face issues',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
