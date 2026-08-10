import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Support tab screen with help/contact details and clickable links.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _email(String email) async {
    await launchUrl(Uri.parse('mailto:$email'));
  }

  @override
  Widget build(BuildContext context) {
    const phone = '+ 7568524982';
    const email = 'School@gmail.com';
    const supportEmail = 'Company@gmail.com';

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
                'Contact School at $phone or',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.square,
                      size: 8,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _email(email),
                    child: Text(
                      email,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.blueButton,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'For feedback, support or queries',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Text(
                'You can also contact support team at',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.square,
                      size: 8,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _email(supportEmail),
                    child: Text(
                      supportEmail,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.blueButton,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'or ',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.supportQuery,
                    ),
                    child: Text(
                      'Click here to send query',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.blueButton,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

