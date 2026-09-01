import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/screens/student/student_fee_information_page.dart';
import 'package:school_app/screens/student/student_menu_screen.dart';

void main() {
  testWidgets('fee information tile opens fee list and select opens fee detail', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentMenuScreen()));

    await tester.dragUntilVisible(
      find.text('Fee Information'),
      find.byType(SingleChildScrollView),
      const Offset(0, -50),
    );
    await tester.tap(find.text('Fee Information'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentFeeInformationPage), findsOneWidget);

    await tester.tap(find.text('Select').first);
    await tester.pumpAndSettle();
    expect(find.byType(StudentFeeDetailPage), findsOneWidget);
  });
}
