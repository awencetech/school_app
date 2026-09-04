class OneOnOneMeeting {
  const OneOnOneMeeting({
    this.id,
    required this.staffId,
    required this.staffName,
    required this.startDateTime,
    required this.endDateTime,
    required this.meetingTime,
    required this.meetingInfo,
    this.meetingUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String staffId;
  final String staffName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String meetingTime;
  final String meetingInfo;
  final String meetingUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OneOnOneMeeting.fromJson(Map<String, dynamic> json) =>
      OneOnOneMeeting(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        staffId: json['staffId']?.toString() ?? '',
        staffName: json['staffName']?.toString() ?? '',
        startDateTime: _date(json['startDateTime']) ?? DateTime.now(),
        endDateTime: _date(json['endDateTime']) ?? DateTime.now(),
        meetingTime: json['meetingTime']?.toString() ?? '',
        meetingInfo: json['meetingInfo']?.toString() ?? '',
        meetingUrl: json['meetingUrl']?.toString() ?? '',
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
      );

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'staffName': staffName,
    'startDateTime': startDateTime.toIso8601String(),
    'endDateTime': endDateTime.toIso8601String(),
    'meetingTime': meetingTime,
    'meetingInfo': meetingInfo,
    'meetingUrl': meetingUrl,
  };
}
