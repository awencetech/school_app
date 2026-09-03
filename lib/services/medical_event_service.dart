import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/medical_event.dart';

class MedicalEventService {
  MedicalEventService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kReleaseMode || kIsWeb) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<MedicalEvent>> getAll() async {
    final response = await http.get(_uri('/api/medical-events')).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    final decoded = jsonDecode(response.body);
    final items = decoded is Map ? decoded['data'] : decoded;
    if (items is! List) return const [];
    return items.map((item) => MedicalEvent.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<MedicalEvent> getById(String id) async {
    final response = await http.get(_uri('/api/medical-events/${Uri.encodeComponent(id)}')).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    final decoded = jsonDecode(response.body);
    return MedicalEvent.fromJson(Map<String, dynamic>.from(decoded is Map && decoded['data'] is Map ? decoded['data'] : decoded));
  }

  Future<MedicalEvent> save(MedicalEvent event) async {
    final editing = event.id != null && event.id!.isNotEmpty;
    final response = await (editing
        ? http.put(_uri('/api/medical-events/${Uri.encodeComponent(event.id!)}'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(event.toJson()))
        : http.post(_uri('/api/medical-events'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(event.toJson())))
      .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception(_message(response));
    final decoded = jsonDecode(response.body);
    return MedicalEvent.fromJson(Map<String, dynamic>.from(decoded is Map && decoded['data'] is Map ? decoded['data'] : decoded));
  }

  Future<void> delete(String id) async {
    final response = await http.delete(_uri('/api/medical-events/${Uri.encodeComponent(id)}')).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  Future<String> uploadReport(String fileName, List<int> bytes) async {
    final request = http.MultipartRequest('POST', _uri('/api/upload/attachment'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final response = await http.Response.fromStream(await request.send()).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception(_message(response));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['url']?.toString() ?? '';
  }

  String _message(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) return body['message'].toString();
    } catch (_) {}
    return 'Medical event request failed (${response.statusCode}).';
  }
}
