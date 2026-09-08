import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student_campaign.dart';
import 'auth_headers.dart';

class StudentCampaignService {
  StudentCampaignService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<StudentCampaign>> getCampaigns() async {
    final response = await http.get(_uri('/api/student-campaigns'), headers: await AuthHeaders.bearer()).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Unable to load campaigns.');
    final payload = jsonDecode(response.body);
    final values = payload is Map ? payload['data'] : payload;
    if (values is! List) return [];
    return values.whereType<Map>().map((item) => StudentCampaign.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<void> createCampaign({
    required String title,
    required String description,
    required String type,
    required String className,
    required DateTime startDate,
    required DateTime endDate,
    required String instructions,
    PlatformFile? poster,
  }) async {
    var imageUrl = '';
    if (poster != null) {
      final bytes = await poster.readAsBytes();
      final request = http.MultipartRequest('POST', _uri('/api/upload/attachment'));
      request.headers.addAll(await AuthHeaders.bearer());
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: poster.name));
      final upload = await http.Response.fromStream(await request.send()).timeout(const Duration(seconds: 30));
      if (upload.statusCode < 200 || upload.statusCode >= 300) throw Exception('Unable to upload poster.');
      imageUrl = (jsonDecode(upload.body) as Map)['url']?.toString() ?? '';
    }
    final response = await http.post(
      _uri('/api/student-campaigns'),
      headers: await AuthHeaders.json(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'type': type,
        'className': className,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'instructions': instructions,
        'imageUrl': imageUrl,
      }),
    ).timeout(const Duration(seconds: 20));
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || payload is! Map || payload['success'] != true) {
      throw Exception(payload is Map ? payload['message'] ?? 'Unable to save campaign.' : 'Unable to save campaign.');
    }
  }
}
