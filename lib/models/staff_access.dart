import 'staff_info.dart';

class StaffAccessRecord {
  const StaffAccessRecord({
    required this.staff,
    this.accessGroups = const [],
  });

  final StaffInfo staff;
  final List<String> accessGroups;

  factory StaffAccessRecord.fromJson(Map<String, dynamic> json) {
    final staffJson = json['staff'] is Map
        ? Map<String, dynamic>.from(json['staff'] as Map)
        : json;
    final groups = json['accessGroups'];
    return StaffAccessRecord(
      staff: StaffInfo.fromJson(staffJson),
      accessGroups: groups is List
          ? groups.map((value) => value.toString()).toList()
          : const [],
    );
  }
}
