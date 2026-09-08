import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/group.dart';
import 'auth_headers.dart';
import 'group_service.dart';

class ClassService {
  ClassService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<Group>> getClasses({
    bool refresh = false,
    String schoolId = 'default-school',
  }) async {
    final response = await http
        .get(
          _uri('/api/classes').replace(queryParameters: {'schoolId': schoolId}),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 15));
    _check(response, 'Failed to load classes');
    final payload = jsonDecode(response.body);
    if (payload is! List) return const [];
    return payload
        .whereType<Map>()
        .map((item) => Group.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.type.trim().toLowerCase() == 'class')
        .toList();
  }

  Future<Group> createClass({
    required String name,
    required String id,
    required String type,
    required String description,
    required String status,
    required String year,
    String schoolId = 'default-school',
  }) async {
    final response = await http
        .post(
          _uri('/api/classes'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'name': name.trim(),
            'id': id.trim(),
            'type': type.trim(),
            'description': description.trim(),
            'status': status,
            'year': year.trim(),
            'schoolId': schoolId,
          }),
        )
        .timeout(const Duration(seconds: 20));
    _check(response, 'Unable to create class');
    return Group.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Group> updateClass(
    String databaseId, {
    required String name,
    required String id,
    required String type,
    required String description,
    required String status,
    required String year,
    String schoolId = 'default-school',
  }) async {
    final response = await http
        .put(
          _uri('/api/classes/$databaseId'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'name': name.trim(),
            'id': id.trim(),
            'type': type.trim(),
            'description': description.trim(),
            'status': status,
            'year': year.trim(),
            'schoolId': schoolId,
          }),
        )
        .timeout(const Duration(seconds: 20));
    _check(response, 'Unable to update class');
    return Group.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteClass(
    String databaseId, {
    String schoolId = 'default-school',
  }) async {
    final response = await http
        .delete(
          _uri(
            '/api/classes/$databaseId',
          ).replace(queryParameters: {'schoolId': schoolId}),
        )
        .timeout(const Duration(seconds: 15));
    _check(response, 'Unable to delete class');
  }

  void _check(http.Response response, String fallback) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map && payload['message'] is String) {
        throw ApiException(
          response.statusCode,
          payload['message'] as String,
          response.request?.url.toString() ?? '',
        );
      }
    } catch (error) {
      if (error is ApiException) rethrow;
    }
    throw ApiException(
      response.statusCode,
      fallback,
      response.request?.url.toString() ?? '',
    );
  }
}
