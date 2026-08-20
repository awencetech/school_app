import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/today_in_class.dart';
import 'group_service.dart';

class TodayInClassService {
  TodayInClassService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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
    final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/today-in-class');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to load Today in Class.', uri.toString());
    }
    final payload = jsonDecode(response.body);
    final list = payload is List
        ? payload
        : payload is Map && payload['data'] is List
            ? payload['data'] as List
            : <dynamic>[];
    return list.map((item) => TodayInClassRecord.fromJson(Map<String, dynamic>.from(item as Map))).toList();
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
  }) async {
    final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/today-in-class');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': date.toIso8601String(),
        'subject': subject,
        'message': message,
        'sendToStudents': sendToStudents,
        'sendToTeachers': sendToTeachers,
        'commentsAllowed': commentsAllowed,
        'attachments': attachments,
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _message(response.body, 'Unable to save Today in Class.'), uri.toString());
    }
    return TodayInClassRecord.fromJson(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
  }

  Future<void> deleteRecord(String groupId, String recordId) async {
    final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/today-in-class/${Uri.encodeComponent(recordId)}');
    final response = await http.delete(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to delete Today in Class.', uri.toString());
    }
  }

  Future<String> uploadAttachment(String fileName, List<int> bytes) async {
    final request = http.MultipartRequest('POST', _uri('/api/upload/attachment'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
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
