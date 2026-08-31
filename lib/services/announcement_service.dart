import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/announcement.dart';

class AnnouncementService {
  AnnouncementService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<Announcement>> getAnnouncements() async {
    final response = await http
        .get(_uri('/api/announcement'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .map((item) => Announcement.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Announcement?> getAnnouncement(String id) async {
    final response = await http
        .get(_uri('/api/announcement/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Announcement.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<Announcement> create(Announcement item) async {
    final response = await http
        .post(
          _uri('/api/announcement'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Announcement.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<Announcement> update(String id, Announcement item) async {
    final response = await http
        .put(
          _uri('/api/announcement/${Uri.encodeComponent(id)}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Announcement.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<void> delete(String id) async {
    final response = await http
        .delete(_uri('/api/announcement/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
  }

  Future<Map<String, dynamic>> toggleLike(String id, {required String userId}) async {
    final response = await http
        .post(
          _uri('/api/announcement/${Uri.encodeComponent(id)}/like'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> addComment(
    String id, {
    required String userId,
    required String userName,
    required String text,
  }) async {
    final response = await http
        .post(
          _uri('/api/announcement/${Uri.encodeComponent(id)}/comments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'userName': userName,
            'text': text,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> addReminder(String id, {required String userId}) async {
    final response = await http
        .post(
          _uri('/api/announcement/${Uri.encodeComponent(id)}/remind'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
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
