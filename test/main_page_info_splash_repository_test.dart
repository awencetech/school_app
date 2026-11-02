import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_app/services/main_page_info_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_user_token': 'backend-app-token',
    });
  });

  test('splash GET sends the stored bearer token', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/mainpage-info/splash');
      expect(request.headers['authorization'], 'Bearer backend-app-token');
      return http.Response(
        jsonEncode({
          'splashScreen': {'title': 'Welcome', 'sinceYear': '1987'},
        }),
        200,
      );
    });
    final repository = MainPageInfoRepository(
      baseUrl: 'https://school-app.example',
      client: client,
    );

    final result = await repository.getSplashScreen();

    expect(result.splashScreen.title, 'Welcome');
    expect(result.splashScreen.sinceYear, '1987');
  });

  test('splash PUT sends the stored bearer token and JSON payload', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/mainpage-info/splash');
      expect(request.headers['authorization'], 'Bearer backend-app-token');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {'title': 'Updated'});
      return http.Response(
        jsonEncode({
          'splashScreen': {'title': 'Updated'},
        }),
        200,
      );
    });
    final repository = MainPageInfoRepository(
      baseUrl: 'https://school-app.example',
      client: client,
    );

    final result = await repository.updateSplashScreen({'title': 'Updated'});

    expect(result.splashScreen.title, 'Updated');
  });

  test('splash GET is not sent when the stored token is missing', () async {
    SharedPreferences.setMockInitialValues({});
    var requestSent = false;
    final repository = MainPageInfoRepository(
      baseUrl: 'https://school-app.example',
      client: MockClient((request) async {
        requestSent = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(repository.getSplashScreen(), throwsStateError);

    expect(requestSent, isFalse);
  });

  test('splash PUT is not sent when the stored token is blank', () async {
    SharedPreferences.setMockInitialValues({'auth_user_token': '  '});
    var requestSent = false;
    final repository = MainPageInfoRepository(
      baseUrl: 'https://school-app.example',
      client: MockClient((request) async {
        requestSent = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      repository.updateSplashScreen({'title': 'Updated'}),
      throwsStateError,
    );

    expect(requestSent, isFalse);
  });
}
