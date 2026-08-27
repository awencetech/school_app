import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/staff_info.dart';

class StaffService {
  StaffService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<StaffInfo>> getStaff() async {
    final response = await http.get(_uri('/api/staff')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Unable to load staff information.');
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => StaffInfo.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<StaffInfo> createStaff(StaffInfo staff) async => _save('/api/staff', staff, create: true);

  Future<StaffInfo> updateStaff(StaffInfo staff) async {
    if (staff.id == null || staff.id!.isEmpty) throw Exception('Staff record ID is missing.');
    return _save('/api/staff/${Uri.encodeComponent(staff.id!)}', staff);
  }

  Future<StaffInfo> _save(String path, StaffInfo staff, {bool create = false}) async {
    final response = await (create ? http.post : http.put)(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(staff.toJson()),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != (create ? 201 : 200)) {
      final message = _message(response.statusCode, response.body);
      throw Exception(message);
    }
    return StaffInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteStaff(String id) async {
    final response = await http.delete(_uri('/api/staff/${Uri.encodeComponent(id)}')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception(_message(response.statusCode, response.body));
  }

  Future<String> uploadImage({required String fileName, required List<int> bytes}) async {
    final request = http.MultipartRequest('POST', _uri('/api/upload/staff-image'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) throw Exception(_message(response.statusCode, body));
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final url = payload['url']?.toString();
    if (url == null || url.isEmpty) throw Exception('Invalid staff image upload response.');
    return _normalizeUrl(url);
  }

  String _normalizeUrl(String url) => url
      .replaceAll('http://localhost:3001', _productionBaseUrl)
      .replaceAll('http://10.0.2.2:3001', _productionBaseUrl);

  String _message(int statusCode, String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] != null) return payload['message'].toString();
    } catch (_) {}
    final plainText = body.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plainText.isNotEmpty) {
      return 'Staff request failed ($statusCode): ${plainText.length > 180 ? '${plainText.substring(0, 180)}...' : plainText}';
    }
    return 'Staff request failed ($statusCode).';
  }
}
