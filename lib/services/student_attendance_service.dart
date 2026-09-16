import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student_attendance.dart';
import 'auth_headers.dart';

class StudentAttendanceException implements Exception {
  const StudentAttendanceException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class StudentAttendanceService {
  StudentAttendanceService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kReleaseMode) return _productionBaseUrl;
    if (kIsWeb) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<List<StudentAttendance>> getForStudent(String studentId) async {
    final query = Uri(queryParameters: {'studentId': studentId}).query;
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/student-attendance?$query'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw _exception(response);
    return _records(response.body)
        .map(
          (item) => StudentAttendance.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<StudentAttendance> save(StudentAttendance attendance) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/student-attendance'),
          headers: await AuthHeaders.json(),
          body: jsonEncode(attendance.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 201) throw _exception(response);
    return StudentAttendance.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<List<StudentAttendance>> getForDate(DateTime date) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/student-attendance?date=${_dateOnly(date)}'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw _exception(response);
    return _records(response.body)
        .map(
          (item) => StudentAttendance.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<StudentAttendance>> getReport({
    String? fromDate,
    String? toDate,
    String? className,
    String? studentId,
    String? status,
  }) async {
    final query = <String, String>{
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
      if (className != null && className.isNotEmpty) 'className': className,
      if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
      if (status != null && status.isNotEmpty && status != 'All')
        'status': status,
    };
    final response = await http
        .get(
          Uri.parse(
            '$_baseUrl/api/student-attendance?${Uri(queryParameters: query).query}',
          ),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw _exception(response);
    return _records(response.body)
        .map(
          (item) => StudentAttendance.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  StudentAttendanceException _exception(http.Response response) {
    final message = switch (response.statusCode) {
      401 => 'Authentication required. Please sign in again.',
      403 => 'You are not authorized to view attendance data.',
      404 => 'Attendance data not found.',
      500 => 'Unable to load attendance.',
      _ => _message(response),
    };
    return StudentAttendanceException(response.statusCode, message);
  }

  List<dynamic> _records(String body) {
    final payload = jsonDecode(body);
    if (payload is List) return payload;
    if (payload is Map && payload['data'] is List)
      return payload['data'] as List;
    return const [];
  }

  String _message(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null)
        return body['message'].toString();
    } catch (_) {}
    return 'Student attendance request failed (${response.statusCode}).';
  }
}
