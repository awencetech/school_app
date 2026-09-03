import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/group.dart';
import 'group_state_service.dart';
import 'preferences_service.dart';
import 'auth_headers.dart';

class GroupRemoteData {
  const GroupRemoteData({
    required this.group,
    required this.students,
    required this.teachers,
  });

  final Group group;
  final List<GroupStudent> students;
  final List<GroupTeacher> teachers;
}

class GroupService {
  GroupService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _groupsCacheKey = 'api_groups_cache_v1';
  static Future<List<Group>>? _groupsRequest;
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

  Future<List<Group>> getGroups({
    bool refresh = false,
    void Function(List<Group>)? onRefresh,
  }) async {
    final cached = await _readCachedGroups();
    if (cached != null && !refresh) {
      if (onRefresh != null) _refreshGroups(onRefresh);
      return cached;
    }

    return _fetchGroups();
  }

  Future<void> _refreshGroups(void Function(List<Group>) onRefresh) async {
    try {
      onRefresh(await _fetchGroups());
    } catch (_) {
      // Keep cached data when the background refresh fails.
    }
  }

  Future<List<Group>> _fetchGroups() {
    if (_groupsRequest != null) return _groupsRequest!;
    _groupsRequest = _requestGroups().whenComplete(() => _groupsRequest = null);
    return _groupsRequest!;
  }

  Future<List<Group>?> _readCachedGroups() async {
    final raw = await PreferencesService.getString(_groupsCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final payload = jsonDecode(raw);
      if (payload is! List) return null;
      return payload
          .whereType<Map>()
          .map((item) => Group.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Group>> _requestGroups() async {
    final resp = await http
        .get(_uri('/api/groups'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw ApiException(
        resp.statusCode,
        'Failed to load groups',
        _uri('/api/groups').toString(),
      );
    }

    final payload = jsonDecode(resp.body);
    if (payload is! List) {
      return <Group>[];
    }

    final groups = payload
        .map((item) => Group.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    groups.sort((a, b) => a.order.compareTo(b.order));
    await PreferencesService.setString(
      _groupsCacheKey,
      jsonEncode(groups.map((group) => group.toJson()).toList()),
    );
    return groups;
  }

  Future<GroupRemoteData> getGroupDetails(String groupId) async {
    final resp = await http
        .get(_uri('/api/groups/$groupId'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw ApiException(
        resp.statusCode,
        'Failed to load group details',
        _uri('/api/groups/$groupId').toString(),
      );
    }

    final payload = Map<String, dynamic>.from(jsonDecode(resp.body) as Map);
    final students = (payload['students'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => GroupStudent.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final teachers = (payload['teachers'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => GroupTeacher.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return GroupRemoteData(
      group: Group.fromJson(payload),
      students: students,
      teachers: teachers,
    );
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
      debugPrint(
        'GroupService.createGroup -> body: ${jsonEncode({'name': name.trim(), 'id': id.trim(), 'type': type.trim(), 'description': description.trim(), 'status': status, 'year': year.trim()})}',
      );
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
      throw ApiException(
        resp.statusCode,
        message,
        _uri('/api/groups').toString(),
      );
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
    List<GroupStudent> students = const [],
    List<GroupTeacher> teachers = const [],
  }) async {
    final resp = await http
        .put(
          _uri('/api/groups/$databaseId'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'name': name.trim(),
            'id': id.trim(),
            'type': type.trim(),
            'description': description.trim(),
            'status': status,
            'year': year.trim(),
            'students': students.map((student) => student.toJson()).toList(),
            'teachers': teachers.map((teacher) => teacher.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      final message = _errorMessage(resp.body);
      throw ApiException(
        resp.statusCode,
        message,
        _uri('/api/groups/$databaseId').toString(),
      );
    }

    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return Group.fromJson(payload);
  }

  Future<void> deleteGroup(String databaseId) async {
    final resp = await http
        .delete(_uri('/api/groups/$databaseId'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      final message = _errorMessage(resp.body);
      throw ApiException(
        resp.statusCode,
        message,
        _uri('/api/groups/$databaseId').toString(),
      );
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
    if (body.trim().startsWith('<') ||
        lower.contains('<!doctype') ||
        lower.contains('<html')) {
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
