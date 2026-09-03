import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/group_event.dart';
import 'group_service.dart';
import 'auth_headers.dart';

class GroupEventService {
  GroupEventService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb || kReleaseMode) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<List<GroupEvent>> getEventsForGroup(String groupId) async {
    final uri = Uri.parse(
      '$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/events',
    );
    debugPrint('Future Event Calendar groupId: $groupId');
    debugPrint('Future Event Calendar URL: $uri');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    debugPrint('Event API status: ${response.statusCode}');
    debugPrint('Event API response: ${response.body}');
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Unable to load group events (${response.statusCode}).',
        uri.toString(),
      );
    }

    final payload = jsonDecode(response.body);
    final rawEvents = switch (payload) {
      List<dynamic> list => list,
      Map<String, dynamic> map when map['events'] is List =>
        map['events'] as List<dynamic>,
      Map<String, dynamic> map when map['data'] is List =>
        map['data'] as List<dynamic>,
      _ => <dynamic>[],
    };

    return rawEvents.map((item) {
      if (item is! Map) {
        throw const FormatException('Event response item is invalid.');
      }
      return GroupEvent.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<GroupEvent> createEvent(GroupEvent event) async {
    final uri = Uri.parse(
      '$_baseUrl/api/groups/${Uri.encodeComponent(event.groupId)}/events',
    );
    return _sendEventRequest(uri, 'POST', event.toJson(), 201);
  }

  Future<GroupEvent> updateEvent(GroupEvent event) async {
    final uri = Uri.parse(
      '$_baseUrl/api/groups/${Uri.encodeComponent(event.groupId)}/events/${Uri.encodeComponent(event.id)}',
    );
    return _sendEventRequest(uri, 'PUT', event.toJson(), 200);
  }

  Future<void> deleteEvent(GroupEvent event) async {
    final uri = Uri.parse(
      '$_baseUrl/api/groups/${Uri.encodeComponent(event.groupId)}/events/${Uri.encodeComponent(event.id)}',
    );
    final response = await http.delete(uri, headers: await AuthHeaders.bearer()).timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Unable to delete event.', uri.toString());
    }
  }

  Future<GroupEvent> _sendEventRequest(
    Uri uri,
    String method,
    Map<String, dynamic> body,
    int expectedStatus,
  ) async {
    final encodedBody = jsonEncode(body);
    final response = method == 'POST'
        ? await http.post(uri, headers: await AuthHeaders.json(), body: encodedBody)
            .timeout(const Duration(seconds: 15))
        : await http.put(uri, headers: await AuthHeaders.json(), body: encodedBody)
            .timeout(const Duration(seconds: 15));
    if (response.statusCode != expectedStatus) {
      throw ApiException(
        response.statusCode,
        _errorMessage(response.body),
        uri.toString(),
      );
    }
    return GroupEvent.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  String _errorMessage(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic> && payload['message'] is String) {
        final message = (payload['message'] as String).trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {}
    return body.trim().isEmpty ? 'Unable to save event.' : body.trim();
  }
}
