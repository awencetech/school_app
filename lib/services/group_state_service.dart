import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/group.dart';

class GroupStudent {
  GroupStudent({
    required this.id,
    required this.groupId,
    required this.name,
    required this.admissionNo,
    required this.section,
    this.imageUrl,
    this.details = '',
    this.contact = '',
    this.email = '',
  });

  String id;
  String groupId;
  String name;
  String admissionNo;
  String section;
  String? imageUrl;
  String details;
  String contact;
  String email;

  factory GroupStudent.fromJson(Map<String, dynamic> json) {
    return GroupStudent(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      admissionNo: (json['admissionNo'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString().isEmpty ? null : (json['imageUrl'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'name': name,
        'admissionNo': admissionNo,
        'section': section,
        'imageUrl': imageUrl,
        'details': details,
        'contact': contact,
        'email': email,
      };
}

class GroupTeacher {
  GroupTeacher({
    required this.id,
    required this.groupId,
    required this.teacherId,
    required this.name,
    required this.subject,
    required this.role,
    this.imageUrl,
    this.details = '',
    this.contact = '',
    this.email = '',
  });

  String id;
  String groupId;
  String teacherId;
  String name;
  String subject;
  String role;
  String? imageUrl;
  String details;
  String contact;
  String email;

  factory GroupTeacher.fromJson(Map<String, dynamic> json) {
    return GroupTeacher(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      teacherId: (json['teacherId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString().isEmpty ? null : (json['imageUrl'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'teacherId': teacherId,
        'name': name,
        'subject': subject,
        'role': role,
        'imageUrl': imageUrl,
        'details': details,
        'contact': contact,
        'email': email,
      };
}

class GroupSettings {
  GroupSettings({
    required this.groupId,
    this.section = '',
    this.communicationPermissions = true,
    this.studentPermissions = true,
    this.teacherPermissions = true,
    this.description = '',
    this.status = 'Active',
    this.academicYear = '2022',
  });

  final String groupId;
  final String section;
  final bool communicationPermissions;
  final bool studentPermissions;
  final bool teacherPermissions;
  final String description;
  final String status;
  final String academicYear;

  factory GroupSettings.fromJson(String groupId, Map<String, dynamic> json) {
    return GroupSettings(
      groupId: groupId,
      section: (json['section'] ?? '').toString(),
      communicationPermissions: json['communicationPermissions'] ?? true,
      studentPermissions: json['studentPermissions'] ?? true,
      teacherPermissions: json['teacherPermissions'] ?? true,
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'Active').toString(),
      academicYear: (json['academicYear'] ?? '2022').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'section': section,
        'communicationPermissions': communicationPermissions,
        'studentPermissions': studentPermissions,
        'teacherPermissions': teacherPermissions,
        'description': description,
        'status': status,
        'academicYear': academicYear,
      };
}

class GroupScopedData {
  GroupScopedData({
    required this.groupId,
    required this.group,
    this.imageUrl,
    List<GroupStudent>? students,
    List<GroupTeacher>? teachers,
    GroupSettings? settings,
  })  : students = students ?? <GroupStudent>[],
        teachers = teachers ?? <GroupTeacher>[],
        settings = settings ??
            GroupSettings(
              groupId: groupId,
              status: group.status,
              academicYear: group.year,
              description: group.description,
            );

  final String groupId;
  Group group;
  String? imageUrl;
  List<GroupStudent> students;
  List<GroupTeacher> teachers;
  GroupSettings settings;

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'group': group.toJson(),
        'imageUrl': imageUrl,
        'students': students.map((item) => item.toJson()).toList(),
        'teachers': teachers.map((item) => item.toJson()).toList(),
        'settings': settings.toJson(),
      };
}

class GroupStateService {
  GroupStateService._();

  static final GroupStateService instance = GroupStateService._();

  final Map<String, GroupScopedData> _groups = <String, GroupScopedData>{};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (!key.startsWith(_storagePrefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final groupId = (decoded['groupId'] ?? '').toString();
        if (groupId.isEmpty) continue;
        final groupJson = decoded['group'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final group = Group.fromJson(groupJson);
        final state = GroupScopedData(
          groupId: groupId,
          group: group,
          imageUrl: decoded['imageUrl']?.toString(),
          students: ((decoded['students'] as List?) ?? const [])
              .map((item) => GroupStudent.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(),
          teachers: ((decoded['teachers'] as List?) ?? const [])
              .map((item) => GroupTeacher.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(),
          settings: decoded['settings'] != null
              ? GroupSettings.fromJson(groupId, Map<String, dynamic>.from(decoded['settings'] as Map))
              : GroupSettings(
                  groupId: groupId,
                  status: group.status,
                  academicYear: group.year,
                  description: group.description,
                ),
        );
        _groups[groupId] = state;
      } catch (error) {
        debugPrint('GroupStateService initialize error: $error');
      }
    }
  }

  String get _storagePrefix => 'group_state_';

  String _key(String groupId) => '$_storagePrefix${groupId.trim()}';

  GroupScopedData ensureStateForGroup(String groupId, {Group? seed}) {
    final key = groupId.trim();
    if (key.isEmpty) {
      throw ArgumentError('groupId is required');
    }
    if (_groups.containsKey(key)) {
      if (seed != null && _groups[key]!.group.id.isEmpty) {
        _groups[key]!.group = seed;
      }
      return _groups[key]!;
    }
    final base = seed ?? Group(id: key, name: key);
    final state = GroupScopedData(groupId: key, group: base);
    _groups[key] = state;
    return state;
  }

  GroupScopedData _ensureState(String groupId, {Group? seed}) => ensureStateForGroup(groupId, seed: seed);

  Future<void> _saveState(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final state = _ensureState(groupId);
    await prefs.setString(_key(groupId), jsonEncode(state.toJson()));
  }

  Future<Group> getGroup(String groupId) async {
    await initialize();
    final state = _ensureState(groupId,
        seed: Group(id: groupId, name: groupId, status: 'Active', year: '2022'));
    return state.group;
  }

  Future<Group> updateGroup(String groupId, Map<String, dynamic> data) async {
    await initialize();
    final state = _ensureState(groupId);
    state.group = state.group.copyWith(
      id: data['id']?.toString() ?? state.group.id,
      name: data['name']?.toString() ?? state.group.name,
      type: data['type']?.toString() ?? state.group.type,
      description: data['description']?.toString() ?? state.group.description,
      status: data['status']?.toString() ?? state.group.status,
      year: data['year']?.toString() ?? state.group.year,
      imageUrl: data['imageUrl']?.toString() ?? state.imageUrl,
    );
    state.settings = GroupSettings(
      groupId: groupId,
      section: data['section']?.toString() ?? state.settings.section,
      communicationPermissions: data['communicationPermissions'] ?? state.settings.communicationPermissions,
      studentPermissions: data['studentPermissions'] ?? state.settings.studentPermissions,
      teacherPermissions: data['teacherPermissions'] ?? state.settings.teacherPermissions,
      description: state.group.description,
      status: state.group.status,
      academicYear: state.group.year,
    );
    await _saveState(groupId);
    return state.group;
  }

  Future<String?> uploadGroupImage(String groupId, String? imagePath) async {
    await initialize();
    if (imagePath == null || imagePath.isEmpty) {
      final state = _ensureState(groupId);
      state.imageUrl = null;
      await _saveState(groupId);
      return null;
    }

    final state = _ensureState(groupId);
    state.imageUrl = imagePath;
    await _saveState(groupId);
    return imagePath;
  }

  Future<List<GroupStudent>> getGroupStudents(String groupId) async {
    await initialize();
    final state = _ensureState(groupId);
    return List<GroupStudent>.from(state.students);
  }

  Future<void> addStudent(String groupId, GroupStudent student) async {
    await initialize();
    final state = _ensureState(groupId);
    final nextStudent = GroupStudent(
      id: student.id.isNotEmpty ? student.id : 'student-${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      name: student.name,
      admissionNo: student.admissionNo,
      section: student.section,
      imageUrl: student.imageUrl,
      details: student.details,
      contact: student.contact,
      email: student.email,
    );
    state.students = [...state.students.where((item) => item.id != nextStudent.id), nextStudent];
    await _saveState(groupId);
  }

  Future<void> updateStudent(String groupId, String studentId, Map<String, dynamic> data) async {
    await initialize();
    final state = _ensureState(groupId);
    final index = state.students.indexWhere((student) => student.id == studentId);
    if (index < 0) return;
    final item = state.students[index];
    state.students[index] = GroupStudent(
      id: item.id,
      groupId: groupId,
      name: data['name']?.toString() ?? item.name,
      admissionNo: data['admissionNo']?.toString() ?? item.admissionNo,
      section: data['section']?.toString() ?? item.section,
      imageUrl: data['imageUrl']?.toString().isEmpty == true ? null : data['imageUrl']?.toString() ?? item.imageUrl,
      details: data['details']?.toString() ?? item.details,
      contact: data['contact']?.toString() ?? item.contact,
      email: data['email']?.toString() ?? item.email,
    );
    await _saveState(groupId);
  }

  Future<void> removeStudent(String groupId, String studentId) async {
    await initialize();
    final state = _ensureState(groupId);
    state.students = state.students.where((student) => student.id != studentId).toList();
    await _saveState(groupId);
  }

  Future<List<GroupTeacher>> getGroupTeachers(String groupId) async {
    await initialize();
    final state = _ensureState(groupId);
    return List<GroupTeacher>.from(state.teachers);
  }

  Future<void> assignTeacher(String groupId, String teacherId, Map<String, dynamic> data) async {
    await initialize();
    final state = _ensureState(groupId);
    final item = GroupTeacher(
      id: data['id']?.toString() ?? teacherId,
      groupId: groupId,
      teacherId: teacherId,
      name: data['name']?.toString() ?? 'Teacher',
      subject: data['subject']?.toString() ?? '',
      role: data['role']?.toString() ?? 'Class Teacher',
      imageUrl: data['imageUrl']?.toString().isEmpty == true ? null : data['imageUrl']?.toString(),
      details: data['details']?.toString() ?? '',
      contact: data['contact']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
    );
    state.teachers = [
      ...state.teachers.where((teacher) => teacher.teacherId != teacherId && teacher.id != item.id),
      item,
    ];
    await _saveState(groupId);
  }

  Future<void> removeTeacher(String groupId, String teacherId) async {
    await initialize();
    final state = _ensureState(groupId);
    state.teachers = state.teachers.where((teacher) => teacher.teacherId != teacherId).toList();
    await _saveState(groupId);
  }

  Future<GroupSettings> getGroupSettings(String groupId) async {
    await initialize();
    final state = _ensureState(groupId);
    return state.settings;
  }

  Future<void> saveGroupSettings(String groupId, GroupSettings settings) async {
    await initialize();
    final state = _ensureState(groupId);
    state.settings = settings;
    await _saveState(groupId);
  }
}
