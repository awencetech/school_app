class ClassTimetableEntry {
  const ClassTimetableEntry({
    required this.id,
    required this.groupId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    this.room = '',
    this.notes = '',
  });

  final String id;
  final String groupId;
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final String room;
  final String notes;

  factory ClassTimetableEntry.fromJson(Map<String, dynamic> json) =>
      ClassTimetableEntry(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        groupId: (json['groupId'] ?? '').toString(),
        day: (json['day'] ?? '').toString(),
        startTime: (json['startTime'] ?? '').toString(),
        endTime: (json['endTime'] ?? '').toString(),
        subject: (json['subject'] ?? '').toString(),
        teacher: (json['teacher'] ?? '').toString(),
        room: (json['room'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
    'subject': subject,
    'teacher': teacher,
    'room': room,
    'notes': notes,
  };
}
