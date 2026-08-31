import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/school_resource.dart';

class SchoolResourceService {
  SchoolResourceService({String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<SchoolResource>> getResources() async {
    final response = await http
        .get(_uri('/api/school-resources'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .map((item) => SchoolResource.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<SchoolResource?> getResourceById(String id) async {
    final response = await http
        .get(_uri('/api/school-resources/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    return SchoolResource.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<SchoolResource> createResource(SchoolResource item) async {
    final response = await http
        .post(
          _uri('/api/school-resources'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return SchoolResource.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<SchoolResource> updateResource(String id, SchoolResource item) async {
    final response = await http
        .put(
          _uri('/api/school-resources/${Uri.encodeComponent(id)}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return SchoolResource.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body)),
    );
  }

  Future<void> deleteResource(String id) async {
    final response = await http
        .delete(_uri('/api/school-resources/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
  }

  String _messageBody(int statusCode, String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] != null) {
        return payload['message'].toString();
      }
    } catch (_) {}
    return 'Request failed ($statusCode).';
  }
}
