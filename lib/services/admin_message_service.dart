import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/admin_message.dart';
import '../models/group.dart';
import 'auth_headers.dart';

class AdminMessageService {
  AdminMessageService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kReleaseMode) return _productionBaseUrl;
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<void> createMessage({
    required String subject,
    required String message,
    required String messageType,
    required bool sendToStudents,
    required bool sendToStaff,
    String? groupId,
    String? groupName,
    String recipientUsername = '',
  }) async {
    final response = await http
        .post(
          _uri('/api/messages/admin'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'subject': subject,
            'message': message,
            'messageType': messageType,
            'sendToStudents': sendToStudents,
            'sendToStaff': sendToStaff,
            'groupId': groupId,
            'groupName': groupName ?? 'All Groups',
            'recipientUsername': recipientUsername,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to send message');
    }
  }

  Future<void> createStaffMessage({
    required String subject,
    required String message,
    required String groupName,
    String recipientUsername = '',
    String recipientRole = '',
  }) async {
    final response = await http
        .post(
          _uri('/api/messages/staff'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'subject': subject,
            'message': message,
            'groupName': groupName,
            'recipientId': recipientUsername,
            'recipientUsername': recipientUsername,
            'recipientRole': recipientRole,
            'messageType': 'General',
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payload = jsonDecode(response.body);
      throw Exception(payload is Map ? payload['message'] ?? 'Unable to send message.' : 'Unable to send message.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map || payload['success'] != true) {
      throw Exception('Message was not confirmed by the server.');
    }
  }

  Future<void> createStudentMessage({
    String groupId = '',
    String groupName = '',
    required String subject,
    required String message,
    String messageType = 'General',
    String recipientUsername = '',
    String recipientRole = 'staff',
  }) async {
    final response = await http
        .post(
          _uri('/api/messages/student-message'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'groupId': groupId,
            'groupName': groupName,
            'subject': subject,
            'message': message,
            'messageType': messageType,
            'recipientId': recipientUsername,
            'recipientUsername': recipientUsername,
            'recipientRole': recipientRole,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payload = jsonDecode(response.body);
      final detail = payload is Map ? payload['message'] : null;
      throw Exception(detail?.toString() ?? 'Unable to send message.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map || payload['success'] != true || payload['data'] is! Map) {
      throw Exception('Message was not confirmed by the server.');
    }
  }

  Future<List<AdminMessage>> getStudentMessages() async {
    final response = await http
        .get(
          _uri('/api/messages/inbox'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Unable to load messages');
    final payload = jsonDecode(response.body);
    final values = payload is Map ? payload['data'] : payload;
    if (values is! List) return [];
    return values
        .whereType<Map>()
        .map((item) => AdminMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AdminMessage>> getMessagesForRole(String role) async {
    final response = await http
        .get(
          _uri('/api/messages/inbox'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Unable to load messages');
    final payload = jsonDecode(response.body);
    final values = payload is Map ? payload['data'] : payload;
    if (values is! List) return [];
    return values
        .whereType<Map>()
        .map((item) => AdminMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Group>> getGroups() async {
    final response = await http
        .get(_uri('/api/groups'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Unable to load groups');
    final values = jsonDecode(response.body);
    if (values is! List) return [];
    return values
        .whereType<Map>()
        .map((item) => Group.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
