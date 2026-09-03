import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class UserService {
  UserService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return _productionBaseUrl;
    if (kReleaseMode) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<User>> getUsers({String? role}) async {
    final uri = role == null ? _uri('/api/users') : _uri('/api/users?role=$role');
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('Failed to load users: ${resp.statusCode}');
    final payload = jsonDecode(resp.body) as List<dynamic>;
    return payload.map((e) => User.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<User> createUser({required String userId, required String email, required String password, required String role}) async {
    final uri = _uri('/api/users');
    final resp = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'email': email, 'password': password, 'role': role}),
    )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 201) {
      // Try to produce a clearer error message when the server returns HTML or non-JSON.
      final contentType = resp.headers['content-type'] ?? '';
      String bodySnippet = '';
      try {
        if (contentType.contains('application/json')) {
          final decoded = jsonDecode(resp.body);
          bodySnippet = jsonEncode(decoded);
        } else {
          bodySnippet = resp.body.length > 300 ? '${resp.body.substring(0, 300)}...' : resp.body;
        }
      } catch (_) {
        bodySnippet = resp.body.length > 300 ? '${resp.body.substring(0, 300)}...' : resp.body;
      }

      // If the response is JSON and contains a message, surface it via ApiException.
      if (contentType.contains('application/json')) {
        try {
          final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
          final msg = decoded['message']?.toString() ?? bodySnippet;
          throw ApiException(resp.statusCode, msg, uri.toString());
        } catch (_) {
          throw ApiException(resp.statusCode, bodySnippet, uri.toString());
        }
      }

      throw ApiException(resp.statusCode, bodySnippet, uri.toString());
    }

    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return User.fromJson(payload);
  }

  Future<User> login({required String identifier, required String password}) async {
    final uri = _uri('/api/login');
    final resp = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      // Avoid revealing whether user exists
      throw ApiException(resp.statusCode, 'Invalid email or password', uri.toString());
    }

    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    // Support either {user: {...}} or direct user object
    final userPayload = Map<String, dynamic>.from((payload['user'] ?? payload) as Map);
    userPayload['token'] = payload['token'];
    return User.fromJson(userPayload);
  }

  Future<User> getUserById(String id) async {
    final resp = await http.get(_uri('/api/users/$id')).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Failed to load user: ${resp.body}');
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return User.fromJson(payload);
  }

  Future<User> updateUser(String id, {String? email, String? password}) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    final resp = await http.put(
      _uri('/api/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) throw Exception('Failed to update user: ${resp.body}');
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    return User.fromJson(payload);
  }

  Future<void> deleteUser(String id) async {
    final resp = await http.delete(_uri('/api/users/$id')).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Failed to delete user: ${resp.body}');
  }

}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String uri;

  ApiException(this.statusCode, this.message, this.uri);

  @override
  String toString() => 'ApiException: $statusCode $message at $uri';
}
