import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/main_page_info.dart';

class MainPageInfoRepository {
  MainPageInfoRepository({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return override;
    }

    // Prefer the production host for web builds by default so deployed web/admin UI
    // points to the production backend. Developers can still override with
    // `--dart-define=API_BASE_URL=...` for local testing.
    if (kIsWeb) {
      return _productionBaseUrl;
    }

    if (kReleaseMode) {
      return _productionBaseUrl;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
    }

    return 'http://localhost:3001';
  }

  static String _normalizeUrl(String url) {
    return url
        .replaceAll('http://localhost:3001', _productionBaseUrl)
        .replaceAll('http://10.0.2.2:3001', _productionBaseUrl);
  }

  static dynamic _normalizePayload(dynamic value) {
    if (value is String) {
      return _normalizeUrl(value);
    }

    if (value is Map<String, dynamic>) {
      return value.map((key, nested) => MapEntry(key, _normalizePayload(nested)));
    }

    if (value is List) {
      return value.map(_normalizePayload).toList();
    }

    return value;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<String> uploadPoster({required String fileName, required List<int> bytes}) async {
    final request = http.MultipartRequest('POST', _uri('/api/upload/school-poster'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Unable to upload school poster.');
    }

    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic> && payload['url'] is String) {
        return _normalizeUrl(payload['url'] as String);
      }
    } catch (_) {
      // fall through to format error below
    }

    throw const FormatException('Invalid poster upload response');
  }

  Future<MainPageInfo> getMainPageInfo() async {
    final response = await http.get(_uri('/api/mainpage-info')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load MongoDB school configuration');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid main page payload');
    }
    final normalizedPayload = Map<String, dynamic>.from(_normalizePayload(payload) as Map<String, dynamic>);
    print('Loaded school poster URL: ${normalizedPayload['schoolSettings']?['schoolPoster'] ?? 'empty'}');
    try {
      final loadedQuote = normalizedPayload['splashScreen']?['quote'] ?? '';
      print('Loaded splash quote: $loadedQuote');
    } catch (_) {}
    return MainPageInfo.fromJson(normalizedPayload);
  }

  Future<MainPageInfo> updateMainPageInfo(MainPageInfo info) async {
    final response = await http.put(
      _uri('/api/mainpage-info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(info.toJson()),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Unable to save changes. Please try again.');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid updated main page payload');
    }
    return MainPageInfo.fromJson(Map<String, dynamic>.from(_normalizePayload(payload) as Map<String, dynamic>));
  }

  Future<MainPageInfo> updateSplashScreen(Map<String, dynamic> payload) async {
    return _updateSection('/api/mainpage-info/splash', payload);
  }

  Future<MainPageInfo> updateSchoolSettings(Map<String, dynamic> payload) async {
    return _updateSection('/api/mainpage-info/settings', payload);
  }

  Future<MainPageInfo> updateSchoolContent(Map<String, dynamic> payload) async {
    return _updateSection('/api/mainpage-info/content', payload);
  }

  Future<MainPageInfo> updateGradePage(Map<String, dynamic> payload) async {
    return _updateSection('/api/mainpage-info/grades', payload);
  }

  Future<MainPageInfo> _updateSection(String path, Map<String, dynamic> payload) async {
    final response = await http.put(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Unable to save changes. Please try again.');
    }

    final parsed = jsonDecode(response.body);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Invalid section payload');
    }

    return MainPageInfo.fromJson(Map<String, dynamic>.from(_normalizePayload(parsed) as Map<String, dynamic>));
  }
}
