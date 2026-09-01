import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/screens/student/student_menu_screen.dart';
import 'package:school_app/screens/student/student_info_screen.dart';
import 'package:school_app/screens/student/student_attendance_page.dart';
import 'package:school_app/screens/student/student_exam_results_page.dart';
import 'package:school_app/screens/student/student_diary_page.dart';
import 'package:school_app/screens/student/student_faculty_feedback_page.dart';
import 'package:school_app/screens/student/student_ptm_page.dart';
import 'package:school_app/screens/student/student_uni_route_page.dart';

void main() {
  testWidgets('student menu tiles navigate to the expected student pages', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentMenuScreen()));

    await tester.tap(find.text('Student Info'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentInfoScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Attendance'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentAttendancePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exam Score'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentExamResultsPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Student Diary'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentDiaryPage), findsOneWidget);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Review Feedback'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StudentFacultyFeedbackPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(StudentDiaryPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Feedback'),
      find.byType(SingleChildScrollView),
      const Offset(0, -50),
    );
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentFacultyFeedbackPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Pick Up'),
      find.byType(SingleChildScrollView),
      const Offset(0, -50),
    );
    await tester.tap(find.text('Pick Up'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentUniRoutePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('PTM Status'),
      find.byType(SingleChildScrollView),
      const Offset(0, -50),
    );
    await tester.tap(find.text('PTM Status'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentPtmPage), findsOneWidget);
  });
}
