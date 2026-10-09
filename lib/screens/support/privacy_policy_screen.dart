import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <({String title, String body, List<String> bullets})>[
    (
      title: '1. Scope of this policy',
      body:
          'This Privacy Policy describes the personal and school-related information processed by the MMHS mobile application and associated MMHS backend services when the app is used for school administration, communication, and student support.',
      bullets: [],
    ),
    (
      title: '2. Information the app may process',
      body:
          'Depending on the features used by the user and school, the app may process account identifiers and contact information, school-related records, and technical service data such as:',
      bullets: [
        'User account details such as email address, user ID, school role, and authentication data used to sign in and authorize access.',
        'Student and parent or guardian profile details may include names, student or admission identifiers, class and section, parent or guardian name, mobile number, and address.',
        'Teacher and staff identification, contact, and work information maintained for school administration.',
        'Attendance, academic records, class information, notices, messages, and staff or student activity within the app.',
        'Uploaded files, images, attachments, or reports when a feature allows document or media upload.',
        'Medical event records or related school support information when those features are used and the school enables them.',
        'Bus GPS or route-related location data when the bus tracking feature is active.',
        'Device and app technical data necessary to operate, secure, and troubleshoot the service.',
      ],
    ),
    (
      title: '3. Authentication and access',
      body:
          'The app uses Firebase Authentication and Google Sign-In for Google sign-in. MMHS username and password credentials are authenticated by the MMHS backend. The app does not provide an automated password-reset service; contact the school administrator for password assistance. The backend validates user identity and authorization before allowing school-specific access. Email, identifiers, passwords, and authentication tokens are processed by the relevant sign-in service and backend for authentication and account access management.',
      bullets: [],
    ),
    (
      title: '4. How information is used',
      body: 'The app may use this information to:',
      bullets: [
        'Provide school login, role-based access, and user account management.',
        'Display class, attendance, academic, and school communication data to the relevant user.',
        'Send notices, messages, or support communications.',
        'Support school workflows such as attendance, medical-event tracking, homework uploads, and bus tracking when enabled.',
        'Maintain service security, troubleshoot errors, and operate the application reliably.',
        'Comply with applicable school or legal requirements.',
      ],
    ),
    (
      title: '5. Files, images, and attachments',
      body:
          'Some features allow users to upload files or images. When enabled, the uploaded file, file name, and related metadata may be transmitted to the MMHS backend for storage and access by the relevant school users. Access is limited by the app\'s role-based functionality and the school\'s operational rules.',
      bullets: [],
    ),
    (
      title: '6. School communications and student data',
      body:
          'MMHS may process student, parent, teacher, and school operational data to support class communication, attendance, notices, resource sharing, and related school workflows. This information is used for legitimate educational and operational purposes within the app and associated school systems.',
      bullets: [],
    ),
    (
      title: '7. Medical and location-related data',
      body:
          'Medical-event records may include a student identifier, name, class, reported symptoms, known special needs, event description, reporter details, and an image. The app also processes bus route and GPS-device status information. The inspected Android release does not request device-location permissions, and the app source does not collect device or background location. The bus records inspected contain route and device-status details, not a live stream of device GPS coordinates. The class-demography map displays configured points using OpenStreetMap tiles.',
      bullets: [],
    ),
    (
      title: '8. Sharing and service providers',
      body:
          'School information submitted in the app is processed by the MMHS backend, hosted on Render, and stored in its configured MongoDB database. Uploaded files may be stored in MongoDB GridFS or backend upload storage, depending on the upload route. Firebase Authentication and Google Sign-In are used for sign-in. Firebase Analytics is included in the Android release; if analytics collection is enabled, Google may automatically process app-usage and device identifiers according to Firebase and project settings. The Android release manifest includes advertising-ID and attribution permissions from bundled Google/Firebase libraries, so their collection settings should be reviewed before release. The class-demography map requests map tiles from OpenStreetMap, which receives tile requests, requested map areas, and the requesting network address. No in-app ad-serving code was found.',
      bullets: [],
    ),
    (
      title: '9. Data security and retention',
      body:
          'The app and backend use reasonable technical and organizational safeguards to protect information against unauthorized access, loss, or misuse. However, no internet-based service can guarantee absolute security. Retention period requires an explicit product/legal decision; data is retained only as long as needed for school operations, system functioning, or applicable legal requirements.',
      bullets: [],
    ),
    (
      title: '10. Children\'s and student privacy',
      body:
          'MMHS is a school-related application and may process student information for educational, administrative, and safety purposes. Information is handled in line with the app\'s school-use workflows and applicable requirements. The app does not use student data for advertising or targeted marketing.',
      bullets: [],
    ),
    (
      title: '11. Permissions and choices',
      body:
          'The inspected Android release declares internet and network access, wake-lock, advertising-ID and attribution, Google services and install-referrer, and biometric/fingerprint permissions; several are contributed by bundled Google/Firebase or AndroidX libraries. A manifest declaration alone does not mean the app uses that feature. The release does not declare location, camera, microphone, contacts, phone, SMS, media/storage, or notification permissions, and the app source does not request device location. Users may contact the school administrator to ask about school-related personal information associated with app use where applicable and legally permitted.',
      bullets: [],
    ),
    (
      title: '12. Account deletion and data requests',
      body:
          'To request review of deletion of an MMHS app login account, contact the school administration at headmaster@muthuthevarmhss.com. The current app does not provide self-service account deletion. An administrator can remove an MMHS login credential, but that action does not delete a Firebase identity, student or staff profile, school records, uploaded files, medical records, messages, or other related records. The school must review the scope of a request and any applicable record-retention requirements; no automatic deletion of those records is promised. Do not send passwords or sign-in tokens in a request.',
      bullets: [],
    ),
    (
      title: '13. Changes to this policy',
      body:
          'This policy may be updated when the app, its data practices, or the implemented features change. The updated version will be published with a revised “Last updated” date.',
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
                  'Last updated: October 8, 2026',
                  style: bodyStyle.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 28),
                SelectableText(
                  'This Privacy Policy explains how MMHS ("we", "our", or "the app") handles information when you use the MMHS school application and associated school systems.',
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
                  '14. Contact Us',
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
