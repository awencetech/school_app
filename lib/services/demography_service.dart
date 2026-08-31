import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/demography.dart';

class DemographyService {
  DemographyService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<Demography>> getDemographies() async {
    final response = await http
        .get(_uri('/api/demography'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const <Demography>[];
    return decoded
        .map((item) => Demography.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Demography>> getDemographiesByGroup(String groupId) async {
    final response = await http
        .get(_uri('/api/demography/group/${Uri.encodeComponent(groupId)}'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const <Demography>[];
    return decoded
        .map((item) => Demography.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Demography> createDemography(Demography item) async {
    final response = await http
        .post(
          _uri('/api/demography'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Demography.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<Demography> updateDemography(String id, Demography item) async {
    final response = await http
        .put(
          _uri('/api/demography/${Uri.encodeComponent(id)}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_messageBody(response.statusCode, response.body));
    }
    return Demography.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<void> deleteDemography(String id) async {
    final response = await http
        .delete(_uri('/api/demography/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 20));
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
