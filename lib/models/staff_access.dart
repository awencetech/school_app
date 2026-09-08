import 'staff_info.dart';

class StaffAccessRecord {
  const StaffAccessRecord({
    required this.staff,
    this.accessGroups = const [],
    this.groupIds = const [],
    this.classTeacherIds = const [],
  });

  final StaffInfo staff;
  final List<String> accessGroups;
  final List<String> groupIds;
  final List<String> classTeacherIds;

  factory StaffAccessRecord.fromJson(Map<String, dynamic> json) {
    final staffValue = json['staff'];
    final staffJson = staffValue is Map
      ? Map<String, dynamic>.from(staffValue)
      : Map<String, dynamic>.from(json);
    final groups = json['accessGroups'];
    return StaffAccessRecord(
      staff: StaffInfo.fromJson(staffJson),
      accessGroups: groups is List
          ? groups.map((value) => value.toString()).toList()
          : const [],
      groupIds: _stringList(json['groupIds'] ?? json['groups']),
      classTeacherIds: _stringList(
        json['classTeacherIds'] ?? json['classTeacher'] ?? json['classTeachers'],
      ),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
