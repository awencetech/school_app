import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/models/group_message.dart';

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
}
