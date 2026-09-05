import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <({String title, String body, List<String> bullets})>[
    (
      title: '1. Information We May Collect',
      body:
          'Depending on the features you use, MMHS may process information such as:',
      bullets: [
        'Name and school-related identification information.',
        'Phone number or email address when provided.',
        'Class, attendance, academic information and school notices.',
        'Information voluntarily submitted through the app.',
        'Technical information required to operate and secure the app.',
      ],
    ),
    (
      title: '2. How We Use Information',
      body: 'Information may be used to:',
      bullets: [
        'Provide school app features.',
        'Authenticate users and manage access.',
        'Display school information and communications.',
        'Maintain security.',
        'Fix technical problems and improve the app.',
        'Comply with legal requirements.',
      ],
    ),
    (
      title: '3. Sharing of Information',
      body:
          'We do not sell personal information. Information may be shared when necessary to provide school services, comply with law, protect users, or when authorized.',
      bullets: [],
    ),
    (
      title: '4. Data Security',
      body:
          'We use reasonable technical and organizational measures to protect user information against unauthorized access, alteration, disclosure, or destruction. However, no internet-based service can guarantee absolute security.',
      bullets: [],
    ),
    (
      title: '5. Data Retention',
      body:
          'Information is retained only as long as reasonably necessary for school services, operational requirements, or legal requirements. Retention periods may depend on the type of information and the school\'s requirements.',
      bullets: [],
    ),
    (
      title: '6. Children\'s Privacy',
      body:
          'MMHS is a school-related application and may be used by students. Student information is processed for legitimate educational and school purposes and in accordance with applicable laws and school requirements. We do not use children\'s information for targeted advertising.',
      bullets: [],
    ),
    (
      title: '7. Third-Party Services',
      body:
          'The app may use services such as authentication, hosting, notifications, analytics, crash reporting, maps or other technical services if those services are implemented. Their processing of information is governed by their applicable privacy policies.',
      bullets: [],
    ),
    (
      title: '8. Permissions',
      body:
          'Permissions such as notifications, camera, storage, location or other permissions are requested only when required by an implemented feature. You can manage available permissions through your device settings.',
      bullets: [],
    ),
    (
      title: '9. Your Choices and Data Requests',
      body:
          'Users can contact the school/app administrator regarding access, correction or deletion of personal information where applicable and legally permitted.',
      bullets: [],
    ),
    (
      title: '10. Changes to This Privacy Policy',
      body:
          'This policy may be updated when the app or its data practices change. The updated version will be published with a revised “Last updated” date.',
      bullets: [],
    ),
  ];

  TextStyle _bodyStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
        height: 1.55,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = _bodyStyle(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => navigateBack(context)),
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  'Privacy Policy for MMHS',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Last updated: August 24, 2026',
                  style: bodyStyle.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 28),
                SelectableText(
                  'This Privacy Policy explains how MMHS ("we", "our", or "the app") handles information when you use the MMHS school application.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 24),
                for (final section in _sections) ...[
                  SelectableText(
                    section.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(section.body, style: bodyStyle),
                  if (section.bullets.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (final bullet in section.bullets)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: SelectableText('- $bullet', style: bodyStyle),
                      ),
                  ],
                  const SizedBox(height: 22),
                ],
                SelectableText(
                  '11. Contact Us',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'If you have questions about this Privacy Policy or how information is handled, please contact:',
                  style: bodyStyle,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'MMHS App / School Administration',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                ),
                SelectableText(
                  'Email: headmaster@muthuthevarmhss.com',
                  style: bodyStyle,
                ),
                const SizedBox(height: 30),
                Center(
                  child: SelectableText(
                    '© 2026 MMHS. All rights reserved.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
