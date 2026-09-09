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
    this.isHomework = false,
    this.attachments = const [],
    String? title,
    this.dueDate,
    String? priority,
    String? topic,
    String? status,
    String? teacherNotes,
    String? startTime,
    String? endTime,
  })  : title = title ?? '',
        priority = priority ?? 'Medium',
        topic = topic ?? '',
        status = status ?? '',
        teacherNotes = teacherNotes ?? '',
        startTime = startTime ?? '',
        endTime = endTime ?? '';

  final String id;
  final String groupId;
  final DateTime date;
  final String subject;
  final String message;
  final bool sendToStudents;
  final bool sendToTeachers;
  final bool commentsAllowed;
  final bool isHomework;
  final List<String> attachments;
  final String title;
  final DateTime? dueDate;
  final String priority;
  final String topic;
  final String status;
  final String teacherNotes;
  final String startTime;
  final String endTime;

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
      isHomework: json['isHomework'] == true,
      attachments: (json['attachments'] is List)
          ? (json['attachments'] as List).map((item) => item.toString()).toList()
          : const [],
          title: (json['title'] ?? '').toString(),
          dueDate: DateTime.tryParse((json['dueDate'] ?? '').toString()),
          priority: (json['priority'] ?? 'Medium').toString(),
          topic: (json['topic'] ?? '').toString(),
          status: (json['status'] ?? '').toString(),
          teacherNotes: (json['teacherNotes'] ?? '').toString(),
          startTime: (json['startTime'] ?? '').toString(),
          endTime: (json['endTime'] ?? '').toString(),
    );
  }
}
