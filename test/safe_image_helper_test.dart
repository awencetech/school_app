import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/utils/safe_image_helper.dart';

void main() {
  group('SafeImageHelper', () {
    test('isValidHttpUrl correctly verifies URLs', () {
      expect(SafeImageHelper.isValidHttpUrl(null), isFalse);
      expect(SafeImageHelper.isValidHttpUrl(''), isFalse);
      expect(SafeImageHelper.isValidHttpUrl('   '), isFalse);
      expect(SafeImageHelper.isValidHttpUrl('assets/images/school_poster.png'), isFalse);
      expect(SafeImageHelper.isValidHttpUrl('ftp://example.com/image.png'), isFalse);
      expect(SafeImageHelper.isValidHttpUrl('http://'), isFalse);
      expect(SafeImageHelper.isValidHttpUrl('https://'), isFalse);
      expect(SafeImageHelper.isValidHttpUrl('http://example.com/image.png'), isTrue);
      expect(SafeImageHelper.isValidHttpUrl('https://school-app-1uep.onrender.com/poster.jpg'), isTrue);
    });

    test('isAssetPath correctly identifies assets', () {
      expect(SafeImageHelper.isAssetPath(null), isFalse);
      expect(SafeImageHelper.isAssetPath(''), isFalse);
      expect(SafeImageHelper.isAssetPath('https://example.com/asset.png'), isFalse);
      expect(SafeImageHelper.isAssetPath('assets/images/founder.png'), isTrue);
      expect(SafeImageHelper.isAssetPath('assets/app_icon.png'), isTrue);
    });

    test('safeBase64Decode returns null on invalid or non-base64 inputs without throwing', () {
      expect(SafeImageHelper.safeBase64Decode(null), isNull);
      expect(SafeImageHelper.safeBase64Decode(''), isNull);
      expect(SafeImageHelper.safeBase64Decode('   '), isNull);
      expect(SafeImageHelper.safeBase64Decode('https://example.com/photo.png'), isNull);
      expect(SafeImageHelper.safeBase64Decode('assets/images/founder.png'), isNull);
      expect(SafeImageHelper.safeBase64Decode('not-a-valid-base64-string!@#\$%^&*()'), isNull);
      expect(SafeImageHelper.safeBase64Decode('data:text/plain;no-comma'), isNull);
    });

    test('safeBase64Decode decodes valid base64 and data URIs', () {
      // "Hello" in base64 is "SGVsbG8="
      final decoded = SafeImageHelper.safeBase64Decode('SGVsbG8=');
      expect(decoded, isNotNull);
      expect(String.fromCharCodes(decoded!), 'Hello');

      // data URI format
      final dataUriDecoded = SafeImageHelper.safeBase64Decode('data:image/png;base64,SGVsbG8=');
      expect(dataUriDecoded, isNotNull);
      expect(String.fromCharCodes(dataUriDecoded!), 'Hello');

      // Unpadded base64 ("SGVsbG8")
      final unpaddedDecoded = SafeImageHelper.safeBase64Decode('SGVsbG8');
      expect(unpaddedDecoded, isNotNull);
      expect(String.fromCharCodes(unpaddedDecoded!), 'Hello');
    });

    testWidgets('buildImage returns fallback on invalid source', (tester) async {
      const fallbackKey = Key('fallback_widget');
      await tester.pumpWidget(
        MaterialApp(
          home: SafeImageHelper.buildImage(
            source: 'invalid-source-not-url-not-base64',
            fallback: const SizedBox(key: fallbackKey),
          ),
        ),
      );

      expect(find.byKey(fallbackKey), findsOneWidget);
    });
  });
}
