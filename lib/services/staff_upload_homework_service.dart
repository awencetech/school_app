import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/today_in_class.dart';
import 'auth_headers.dart';
import 'group_service.dart';

class StaffUploadHomeworkService {
  StaffUploadHomeworkService({String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb || kReleaseMode) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<TodayInClassRecord> create({
    required String groupId,
    required String groupName,
    required String schoolId,
    required DateTime date,
    required String subject,
    required String message,
    required String title,
    required DateTime? dueDate,
    required String priority,
    required bool sendToStudents,
    required bool sendToTeachers,
    required bool commentsAllowed,
    required List<String> attachments,
  }) async {
    final uri = _uri('/api/staff-uploadhw');
    final response = await http.post(
      uri,
      headers: await AuthHeaders.json(),
      body: jsonEncode({
        'groupId': groupId,
        'groupName': groupName,
        'schoolId': schoolId,
        'date': date.toIso8601String(),
        'subject': subject,
        'message': message,
        'title': title,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
        'sendToStudents': sendToStudents,
        'sendToTeachers': sendToTeachers,
        'commentsAllowed': commentsAllowed,
        'attachments': attachments,
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _message(response.body), uri.toString());
    }
    return TodayInClassRecord.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<String> uploadAttachment(
    String fileName,
    List<int> bytes, {
    MediaType? contentType,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/upload/attachment'));
    request.headers.addAll(await AuthHeaders.bearer());
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: contentType,
    ));
    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to upload attachment.', request.url.toString());
    }
    final payload = jsonDecode(body);
    if (payload is Map && payload['url'] is String) return payload['url'] as String;
    throw const FormatException('Invalid attachment upload response.');
  }

  String _message(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] is String) return payload['message'] as String;
    } catch (_) {}
    return body.isEmpty ? 'Unable to save staff homework.' : body;
  }
}
