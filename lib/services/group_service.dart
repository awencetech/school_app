import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/group.dart';

class GroupService {
  GroupService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return _productionBaseUrl;
    if (kReleaseMode) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<Group>> getGroups() async {
    final resp = await http.get(_uri('/api/groups')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, 'Failed to load groups', _uri('/api/groups').toString());
    }

    final payload = jsonDecode(resp.body);
    if (payload is! List) {
      return <Group>[];
    }

    final groups = payload
        .map((item) => Group.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    groups.sort((a, b) => a.order.compareTo(b.order));
    return groups;
  }

  Future<Group> createGroup({
    required String name,
    required String id,
    required String type,
    required String description,
    required String status,
    required String year,
  }) async {
    // Log the outgoing request for local debugging (safe to remove in production)
    try {
      debugPrint('GroupService.createGroup -> POST ${_uri('/api/groups')}');
      debugPrint('GroupService.createGroup -> body: ${jsonEncode({
        'name': name.trim(),
        'id': id.trim(),
        'type': type.trim(),
        'description': description.trim(),
        'status': status,
        'year': year.trim(),
      })}');
    } catch (_) {}

    final resp = await http
        .post(
          _uri('/api/groups'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name.trim(),
            'id': id.trim(),
            'type': type.trim(),
            'description': description.trim(),
            'status': status,
            'year': year.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 201) {
      final message = _errorMessage(resp.body);
      throw ApiException(resp.statusCode, message, _uri('/api/groups').toString());
    }

    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return Group.fromJson(payload);
  }

  Future<Group> updateGroup(
    String databaseId, {
    required String name,
    required String id,
    required String type,
    required String description,
    required String status,
    required String year,
  }) async {
    final resp = await http
        .put(
          _uri('/api/groups/$databaseId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name.trim(),
            'id': id.trim(),
            'type': type.trim(),
            'description': description.trim(),
            'status': status,
            'year': year.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      final message = _errorMessage(resp.body);
      throw ApiException(resp.statusCode, message, _uri('/api/groups/$databaseId').toString());
    }

    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return Group.fromJson(payload);
  }

  Future<void> deleteGroup(String databaseId) async {
    final resp = await http.delete(_uri('/api/groups/$databaseId')).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      final message = _errorMessage(resp.body);
      throw ApiException(resp.statusCode, message, _uri('/api/groups/$databaseId').toString());
    }
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    // If backend returned an HTML error page (Express default), avoid showing raw HTML in UI
    final lower = body.toLowerCase();
    if (body.trim().startsWith('<') || lower.contains('<!doctype') || lower.contains('<html')) {
      return 'Request failed';
    }

    return body.isNotEmpty ? body : 'Request failed';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String uri;

  ApiException(this.statusCode, this.message, this.uri);

  @override
  String toString() => 'ApiException: $statusCode $message at $uri';
}
