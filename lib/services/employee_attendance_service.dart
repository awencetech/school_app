import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/employee_attendance.dart';

class EmployeeAttendanceService {
  EmployeeAttendanceService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kReleaseMode || kIsWeb) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<List<EmployeeAttendance>> getAll({String? date}) async {
    final query = date == null ? '' : '?date=${Uri.encodeQueryComponent(date)}';
    final response = await http
        .get(_uri('/api/employee-attendance$query'))
        .timeout(const Duration(seconds: 20));
    return _list(response);
  }

  Future<List<EmployeeAttendance>> getPending(String date) async {
    final response = await http
        .get(
          _uri(
            '/api/employee-attendance/pending?date=${Uri.encodeQueryComponent(date)}',
          ),
        )
        .timeout(const Duration(seconds: 20));
    return _list(response);
  }

  Future<List<EmployeeAttendance>> getLate(String date) async {
    final response = await http
        .get(
          _uri(
            '/api/employee-attendance/late?date=${Uri.encodeQueryComponent(date)}',
          ),
        )
        .timeout(const Duration(seconds: 20));
    return _list(response);
  }

  Future<Map<String, dynamic>> getSummary(String date) async {
    final response = await http
        .get(
          _uri(
            '/api/employee-attendance/summary?date=${Uri.encodeQueryComponent(date)}',
          ),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<EmployeeAttendance> save(EmployeeAttendance attendance) async {
    final editing = attendance.id != null && attendance.id!.isNotEmpty;
    final response =
        await (editing
                ? http.put(
                    _uri(
                      '/api/employee-attendance/${Uri.encodeComponent(attendance.id!)}',
                    ),
                    headers: _headers,
                    body: jsonEncode(attendance.toJson()),
                  )
                : http.post(
                    _uri('/api/employee-attendance'),
                    headers: _headers,
                    body: jsonEncode(attendance.toJson()),
                  ))
            .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response));
    }
    return EmployeeAttendance.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<EmployeeAttendance> approve(String id) async {
    final response = await http
        .patch(
          _uri('/api/employee-attendance/${Uri.encodeComponent(id)}/approve'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    return EmployeeAttendance.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<EmployeeAttendance> markLate(String id, bool isLate) async {
    final response = await http
        .patch(
          _uri('/api/employee-attendance/${Uri.encodeComponent(id)}/late'),
          headers: _headers,
          body: jsonEncode({'isLate': isLate}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    return EmployeeAttendance.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<List<EmployeeAttendance>> _list(http.Response response) async {
    if (response.statusCode != 200) throw Exception(_message(response));
    final decoded = jsonDecode(response.body);
    final values = decoded is Map ? decoded['data'] : decoded;
    if (values is! List) return const [];
    return values
        .map(
          (item) => EmployeeAttendance.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  String _message(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return 'Employee attendance request failed (${response.statusCode}).';
  }
}
