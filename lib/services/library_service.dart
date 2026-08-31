import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/library_book.dart';

class LibraryService {
  LibraryService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<LibraryBook>> getBooks() async {
    final response = await http.get(_uri('/api/library')).timeout(const Duration(seconds: 20));
    _check(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded.map((item) => LibraryBook.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<LibraryBook> createBook(LibraryBook book) => _send('post', '/api/library', book);

  Future<LibraryBook> updateBook(String id, LibraryBook book) => _send('put', '/api/library/${Uri.encodeComponent(id)}', book);

  Future<void> deleteBook(String id) async {
    final response = await http.delete(_uri('/api/library/${Uri.encodeComponent(id)}')).timeout(const Duration(seconds: 20));
    _check(response);
  }

  Future<LibraryBook> _send(String method, String path, LibraryBook book) async {
    final request = http.Request(method, _uri(path))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(book.toJson());
    final response = await http.Client().send(request).then(http.Response.fromStream);
    _check(response);
    return LibraryBook.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Request failed (${response.statusCode}).';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) message = body['message'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }
}
