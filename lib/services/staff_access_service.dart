import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/staff_access.dart';
import 'auth_headers.dart';

class StaffAccessService {
  StaffAccessService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb || kReleaseMode) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<StaffAccessRecord>> getAll() async {
    final response = await http
        .get(_uri('/api/stf-access'), headers: await AuthHeaders.bearer())
        .timeout(const Duration(seconds: 20));
    _check(response);
    final payload = jsonDecode(response.body);
    final values = payload is Map ? payload['data'] : payload;
    if (values is! List) return const [];
    return values
        .map((item) => StaffAccessRecord.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<StaffAccessRecord> get(String staffId) async {
    final response = await http
        .get(
          _uri('/api/stf-access/${Uri.encodeComponent(staffId)}'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 20));
    _check(response);
    return StaffAccessRecord.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<StaffAccessRecord> save({
    required String staffId,
    required List<String> accessGroups,
  }) async {
    final response = await http
        .put(
          _uri('/api/stf-access/${Uri.encodeComponent(staffId)}'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({'accessGroups': accessGroups}),
        )
        .timeout(const Duration(seconds: 20));
    _check(response);
    return StaffAccessRecord.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  void _check(http.Response response) {
    if (response.statusCode == 200) return;
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map && payload['message'] != null) {
        throw Exception(payload['message'].toString());
      }
    } catch (error) {
      if (error is FormatException) {
        // Some proxies return an HTML error page instead of JSON.
      } else {
        rethrow;
      }
    }
    throw Exception('Staff access request failed (${response.statusCode}).');
  }
}
