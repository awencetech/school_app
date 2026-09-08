class EventCelebration {
  EventCelebration({
    this.id,
    this.schoolId = 'default-school',
    required this.heading,
    this.imageUrl = '',
    required this.subHeading,
    required this.content,
    this.eventDate,
    this.category = 'Event',
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String schoolId;
  final String heading;
  final String imageUrl;
  final String subHeading;
  final String content;
  final DateTime? eventDate;
  final String category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EventCelebration.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      final raw = value.toString();
      try {
        final datePart = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(raw)?.group(0);
        return DateTime.parse(datePart ?? raw);
      } catch (_) {
        try {
          final normalized = raw.replaceAll('/', '-');
          final datePart = RegExp(r'^\d{4}-\d{2}-\d{2}')
              .firstMatch(normalized)
              ?.group(0);
          return DateTime.parse(datePart ?? normalized);
        } catch (_) {
          return null;
        }
      }
    }

    return EventCelebration(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      schoolId: json['schoolId']?.toString() ?? 'default-school',
      heading: (json['heading'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      subHeading: (json['subHeading'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      eventDate: parseDate(json['eventDate']),
      category: (json['category'] ?? 'Event').toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'heading': heading,
    'imageUrl': imageUrl,
    'subHeading': subHeading,
    'content': content,
    'eventDate': eventDate?.toIso8601String(),
    'category': category,
  };
}
