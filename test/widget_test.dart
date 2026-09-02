// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:school_app/app.dart';
import 'package:school_app/models/group.dart';
import 'package:school_app/models/staff_handbook.dart';
import 'package:school_app/screens/achievements/achievements_screen.dart';
import 'package:school_app/screens/admin/group_info_edit_page.dart';
import 'package:school_app/screens/admin/student_management_page.dart';
import 'package:school_app/screens/login/create_account_screen.dart';
import 'package:school_app/screens/login/forgot_password_screen.dart';
import 'package:school_app/screens/login/login_screen.dart';
import 'package:school_app/screens/school/school_screen.dart';
import 'package:school_app/screens/staff/staff_handbook_page.dart';
import 'package:school_app/screens/student/student_info_screen.dart';
import 'package:school_app/services/app_state.dart';
import 'package:school_app/services/school_config_service.dart';
import 'package:school_app/services/staff_handbook_service.dart';
import 'package:school_app/widgets/cards/staff_profile_card.dart';
import 'package:school_app/widgets/important_news_ticker.dart';
import 'package:school_app/widgets/navigation/app_bottom_navigation.dart';

Widget _withSchoolConfig(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => SchoolConfigService(),
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('SchoolApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const SchoolApp());
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(SchoolApp), findsOneWidget);
  });

  testWidgets('AchievementsScreen renders with school configuration', (WidgetTester tester) async {
    await tester.pumpWidget(_withSchoolConfig(const AchievementsScreen()));
    await tester.pump();

    expect(find.text('Grade X'), findsOneWidget);
    expect(find.text('Grade XII'), findsOneWidget);
    expect(find.text('Sports Achievements'), findsOneWidget);
  });

  testWidgets('LoginScreen matches the reference sign-in layout', (WidgetTester tester) async {
    await tester.pumpWidget(_withSchoolConfig(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('School name'), findsOneWidget);
    expect(find.text('Username or email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Don\'t have an account? Register'), findsOneWidget);
    expect(find.text('Contact our school to get information about registration'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen matches the reference recovery layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Recover Your Password'), findsOneWidget);
    expect(find.text('Student ID'), findsOneWidget);
    expect(find.text('Admission Number'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Don\'t have an account? Register'), findsOneWidget);
    expect(find.text('Contact your school if you face issues'), findsOneWidget);
  });

  testWidgets('CreateAccountScreen matches the reference registration layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateAccountScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Password (Again)'), findsOneWidget);
    expect(find.text('Click here to Register Now!'), findsOneWidget);
    expect(find.text('By clicking Register, you agree to our Privacy Policy and Terms of Use'), findsOneWidget);
  });

  testWidgets('SchoolScreen renders a staff profile list without blanking', (WidgetTester tester) async {
    await tester.pumpWidget(_withSchoolConfig(const SchoolScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(StaffProfileCard), findsWidgets);
  });

  testWidgets('AppBottomNavigation switches to Logout when the user is logged in', (WidgetTester tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavigation(),
            body: SizedBox(),
          ),
        ),
      ),
    );

    expect(find.text('Login'), findsOneWidget);

    await appState.setLoggedIn(true);
    await tester.pump();

    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('StudentInfoScreen matches the reference student information layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentInfoScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Student Info'), findsOneWidget);
    expect(find.text('Student name'), findsOneWidget);
    expect(find.text('Student ID'), findsOneWidget);
    expect(find.text('Mail ID :'), findsOneWidget);
    expect(find.text('Mobile No :'), findsOneWidget);
    expect(find.text('Special Needs :'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Groups and Classes of Student name'), findsOneWidget);
    expect(find.text('Your Location'), findsOneWidget);
    expect(find.text('Parent Details'), findsOneWidget);
  });

  testWidgets('StudentManagementPage exposes the Add Student button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentManagementPage()));
    await tester.pumpAndSettle();

    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Add Student'), findsOneWidget);
  });

  testWidgets('StudentManagementPage uses class/section dropdowns with a generated read-only student ID', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentManagementPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    expect(find.text('Class'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);

    final idField = find.widgetWithText(TextFormField, 'Student ID');
    expect(idField, findsOneWidget);
    final tf = tester.widget<TextFormField>(idField);
    expect(tf.enabled, isFalse);
    expect(tf.controller!.text, isNotEmpty);
    expect(tf.controller!.text.startsWith('STU'), isTrue);
  });

  testWidgets('StudentManagementPage shows saved students with edit and delete actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentManagementPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Naveen');
    await tester.enterText(find.widgetWithText(TextFormField, 'Class'), 'Grade 10');
    await tester.enterText(find.widgetWithText(TextFormField, 'Section'), 'A');
    await tester.enterText(find.widgetWithText(TextFormField, 'Student ID'), 'STU-101');
    await tester.enterText(find.widgetWithText(TextFormField, 'Parent Name'), 'Ravi');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile Number'), '9876543210');
    await tester.enterText(find.widgetWithText(TextFormField, 'Address'), 'Street 1');

    await tester.dragUntilVisible(
      find.text('Save Student'),
      find.byType(Scrollable),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save Student'));
    await tester.pumpAndSettle();

    expect(find.text('Naveen'), findsOneWidget);
    expect(find.text('Grade 10'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('GroupInfoEditPage shows the selected group and edit fields', (WidgetTester tester) async {
    final group = Group(
      id: 'SAMUNI-2022-NCC2022',
      name: 'NCC2022',
      type: 'Other',
      description: 'NCC2022',
      status: 'Active',
      year: '2022',
    );

    await tester.pumpWidget(MaterialApp(home: GroupInfoEditPage(group: group)));
    await tester.pumpAndSettle();

    expect(find.text('Group Info Edit'), findsOneWidget);
    expect(find.text('NCC2022'), findsWidgets);
    expect(find.text('SAMUNI-2022-NCC2022'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Group Details'), findsOneWidget);
  });

  testWidgets('StaffHandbookPage renders saved sections in the dashboard grid', (WidgetTester tester) async {
    final service = _TestStaffHandbookService();

    await tester.pumpWidget(
      MaterialApp(
        home: StaffHandbookPage(service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Introduction'), findsOneWidget);
    expect(find.text('School Policies'), findsOneWidget);
    expect(find.text('Staff attendance and weekly reporting process.'), findsOneWidget);
  });

  testWidgets('ImportantNewsTicker does not overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: ImportantNewsTicker(
              items: [
                'This is a very long important news string that should scroll without causing a RenderFlex overflow in the ticker layout.',
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });
}

class _TestStaffHandbookService extends StaffHandbookService {
  _TestStaffHandbookService();

  @override
  Future<StaffHandbook> getHandbook() async {
    return StaffHandbook(
      id: 'handbook-1',
      schoolId: 'default-school',
      sections: [
        HandbookSection(
          heading: 'Introduction',
          subSections: [
            HandbookSubSection(
              subHeading: 'Welcome',
              content: 'Staff attendance and weekly reporting process.',
            ),
          ],
        ),
        HandbookSection(
          heading: 'School Policies',
          subSections: [
            HandbookSubSection(
              subHeading: 'Code of conduct',
              content: 'Follow the school policies and duty schedule.',
            ),
          ],
        ),
      ],
    );
  }
}
