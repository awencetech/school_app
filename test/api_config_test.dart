import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('selects staging only when explicitly requested', () {
      expect(
        ApiConfig.resolveReleaseBaseUrl('staging'),
        'https://school-backend-staging.onrender.com',
      );
    });

    test('selects the existing production backend explicitly', () {
      expect(
        ApiConfig.resolveReleaseBaseUrl('production'),
        'https://school-app-1uep.onrender.com',
      );
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
