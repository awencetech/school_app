import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/screens/student/student_menu_screen.dart';
import 'package:school_app/screens/student/student_resources_page.dart';

void main() {
  testWidgets('student resources tile opens the list and add opens the insert page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentMenuScreen()));

    await tester.dragUntilVisible(
      find.text('Student Resources'),
      find.byType(SingleChildScrollView),
      const Offset(0, -50),
    );
    await tester.tap(find.text('Student Resources'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentResourcesPage), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentResourceInsertPage), findsOneWidget);
  });
}
