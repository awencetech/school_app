import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('selects staging only when explicitly requested', () {
      expect(
        ApiConfig.resolveReleaseBaseUrl('staging'),
        'https://school-app-1uep.onrender.com',
      );
    });

    test('selects the existing production backend explicitly', () {
      expect(
        ApiConfig.resolveReleaseBaseUrl('production'),
        'https://school-app-1uep.onrender.com',
      );
    });

    test('staging and production URLs are HTTPS origins without trailing slashes', () {
      expect(ApiConfig.stagingBaseUrl, 'https://school-app-1uep.onrender.com');
      expect(ApiConfig.stagingBaseUrl.endsWith('/'), isFalse);
      expect(ApiConfig.productionBaseUrl.endsWith('/'), isFalse);
    });

    test('fails closed for missing or unknown release targets', () {
      expect(() => ApiConfig.resolveReleaseBaseUrl(''), throwsStateError);
      expect(
        () => ApiConfig.resolveReleaseBaseUrl('unknown'),
        throwsStateError,
      );
    });

    test('release URL is selected only from the compile-time API_ENV', () {
      final expectedUrl = switch (ApiConfig.releaseTarget) {
        'staging' => ApiConfig.stagingBaseUrl,
        'production' => ApiConfig.productionBaseUrl,
        _ => null,
      };
      if (expectedUrl == null) {
        expect(() => ApiConfig.releaseBaseUrl, throwsStateError);
      } else {
        expect(ApiConfig.releaseBaseUrl, expectedUrl);
      }
    });
  });
}
