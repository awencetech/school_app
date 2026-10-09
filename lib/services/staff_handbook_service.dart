import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/staff_handbook.dart';
import 'auth_headers.dart';
import '../config/api_config.dart';

class StaffHandbookService {
  StaffHandbookService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();
  final String _baseUrl;
  static const schoolId = 'default-school';

  static String _resolveBaseUrl() {
    if (kReleaseMode) {
      return ApiConfig.releaseBaseUrl;
    }
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kReleaseMode) {
      return ApiConfig.releaseBaseUrl;
    }
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<StaffHandbook> getHandbook() async {
    final response = await http
        .get(
          _uri('/api/school-handbook/$schoolId'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception(_message(response));
    return StaffHandbook.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<StaffHandbook> save(StaffHandbook handbook) async {
    final path = handbook.id == null
        ? '/api/school-handbook'
        : '/api/school-handbook/${Uri.encodeComponent(handbook.id!)}';
    final response = await (handbook.id == null ? http.post : http.put)(
      _uri(path),
      headers: await AuthHeaders.json(),
      body: jsonEncode(handbook.toJson()),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response));
    }
    return StaffHandbook.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> upload(List<int> bytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/upload/attachment'),
    );
    request.headers.addAll(await AuthHeaders.bearer());
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, body));
    }
    final url = (jsonDecode(body) as Map<String, dynamic>)['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('The uploaded document URL was missing.');
    }
    return url
        .replaceAll('http://localhost:3001', _baseUrl)
        .replaceAll('http://10.0.2.2:3001', _baseUrl);
  }

  String _message(http.Response response) =>
      _messageBody(response.statusCode, response.body);
  String _messageBody(int statusCode, String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map && value['message'] != null) {
        return value['message'].toString();
      }
    } catch (_) {}
    return 'Handbook request failed ($statusCode).';
  }
}
