class LessonPlan {
  const LessonPlan({
    required this.id,
    required this.groupId,
    required this.date,
    required this.subject,
    required this.topic,
    required this.startTime,
    required this.endTime,
    required this.teacher,
    required this.learningObjectives,
    required this.notes,
    this.room = '',
    this.status = 'Planned',
    this.attachments = const [],
    this.completionNotes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String groupId;
  final DateTime date;
  final String subject;
  final String topic;
  final String startTime;
  final String endTime;
  final String teacher;
  final String learningObjectives;
  final String notes;
  final String room;
  final String status; // Planned, In Progress, Completed, Cancelled
  final List<String> attachments;
  final String completionNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LessonPlan.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse((json['date'] ?? '').toString());
    if (date == null) {
      throw const FormatException('Lesson plan date is invalid.');
    }
    final createdAt = DateTime.tryParse((json['createdAt'] ?? '').toString());
    final updatedAt = DateTime.tryParse((json['updatedAt'] ?? '').toString());
    final rawObjectives = json['learningObjectives'];
    final objectives = rawObjectives is List
        ? rawObjectives.map((item) => item.toString()).join('\n')
        : (rawObjectives ?? '').toString();
    return LessonPlan(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      date: date,
      subject: (json['subject'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      teacher: (json['teacher'] ?? '').toString(),
      learningObjectives: objectives,
      notes: (json['notes'] ?? '').toString(),
      room: (json['room'] ?? '').toString(),
      status: (json['status'] ?? 'Planned').toString(),
      attachments: json['attachments'] is List
          ? List<String>.from(json['attachments'])
          : [],
      completionNotes: (json['completionNotes'] ?? '').toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'subject': subject,
    'topic': topic,
    'startTime': startTime,
    'endTime': endTime,
    'teacher': teacher,
    'learningObjectives': learningObjectives,
    'notes': notes,
    'room': room,
    'status': status,
    'attachments': attachments,
    'completionNotes': completionNotes,
  };

  LessonPlan copyWith({
    String? id,
    String? groupId,
    DateTime? date,
    String? subject,
    String? topic,
    String? startTime,
    String? endTime,
    String? teacher,
    String? learningObjectives,
    String? notes,
    String? room,
    String? status,
    List<String>? attachments,
    String? completionNotes,
  }) => LessonPlan(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    date: date ?? this.date,
    subject: subject ?? this.subject,
    topic: topic ?? this.topic,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    teacher: teacher ?? this.teacher,
    learningObjectives: learningObjectives ?? this.learningObjectives,
    notes: notes ?? this.notes,
    room: room ?? this.room,
    status: status ?? this.status,
    attachments: attachments ?? this.attachments,
    completionNotes: completionNotes ?? this.completionNotes,
  );
}
