import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StudentRecord {
  const StudentRecord({
    this.id,
    required this.name,
    required this.className,
    required this.section,
    required this.studentId,
    required this.admissionNumber,
    required this.parentName,
    required this.mobileNumber,
    required this.address,
    required this.about,
    required this.hobbies,
    required this.role,
    this.imageUrl = '',
  });

  final String? id;
  final String name;
  final String className;
  final String section;
  final String studentId;
  final String admissionNumber;
  final String parentName;
  final String mobileNumber;
  final String address;
  final String about;
  final String hobbies;
  final String role;
  final String imageUrl;

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      admissionNumber: json['admissionNumber']?.toString() ?? '',
      parentName: json['parentName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      about: json['about']?.toString() ?? '',
      hobbies: json['hobbies']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'className': className,
        'section': section,
        'studentId': studentId,
        'admissionNumber': admissionNumber,
        'parentName': parentName,
        'mobileNumber': mobileNumber,
        'address': address,
        'about': about,
        'hobbies': hobbies,
        'role': role,
        'imageUrl': imageUrl,
      };
}

class StudentService {
  StudentService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb || kReleaseMode) return _productionBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<StudentRecord>> getStudents() async {
    final response = await http.get(_uri('/api/students')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Unable to load student information.');
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => StudentRecord.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<StudentRecord> createStudent(StudentRecord student) async {
    final response = await http.post(
      _uri('/api/students'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(student.toJson()),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 201) {
      final msg = _message(response.statusCode, response.body);
      throw Exception(msg);
    }

    return StudentRecord.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<StudentRecord> updateStudent(StudentRecord student) async {
    if (student.id == null || student.id!.isEmpty) throw Exception('Student record ID is missing.');
    final response = await http.put(
      _uri('/api/students/${Uri.encodeComponent(student.id!)}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(student.toJson()),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final msg = _message(response.statusCode, response.body);
      throw Exception(msg);
    }

    return StudentRecord.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteStudent(String id) async {
    final response = await http.delete(_uri('/api/students/${Uri.encodeComponent(id)}')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      final msg = _message(response.statusCode, response.body);
      throw Exception(msg);
    }
  }

  String _message(int statusCode, String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] != null) return payload['message'].toString();
    } catch (_) {}

    final plainText = body.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plainText.isNotEmpty) {
      return 'Student request failed ($statusCode): ${plainText.length > 180 ? '${plainText.substring(0, 180)}...' : plainText}';
    }
    return 'Student request failed ($statusCode).';
  }
}
