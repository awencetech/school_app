/// An event scheduled for one activity group.
class GroupEvent {
  const GroupEvent({
    required this.id,
    required this.groupId,
    required this.title,
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.description = '',
    this.createdBy = '',
    this.color = '#FF9800',
  });

  final String id;
  final String groupId;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final String description;
  final String createdBy;
  final String color;

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    final startDate = _parseDate(
      json['startDate'] ??
          json['start_date'] ??
          json['eventDate'] ??
          json['event_date'],
    );
    if (startDate == null) {
      throw const FormatException('Event startDate is invalid.');
    }

    return GroupEvent(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? json['group_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      startDate: startDate,
      endDate: _parseDate(json['endDate'] ?? json['end_date']),
      startTime: _optionalString(json['startTime'] ?? json['start_time']),
      endTime: _optionalString(json['endTime'] ?? json['end_time']),
      description: (json['description'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      color: (json['color'] ?? '#FF9800').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'title': title,
    'startDate': _dateOnly(startDate),
    'endDate': endDate == null ? null : _dateOnly(endDate!),
    'startTime': startTime,
    'endTime': endTime,
    'description': description,
    'createdBy': createdBy,
    'color': color,
  };

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Map && value[r'$date'] != null) {
      return DateTime.tryParse(value[r'$date'].toString());
    }
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
