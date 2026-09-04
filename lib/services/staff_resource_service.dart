import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/staff_resource.dart';

class StaffResourceService {
  StaffResourceService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb || kReleaseMode) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<List<StaffResource>> getAll({String? staffId, String? token}) async {
    final query = staffId == null ? null : {'staffId': staffId};
    final response = await http.get(_uri('/api/staff-resources', query), headers: _headers(token)).timeout(const Duration(seconds: 20));
    _check(response);
    return _list(response.body);
  }

  Future<List<StaffResource>> getMyResources({required String token}) async {
    final response = await http.get(_uri('/api/staff-resources/my-resources'), headers: _headers(token)).timeout(const Duration(seconds: 20));
    _check(response);
    return _list(response.body);
  }

  Future<StaffResource> create(StaffResource resource, {String? token}) => _send('POST', '/api/staff-resources', resource, token: token);

  Future<StaffResource> update(StaffResource resource, {String? token}) {
    if (resource.id == null || resource.id!.isEmpty) throw Exception('Resource ID is missing.');
    return _send('PUT', '/api/staff-resources/${Uri.encodeComponent(resource.id!)}', resource, token: token);
  }

  Future<void> delete(String id, {String? token}) async {
    final response = await http.delete(_uri('/api/staff-resources/${Uri.encodeComponent(id)}'), headers: _headers(token)).timeout(const Duration(seconds: 20));
    _check(response);
  }

  Future<StaffResource> _send(String method, String path, StaffResource resource, {String? token}) async {
    final request = http.Request(method, _uri(path))
      ..headers.addAll(_headers(token))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(resource.toJson());
    final response = await http.Client().send(request).then(http.Response.fromStream);
    _check(response);
    return StaffResource.fromJson(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
  }

  Map<String, String> _headers(String? token) => token == null || token.trim().isEmpty
      ? {}
      : {'Authorization': 'Bearer ${token.trim()}'};

  List<StaffResource> _list(String body) {
    final data = jsonDecode(body);
    if (data is! List) return const [];
    return data.map((item) => StaffResource.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'Staff resource request failed (${response.statusCode}).';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) message = data['message'].toString();
    } catch (_) {}
    throw Exception(message);
  }
}
