import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/school_news.dart';

class SchoolNewsService {
  SchoolNewsService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<SchoolNews>> getSchoolNews({bool onlyPublished = false}) async {
    final response = await http
        .get(_uri(onlyPublished ? '/api/schoolnews?published=true' : '/api/schoolnews'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .map((item) => SchoolNews.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<SchoolNews?> getSchoolNewsById(String id) async {
    final response = await http
        .get(_uri('/api/schoolnews/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    return SchoolNews.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<SchoolNews> create(SchoolNews item) async {
    final response = await http
        .post(
          _uri('/api/schoolnews'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': item.title,
            'date': item.date?.toIso8601String(),
            'news': item.news,
            'isPublished': item.isPublished,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    return SchoolNews.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<SchoolNews> update(String id, SchoolNews item) async {
    final response = await http
        .put(
          _uri('/api/schoolnews/${Uri.encodeComponent(id)}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': item.title,
            'date': item.date?.toIso8601String(),
            'news': item.news,
            'isPublished': item.isPublished,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    return SchoolNews.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<void> delete(String id) async {
    final response = await http
        .delete(_uri('/api/schoolnews/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
  }

  Future<SchoolNews> publish(String id, {required bool published}) async {
    final response = await http
        .patch(
          _uri('/api/schoolnews/${Uri.encodeComponent(id)}/publish'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'isPublished': published}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    return SchoolNews.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  String _messageBody(int statusCode, String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map && value['message'] != null) {
        return value['message'].toString();
      }
    } catch (_) {}
    return 'Request failed ($statusCode).';
  }
}
