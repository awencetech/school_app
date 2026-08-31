import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/event_celebration.dart';

class EventCelebrationService {
  EventCelebrationService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const schoolId = 'default-school';
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

  Future<List<EventCelebration>> getEvents() async {
    final response = await http
        .get(_uri('/api/events-celebration?schoolId=$schoolId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception(_message(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .map((item) => EventCelebration.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<EventCelebration?> getEvent(String id) async {
    final response = await http
        .get(_uri('/api/events-celebration/$id'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw Exception(_message(response));
    return EventCelebration.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<EventCelebration> create(EventCelebration item) async {
    final response = await http
        .post(
          _uri('/api/events-celebration'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response));
    }
    return EventCelebration.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<EventCelebration> update(String id, EventCelebration item) async {
    final response = await http
        .put(
          _uri('/api/events-celebration/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    return EventCelebration.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<void> delete(String id) async {
    final response = await http
        .delete(_uri('/api/events-celebration/$id'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_message(response));
    }
  }

  Future<String> uploadImage(List<int> bytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/upload/attachment'),
    );
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) throw Exception(_messageBody(response.statusCode, body));

    final url = (jsonDecode(body) as Map<String, dynamic>)['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('The uploaded image URL was missing.');
    }
    return url
        .replaceAll('http://localhost:3001', _productionBaseUrl)
        .replaceAll('http://10.0.2.2:3001', _productionBaseUrl);
  }

  String _message(http.Response response) => _messageBody(response.statusCode, response.body);

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
