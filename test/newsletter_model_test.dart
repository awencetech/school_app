import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/models/newsletter.dart';

void main() {
  test('newsletter model parses section content from JSON', () {
    final newsletter = Newsletter.fromJson({
      'id': 'abc123',
      'heading': 'Term 1 Newsletter',
      'introduction': 'Welcome to the term.',
      'imageUrl': 'https://example.com/image.jpg',
      'sections': [
        {'subHeading': 'Academics', 'content': 'Students worked hard.'},
      ],
      'createdAt': '2025-01-01T00:00:00.000Z',
      'updatedAt': '2025-01-02T00:00:00.000Z',
    });

    expect(newsletter.heading, 'Term 1 Newsletter');
    expect(newsletter.sections.length, 1);
    expect(newsletter.sections.first.subHeading, 'Academics');
    expect(newsletter.sections.first.content, 'Students worked hard.');
  });
}
