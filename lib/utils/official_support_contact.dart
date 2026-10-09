import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const officialSupportEmail = 'headmaster@muthuthevarmhss.com';

Uri officialSupportRequestUri({
  required String subject,
  required String body,
}) => Uri(
  scheme: 'mailto',
  path: officialSupportEmail,
  queryParameters: {'subject': subject, 'body': body},
);

Future<void> openOfficialSupportRequest(
  BuildContext context, {
  required String subject,
  required String body,
}) async {
  final opened = await launchUrl(
    officialSupportRequestUri(subject: subject, body: body),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No email app is available to send this request.'),
      ),
    );
  }
}
