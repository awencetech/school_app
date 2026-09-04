import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/one_on_one_meeting.dart';

class OneOnOneMeetingService {
  OneOnOneMeetingService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();

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
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<List<OneOnOneMeeting>> getAllForStaff(String staffId) async {
    final response = await http
        .get(
          _uri(
            '/api/one-on-one-meetings/staff/${Uri.encodeComponent(staffId)}',
          ),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    final decoded = jsonDecode(response.body);
    final items = decoded is Map ? decoded['data'] : decoded;
    if (items is! List) return const [];
    return items
        .map(
          (item) =>
              OneOnOneMeeting.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<OneOnOneMeeting>> getMyMeetings({required String token}) async {
    final response = await http
        .get(
          _uri('/api/one-on-one-meetings/my-meetings'),
          headers: {'Authorization': 'Bearer ${token.trim()}'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    final decoded = jsonDecode(response.body);
    final items = decoded is Map ? decoded['data'] : decoded;
    if (items is! List) return const [];
    return items
        .map(
          (item) => OneOnOneMeeting.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<OneOnOneMeeting> save(OneOnOneMeeting meeting) async {
    final editing = meeting.id != null && meeting.id!.isNotEmpty;
    final response =
        await (editing
                ? http.put(
                    _uri(
                      '/api/one-on-one-meetings/${Uri.encodeComponent(meeting.id!)}',
                    ),
                    headers: _headers,
                    body: jsonEncode(meeting.toJson()),
                  )
                : http.post(
                    _uri('/api/one-on-one-meetings'),
                    headers: _headers,
                    body: jsonEncode(meeting.toJson()),
                  ))
            .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response));
    }
    final decoded = jsonDecode(response.body);
    return OneOnOneMeeting.fromJson(
      Map<String, dynamic>.from(
        decoded is Map && decoded['data'] is Map
            ? decoded['data']
            : decoded as Map,
      ),
    );
  }

  Future<void> delete(String id) async {
    final response = await http
        .delete(_uri('/api/one-on-one-meetings/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  String _message(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return 'Meeting request failed (${response.statusCode}).';
  }
}
