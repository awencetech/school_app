import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student_ptm.dart';
import 'auth_headers.dart';

class StudentPtmService {
  StudentPtmService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<StudentPtm>> getPtms() async {
    final response = await http
        .get(_uri('/api/student-ptm'), headers: await AuthHeaders.bearer())
        .timeout(const Duration(seconds: 15));
    final payload = _decode(response);
    if (response.statusCode != 200 || payload is! Map || payload['success'] != true) {
      throw Exception(_message(payload, 'Unable to load PTMs.'));
    }
    final values = payload['data'];
    if (values is! List) return [];
    return values
        .whereType<Map>()
        .map((item) => StudentPtm.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> createPtm({
    required String title,
    required String message,
    required String className,
    required String section,
    required String date,
    required String time,
    required String venue,
    required String instructions,
    PlatformFile? image,
  }) async {
    var imageUrl = '';
    if (image != null) {
      final bytes = await image.readAsBytes();
      final request = http.MultipartRequest('POST', _uri('/api/upload/attachment'));
      request.headers.addAll(await AuthHeaders.bearer());
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));
      final upload = await http.Response.fromStream(await request.send())
          .timeout(const Duration(seconds: 30));
      final uploadPayload = _decode(upload);
      if (upload.statusCode < 200 || upload.statusCode >= 300 || uploadPayload is! Map) {
        throw Exception(_message(uploadPayload, 'Unable to upload PTM notice.'));
      }
      imageUrl = (uploadPayload['url'] ?? '').toString();
      if (imageUrl.isEmpty) throw Exception('Unable to upload PTM notice.');
    }

    final response = await http
        .post(
          _uri('/api/student-ptm'),
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'title': title,
            'message': message,
            'className': className,
            'section': section,
            'date': date,
            'time': time,
            'venue': venue,
            'instructions': instructions,
            'imageUrl': imageUrl,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final payload = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        payload is! Map || payload['success'] != true) {
      throw Exception(_message(payload, 'Unable to publish PTM.'));
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  String _message(dynamic payload, String fallback) {
    if (payload is Map && payload['message'] != null) {
      return payload['message'].toString();
    }
    return fallback;
  }
}
