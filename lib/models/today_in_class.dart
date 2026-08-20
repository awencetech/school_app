class TodayInClassRecord {
  const TodayInClassRecord({
    required this.id,
    required this.groupId,
    required this.date,
    required this.subject,
    required this.message,
    required this.sendToStudents,
    required this.sendToTeachers,
    required this.commentsAllowed,
    this.attachments = const [],
  });

  final String id;
  final String groupId;
  final DateTime date;
  final String subject;
  final String message;
  final bool sendToStudents;
  final bool sendToTeachers;
  final bool commentsAllowed;
  final List<String> attachments;

  factory TodayInClassRecord.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse((json['date'] ?? '').toString());
    if (date == null) throw const FormatException('Today in Class date is invalid.');
    return TodayInClassRecord(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      date: date,
      subject: (json['subject'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      sendToStudents: json['sendToStudents'] == true,
      sendToTeachers: json['sendToTeachers'] == true,
      commentsAllowed: json['commentsAllowed'] != false,
      attachments: (json['attachments'] is List)
          ? (json['attachments'] as List).map((item) => item.toString()).toList()
          : const [],
    );
  }
}
