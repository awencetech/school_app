import 'package:flutter_test/flutter_test.dart';

import 'package:school_app/models/announcement.dart';

void main() {
  test('Announcement parsing keeps the required fields', () {
    final announcement = Announcement.fromJson({
      '_id': 'abc123',
      'subject': 'Homework - Mathematics',
      'from': 'Mr. Arun Kumar',
      'to': ['students'],
      'createdOn': '2026-08-07',
      'content': 'Complete Exercise 5 from Mathematics textbook and submit it tomorrow.',
      'likes': ['u1', 'u2'],
      'comments': [
        {'name': 'Naveen', 'text': 'This homework is clear. Thank you.', 'createdAt': '2026-08-07T10:00:00Z'},
      ],
      'reminders': ['u1'],
      'createdAt': '2026-08-07T09:00:00Z',
      'updatedAt': '2026-08-07T09:30:00Z',
    });

    expect(announcement.id, 'abc123');
    expect(announcement.subject, 'Homework - Mathematics');
    expect(announcement.fromName, 'Mr. Arun Kumar');
    expect(announcement.to, ['students']);
    expect(announcement.createdOn, '2026-08-07');
    expect(announcement.content, 'Complete Exercise 5 from Mathematics textbook and submit it tomorrow.');
    expect(announcement.likes, ['u1', 'u2']);
    expect(announcement.comments.length, 1);
    expect(announcement.reminders, ['u1']);
  });
}
