import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:school_app/models/group_message.dart';
import 'package:school_app/screens/admin/group_messages_edit_page.dart';
import 'package:school_app/screens/admin/know_your_school_detail_page.dart';
import 'package:school_app/screens/admin/write_message_page.dart';
import 'package:school_app/services/app_state.dart';

void main() {
  test('GroupMessage parses like and comment metadata from JSON', () {
    final message = GroupMessage.fromJson({
      'id': 'm-1',
      'groupId': 'NCC2022',
      'groupName': 'NCC2022',
      'title': 'Today is off day',
      'content': 'Today is off day',
      'message': 'Today is off day',
      'authorId': 'teacher-1',
      'authorRole': 'teacher',
      'senderName': 'Teacher',
      'category': 'Important',
      'messageType': 'Important',
      'priority': 'Important',
      'audience': ['Students'],
      'approved': true,
      'createdAt': '2026-08-27T09:00:00Z',
      'commentsAllowed': true,
      'likedBy': ['student-1', 'student-2'],
      'comments': [
        {
          'id': 'c-1',
          'messageId': 'm-1',
          'groupId': 'NCC2022',
          'studentId': 'student-1',
          'studentName': 'Alice',
          'studentProfileImage': 'https://example.com/alice.png',
          'text': 'Noted',
          'createdAt': '2026-08-27T09:05:00Z',
        },
      ],
    });

    expect(message.commentsAllowed, isTrue);
    expect(message.likedBy, ['student-1', 'student-2']);
    expect(message.comments.length, 1);
    expect(message.comments.first.messageId, 'm-1');
    expect(message.comments.first.groupId, 'NCC2022');
    expect(message.comments.first.studentProfileImage, 'https://example.com/alice.png');
    expect(message.comments.first.text, 'Noted');
  });

  testWidgets('Teacher badge shows teacher name with a person icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherNameBadge(
            teacherName: 'Mrs. Priya',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Mrs. Priya'), findsOneWidget);
  });

  testWidgets('WriteMessagePage shows the student group message form', (tester) async {
    final appState = AppState();
    await appState.initialization;
    await appState.setAuthenticatedUser(
      userId: 'ST-100',
      email: 'student@example.com',
      role: 'student',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: WriteMessagePage(
            groupId: 'SAMUNI-2022-NCC2022',
            groupName: 'NCC2022',
            groupYear: '2026',
          ),
        ),
      ),
    );

    expect(find.text('Write Message'), findsWidgets);
    expect(find.text('Create Message'), findsOneWidget);
    expect(find.text('Message Type'), findsOneWidget);
    expect(find.text('Student Name'), findsOneWidget);
    expect(find.text('Message Title'), findsOneWidget);
    expect(find.text('Message Content'), findsOneWidget);
    expect(find.text('Current Group'), findsOneWidget);
    expect(find.text('Send Message'), findsOneWidget);
  });

  test('Website URLs are normalized before saving', () {
    expect(
      KnowYourSchoolDetailPage.normalizeWebsiteUrl('example.com'),
      'https://example.com',
    );
    expect(
      KnowYourSchoolDetailPage.normalizeWebsiteUrl('https://example.com'),
      'https://example.com',
    );
    expect(
      KnowYourSchoolDetailPage.normalizeWebsiteUrl('   '),
      '',
    );
  });
}
