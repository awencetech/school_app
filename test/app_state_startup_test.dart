import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_app/models/main_page_info.dart';
import 'package:school_app/models/staff_access.dart';
import 'package:school_app/models/staff_info.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/screens/splash/splash_screen.dart';
import 'package:school_app/services/app_state.dart';
import 'package:school_app/services/main_page_info_repository.dart';
import 'package:school_app/services/staff_access_service.dart';
import 'package:school_app/services/splash_config_service.dart';

class _DelayedStaffAccessService extends StaffAccessService {
  final Completer<StaffAccessRecord> result = Completer<StaffAccessRecord>();
  int requestCount = 0;

  @override
  Future<StaffAccessRecord> getMine() {
    requestCount++;
    return result.future;
  }
}

class _MemoryMainPageInfoRepository extends MainPageInfoRepository {
  @override
  Future<MainPageInfo> getMainPageInfo() async => const MainPageInfo();
}

StaffAccessRecord _staffAccess() => const StaffAccessRecord(
  staff: StaffInfo(
    name: 'Test staff',
    designation: '',
    employeeCategory: '',
    employeeId: 'staff-1',
    teaches: '',
    about: '',
    hobbiesAndInterest: '',
    role: 'staff',
    imageUrl: '',
  ),
  accessGroups: ['attendance'],
  classTeacherIds: ['class-1'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('staff session restoration does not wait for the access API', () async {
    SharedPreferences.setMockInitialValues({
      'user_logged_in': true,
      'auth_user_id': 'staff-1',
      'auth_user_role': 'staff',
      'auth_user_token': 'test-token',
    });
    final service = _DelayedStaffAccessService();
    final appState = AppState(staffAccessService: service);
    addTearDown(appState.dispose);

    await appState.initialization.timeout(const Duration(seconds: 1));

    expect(appState.isInitialized, isTrue);
    expect(appState.isLoggedIn, isTrue);
    expect(service.requestCount, 1);
    expect(appState.staffAccessError, isNull);

    service.result.complete(_staffAccess());
    await appState.staffAccessInitialization;

    expect(appState.staffClassTeacherIds, ['class-1']);
    expect(appState.staffAccessGroups, {'attendance'});
  });

  test('staff login completes before the access API responds', () async {
    SharedPreferences.setMockInitialValues({});
    final service = _DelayedStaffAccessService();
    final appState = AppState(staffAccessService: service);
    addTearDown(appState.dispose);
    await appState.initialization;

    await appState.setAuthenticatedUser(
      userId: 'staff-1',
      email: 'staff@example.test',
      role: 'staff',
      token: 'test-token',
    );

    expect(appState.isLoggedIn, isTrue);
    expect(service.requestCount, 1);

    service.result.complete(_staffAccess());
    await appState.staffAccessInitialization;
    expect(appState.staffClassTeacherIds, ['class-1']);
  });

  testWidgets('splash transitions while staff access is still pending', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_logged_in': true,
      'auth_user_id': 'staff-1',
      'auth_user_role': 'staff',
      'auth_user_token': 'test-token',
    });
    final service = _DelayedStaffAccessService();
    final appState = AppState(staffAccessService: service);
    final splashConfig = SplashConfigService(
      repository: _MemoryMainPageInfoRepository(),
    );
    addTearDown(appState.dispose);
    addTearDown(splashConfig.dispose);
    await Future.wait([appState.initialization, splashConfig.initialization]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SplashConfigService>.value(
            value: splashConfig,
          ),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.language: (_) =>
                const Scaffold(body: Text('Language selection')),
          },
          home: const SplashScreen(targetRoute: AppRoutes.language),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Language selection'), findsOneWidget);
    expect(service.requestCount, 1);

    service.result.complete(_staffAccess());
    await appState.staffAccessInitialization;
  });
}
