class DemographyMember {
  const DemographyMember({
    this.name = '',
    this.staffId = '',
    this.studentId = '',
  });

  final String name;
  final String staffId;
  final String studentId;

  String get displayText {
    final value = name.trim();
    if (value.isEmpty) return '';
    if (staffId.trim().isNotEmpty) return '$value (${staffId.trim()})';
    if (studentId.trim().isNotEmpty) return '$value (${studentId.trim()})';
    return value;
  }

  factory DemographyMember.fromJson(Map<String, dynamic> json) {
    return DemographyMember(
      name: (json['name'] ?? '').toString().trim(),
      staffId: (json['staffId'] ?? '').toString().trim(),
      studentId: (json['studentId'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name.trim().isNotEmpty) data['name'] = name.trim();
    if (staffId.trim().isNotEmpty) data['staffId'] = staffId.trim();
    if (studentId.trim().isNotEmpty) data['studentId'] = studentId.trim();
    return data;
  }
}

class Demography {
  Demography({
    this.id,
    required this.groupId,
    required this.groupName,
    List<DemographyMember>? teachers,
    List<DemographyMember>? otherTeachers,
    List<DemographyMember>? students,
    this.createdAt,
    this.updatedAt,
  })  : teachers = teachers ?? const <DemographyMember>[],
        otherTeachers = otherTeachers ?? const <DemographyMember>[],
        students = students ?? const <DemographyMember>[];

  final String? id;
  final String groupId;
  final String groupName;
  final List<DemographyMember> teachers;
  final List<DemographyMember> otherTeachers;
  final List<DemographyMember> students;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Demography.fromJson(Map<String, dynamic> json) {
    return Demography(
      id: (json['_id'] ?? json['id'] ?? '').toString().isEmpty
          ? null
          : (json['_id'] ?? json['id']).toString(),
      groupId: (json['groupId'] ?? '').toString(),
      groupName: (json['groupName'] ?? '').toString(),
      teachers: ((json['teachers'] as List?) ?? const [])
          .map((item) => DemographyMember.fromJson(Map<String, dynamic>.from(item)))
          .where((member) => member.name.trim().isNotEmpty)
          .toList(),
      otherTeachers: ((json['otherTeachers'] as List?) ?? const [])
          .map((item) => DemographyMember.fromJson(Map<String, dynamic>.from(item)))
          .where((member) => member.name.trim().isNotEmpty)
          .toList(),
      students: ((json['students'] as List?) ?? const [])
          .map((item) => DemographyMember.fromJson(Map<String, dynamic>.from(item)))
          .where((member) => member.name.trim().isNotEmpty)
          .toList(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) '_id': id,
      'groupId': groupId,
      'groupName': groupName,
      'teachers': teachers.map((member) => member.toJson()).toList(),
      'otherTeachers': otherTeachers.map((member) => member.toJson()).toList(),
      'students': students.map((member) => member.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
