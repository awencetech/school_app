import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lesson_plan.dart';
import 'group_service.dart';

class LessonPlanService {
  LessonPlanService({String? baseUrl})
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

  Uri _uri(String groupId, [String? id]) => Uri.parse(
    '$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/lesson-plans${id == null ? '' : '/${Uri.encodeComponent(id)}'}',
  );

  Future<List<LessonPlan>> getForGroup(String groupId) async {
    final uri = _uri(groupId);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Unable to load lesson plans.',
        uri.toString(),
      );
    }
    final data = jsonDecode(response.body) as List;
    return data
        .map(
          (item) =>
              LessonPlan.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<LessonPlan>> getForDate(String groupId, DateTime date) async {
    final uri = Uri.parse(
      '$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/lesson-plans?date=${date.toIso8601String().split('T')[0]}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Unable to load lesson plans for the date.',
        uri.toString(),
      );
    }
    final data = jsonDecode(response.body) as List;
    return data
        .map(
          (item) =>
              LessonPlan.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<LessonPlan> save(
    String groupId,
    LessonPlan plan,
  ) async {
    final uri = _uri(groupId, plan.id.isEmpty ? null : plan.id);
    final response = plan.id.isEmpty
        ? await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(plan.toJson()),
          )
        : await http.put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(plan.toJson()),
          );
    if (response.statusCode != (plan.id.isEmpty ? 201 : 200)) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    return LessonPlan.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<void> delete(String groupId, String id) async {
    final uri = _uri(groupId, id);
    final response = await http.delete(uri);
    if (response.statusCode != 204) {
      throw ApiException(
        response.statusCode,
        'Unable to delete lesson plan.',
        uri.toString(),
      );
    }
  }

  String _message(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map && value['message'] is String) {
        return value['message'] as String;
      }
    } catch (_) {}
    return 'Unable to save lesson plan.';
  }
}
