import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/utils/official_support_contact.dart';

void main() {
  test('support request uses the established contact without credentials', () {
    final uri = officialSupportRequestUri(
      subject: 'MMHS account deletion request',
      body: 'Please review my account deletion request.',
    );

    expect(uri.scheme, 'mailto');
    expect(uri.path, officialSupportEmail);
    expect(uri.queryParameters['subject'], 'MMHS account deletion request');
    expect(
      uri.queryParameters['body'],
      'Please review my account deletion request.',
    );
  });
}
