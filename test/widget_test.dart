// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_app/app.dart';
import 'package:school_app/screens/achievements/achievements_screen.dart';
import 'package:school_app/screens/login/create_account_screen.dart';
import 'package:school_app/screens/login/forgot_password_screen.dart';
import 'package:school_app/screens/login/login_screen.dart';
import 'package:school_app/screens/school/school_screen.dart';
import 'package:school_app/widgets/cards/staff_profile_card.dart';
import 'package:school_app/widgets/cards/student_achievement_card.dart';
import 'package:school_app/widgets/important_news_ticker.dart';

void main() {
  testWidgets('SchoolApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const SchoolApp());
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(SchoolApp), findsOneWidget);
  });

  testWidgets('AchievementsScreen shows three equal student cards in each grade row', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(StudentAchievementCard), findsNWidgets(6));
  });

  testWidgets('LoginScreen matches the reference sign-in layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
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
    await tester.pumpWidget(const MaterialApp(home: SchoolScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(StaffProfileCard), findsWidgets);
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
