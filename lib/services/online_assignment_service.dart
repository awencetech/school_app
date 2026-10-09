import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_headers.dart';
import '../config/api_config.dart';

class OnlineAssignmentService {
  OnlineAssignmentService({String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;

  static String _resolveBaseUrl() {
    if (kReleaseMode) {
      return ApiConfig.releaseBaseUrl;
    }
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<Map<String, dynamic>>> getAssignments({
    required String groupId,
    required List<String> groupReferences,
  }) async {
    final response = await http
        .get(
          _uri('/api/online-assignment'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_message(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid assignment response.');
    }
    final allowedGroupIds = groupReferences.toSet()..add(groupId);
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => allowedGroupIds.contains(
              (item['groupId'] ?? '').toString().trim(),
            ))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createAssignment({
    required String groupId,
    required Map<String, dynamic> assignment,
  }) =>
      _save(
        method: 'POST',
        path: '/api/online-assignment',
        assignment: {...assignment, 'groupId': groupId},
        expectedStatus: 201,
      );

  Future<Map<String, dynamic>> updateAssignment({
    required String groupId,
    required String assignmentId,
    required Map<String, dynamic> assignment,
  }) =>
      _save(
        method: 'PUT',
        path: '/api/online-assignment/${Uri.encodeComponent(assignmentId)}',
        assignment: {...assignment, 'groupId': groupId},
        expectedStatus: 200,
      );

  Future<Map<String, dynamic>> _save({
    required String method,
    required String path,
    required Map<String, dynamic> assignment,
    required int expectedStatus,
  }) async {
    final request = http.Request(method, _uri(path))
      ..body = jsonEncode(assignment);
    request.headers.addAll(await AuthHeaders.json());
    final client = http.Client();
    late final http.Response response;
    try {
      response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
    } finally {
      client.close();
    }
    if (response.statusCode != expectedStatus) {
      throw Exception(_message(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid assignment response.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final response = await http
        .delete(
          _uri('/api/online-assignment/${Uri.encodeComponent(assignmentId)}'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_message(response));
    }
  }

  String _message(http.Response response) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map && payload['message'] != null) {
        return payload['message'].toString();
      }
    } catch (_) {}
    return 'Assignment request failed (${response.statusCode}).';
  }
}
