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

  static Future<MainPageInfo>? _inFlightMainPageInfoFuture;

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

  Future<MainPageInfo> getMainPageInfo() {
    if (_inFlightMainPageInfoFuture != null) {
      return _inFlightMainPageInfoFuture!;
    }

    _inFlightMainPageInfoFuture = _fetchMainPageInfo().whenComplete(() {
      _inFlightMainPageInfoFuture = null;
    });
    return _inFlightMainPageInfoFuture!;
  }

  Future<MainPageInfo> _fetchMainPageInfo() async {
    final response = await http.get(_uri('/api/mainpage-info')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load MongoDB school configuration');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid main page payload');
    }
    final normalizedPayload = Map<String, dynamic>.from(_normalizePayload(payload) as Map<String, dynamic>);

    // Backwards compatibility: Some older writes incorrectly stored homeContent
    // inside schoolContent.homeContent. If top-level homeContent is missing but
    // schoolContent.homeContent exists, promote it to top-level so the app reads
    // the correct Home-only content without affecting schoolContent.members.
    try {
      final List<dynamic>? topHomeContent = normalizedPayload['homeContent'] is List ? List<dynamic>.from(normalizedPayload['homeContent'] as List<dynamic>) : null;
      final List<dynamic>? legacyHomeContent = normalizedPayload['schoolContent'] is Map<String, dynamic> &&
              (normalizedPayload['schoolContent'] as Map<String, dynamic>).containsKey('homeContent')
          ? List<dynamic>.from((normalizedPayload['schoolContent'] as Map<String, dynamic>)['homeContent'] as List<dynamic>)
          : null;

      if (legacyHomeContent != null && legacyHomeContent.isNotEmpty) {
        if (topHomeContent == null || topHomeContent.length < legacyHomeContent.length) {
          normalizedPayload['homeContent'] = legacyHomeContent;
        }
      }
    } catch (_) {
      // ignore and continue
    }

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
      debugPrint('_updateSection failed: ${response.statusCode} ${response.body}');
      throw Exception('Unable to save changes (${response.statusCode}): ${response.body}');
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
      throw Exception('Unable to save changes (${response.statusCode}): ${response.body}');
    }

    debugPrint('_updateSection response: ${response.statusCode} -- body length: ${response.body.length}');
    dynamic parsed;
    try {
      parsed = jsonDecode(response.body);
      debugPrint('_updateSection parsed successfully: ${parsed.runtimeType}');
    } catch (e) {
      debugPrint('_updateSection jsonDecode failed: $e -- body: ${response.body}');
      throw FormatException('Invalid JSON response from server: ${e.toString()}');
    }
    if (parsed is! Map<String, dynamic>) {
      debugPrint('_updateSection unexpected payload type: ${parsed.runtimeType} -- body: ${response.body}');
      throw const FormatException('Invalid section payload');
    }

    final normalized = Map<String, dynamic>.from(_normalizePayload(parsed) as Map<String, dynamic>);

    // Backwards compatibility: promote nested schoolContent.homeContent -> top-level homeContent
    try {
      final List<dynamic>? topHomeContent = normalized['homeContent'] is List ? List<dynamic>.from(normalized['homeContent'] as List<dynamic>) : null;
      final List<dynamic>? legacyHomeContent = normalized['schoolContent'] is Map<String, dynamic> &&
              (normalized['schoolContent'] as Map<String, dynamic>).containsKey('homeContent')
          ? List<dynamic>.from((normalized['schoolContent'] as Map<String, dynamic>)['homeContent'] as List<dynamic>)
          : null;

      if (legacyHomeContent != null && legacyHomeContent.isNotEmpty) {
        if (topHomeContent == null || topHomeContent.length < legacyHomeContent.length) {
          normalized['homeContent'] = legacyHomeContent;
        }
      }
    } catch (_) {}

    return MainPageInfo.fromJson(normalized);
  }
}
