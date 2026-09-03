import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/today_in_class.dart';
import 'group_service.dart';
import 'auth_headers.dart';

class HomeworkService {
  HomeworkService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<TodayInClassRecord>> getRecords(String groupId) async {
    final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/homework');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to load Homework.', uri.toString());
    }
    final payload = jsonDecode(response.body);
    final list = payload is List
        ? payload
        : payload is Map && payload['data'] is List
            ? payload['data'] as List
            : <dynamic>[];
    return list
        .map((item) => TodayInClassRecord.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<TodayInClassRecord> createRecord({
    required String groupId,
    required DateTime date,
    required String subject,
    required String message,
    required bool sendToStudents,
    required bool sendToTeachers,
    required bool commentsAllowed,
    required List<String> attachments,
  }) => _save(
        method: 'POST',
        uri: _uri('/api/groups/${Uri.encodeComponent(groupId)}/homework'),
        body: {
          'date': date.toIso8601String(),
          'subject': subject,
          'message': message,
          'sendToStudents': sendToStudents,
          'sendToTeachers': sendToTeachers,
          'commentsAllowed': commentsAllowed,
          'attachments': attachments,
        },
        expectedStatus: 201,
      );

  Future<TodayInClassRecord> updateRecord({
    required String groupId,
    required String recordId,
    required DateTime date,
    required String subject,
    required String message,
    required bool sendToStudents,
    required bool sendToTeachers,
    required bool commentsAllowed,
    required List<String> attachments,
  }) => _save(
        method: 'PUT',
        uri: _uri('/api/groups/${Uri.encodeComponent(groupId)}/homework/${Uri.encodeComponent(recordId)}'),
        body: {
          'date': date.toIso8601String(),
          'subject': subject,
          'message': message,
          'sendToStudents': sendToStudents,
          'sendToTeachers': sendToTeachers,
          'commentsAllowed': commentsAllowed,
          'attachments': attachments,
        },
        expectedStatus: 200,
      );

  Future<void> deleteRecord(String groupId, String recordId) async {
    final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/homework/${Uri.encodeComponent(recordId)}');
    final response = await http.delete(uri, headers: await AuthHeaders.bearer()).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to delete Homework.', uri.toString());
    }
  }

  Future<TodayInClassRecord> _save({
    required String method,
    required Uri uri,
    required Map<String, dynamic> body,
    required int expectedStatus,
  }) async {
    final request = http.Request(method, uri)
      ..body = jsonEncode(body);
    request.headers.addAll(await AuthHeaders.json());
    final response = await http.Client().send(request).then(http.Response.fromStream).timeout(const Duration(seconds: 20));
    if (response.statusCode != expectedStatus) {
      throw ApiException(response.statusCode, _message(response.body, 'Unable to save Homework.'), uri.toString());
    }
    return TodayInClassRecord.fromJson(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
  }

  Future<String> uploadAttachment(String fileName, List<int> bytes, {MediaType? contentType}) async {
    final request = http.MultipartRequest('POST', _uri('/api/upload/attachment'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName, contentType: contentType));
    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) throw Exception('Unable to upload attachment.');
    final payload = jsonDecode(body);
    if (payload is Map && payload['url'] is String) return payload['url'] as String;
    throw const FormatException('Invalid attachment upload response.');
  }

  String _message(String body, String fallback) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] is String) return payload['message'] as String;
    } catch (_) {}
    return fallback;
  }
}
