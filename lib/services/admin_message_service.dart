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
    if (kIsWeb || kReleaseMode) return _productionBaseUrl;
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
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to send message');
    }
  }

  Future<List<AdminMessage>> getMessagesForRole(String role) async {
    final endpoint = switch (role.trim().toLowerCase()) {
      'admin' || 'administrator' => 'admin',
      'staff' || 'teacher' => 'staff',
      _ => 'student',
    };
    final response = await http
        .get(
          _uri('/api/messages/$endpoint'),
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
