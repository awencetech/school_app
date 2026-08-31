import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SocialUrlService {
  SocialUrlService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Uri get _facebookUri => Uri.parse('$_baseUrl/api/social-url/facebook');
  Uri get _youtubeUri => Uri.parse('$_baseUrl/api/social-url/youtube');
  Uri get _instagramUri => Uri.parse('$_baseUrl/api/social-url/instagram');
  Uri get _whatsappUri => Uri.parse('$_baseUrl/api/social-url/whatsapp');

  Future<String> getFacebookUrl() async {
    final response = await http.get(_facebookUri).timeout(const Duration(seconds: 15));
    _check(response);
    final data = jsonDecode(response.body);
    return data is Map ? (data['url'] ?? '').toString().trim() : '';
  }

  Future<String> saveFacebookUrl(String url) async {
    final response = await http.post(
      _facebookUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    ).timeout(const Duration(seconds: 20));
    _check(response);
    final data = jsonDecode(response.body);
    return data is Map ? (data['url'] ?? '').toString().trim() : url;
  }

  Future<String> getYoutubeUrl() async {
    final response = await http.get(_youtubeUri).timeout(const Duration(seconds: 15));
    _check(response);
    final data = jsonDecode(response.body);
    return data is Map ? (data['url'] ?? '').toString().trim() : '';
  }

  Future<String> saveYoutubeUrl(String url) async {
    final response = await http.post(
      _youtubeUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    ).timeout(const Duration(seconds: 20));
    _check(response);
    final data = jsonDecode(response.body);
    return data is Map ? (data['url'] ?? '').toString().trim() : url;
  }

  Future<String> getInstagramUrl() async {
    final response = await http.get(_instagramUri).timeout(const Duration(seconds: 15));
    _check(response);
    final data = jsonDecode(response.body);
    return data is Map ? (data['url'] ?? '').toString().trim() : '';
  }

  Future<String> saveInstagramUrl(String url) async {
    final response = await http.post(
      _instagramUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    ).timeout(const Duration(seconds: 20));
    _check(response);
    final data = jsonDecode(response.body);
    return data is Map ? (data['url'] ?? '').toString().trim() : url;
  }

  Future<Map<String, String>> getWhatsappConfig() async {
    final response = await http.get(_whatsappUri).timeout(const Duration(seconds: 15));
    _check(response);
    final data = jsonDecode(response.body);
    if (data is! Map) return const {'phoneNumber': '', 'text': ''};
    return {'phoneNumber': (data['phoneNumber'] ?? '').toString(), 'text': (data['text'] ?? '').toString()};
  }

  Future<void> saveWhatsappConfig({required String phoneNumber, required String text}) async {
    final response = await http.post(
      _whatsappUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber, 'text': text}),
    ).timeout(const Duration(seconds: 20));
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'Request failed (${response.statusCode}).';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) message = data['message'].toString();
    } catch (_) {}
    throw Exception(message);
  }
}
