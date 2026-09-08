import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student_request.dart';
import 'auth_headers.dart';

class StudentRequestService {
  StudentRequestService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<void> createRequest({
    required String requestType,
    required String title,
    required String description,
  }) async {
    final response = await http
        .post(
          _uri('/api/student-requests'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'requestType': requestType,
            'title': title,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        payload is! Map || payload['success'] != true || payload['data'] is! Map) {
      throw Exception(payload is Map ? payload['message'] ?? 'Unable to save request.' : 'Unable to save request.');
    }
  }

  Future<List<StudentRequest>> getPendingRequests() async {
    final response = await http
        .get(_uri('/api/student-requests/pending'), headers: await AuthHeaders.bearer())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Unable to load requests.');
    final payload = jsonDecode(response.body);
    final values = payload is Map ? payload['data'] : payload;
    if (values is! List) return [];
    return values
        .whereType<Map>()
        .map((item) => StudentRequest.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> updateStatus({required String id, required String status}) async {
    final response = await http
        .patch(
          _uri('/api/student-requests/$id/status'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to update request status.');
    }
  }
}