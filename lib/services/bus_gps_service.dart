import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/bus_gps.dart';

class BusGpsService {
  BusGpsService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<List<BusGps>> getAll() async {
    final response = await http
        .get(_uri('/api/bus-gps'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    final decoded = jsonDecode(response.body);
    final items = decoded is Map ? decoded['data'] : decoded;
    if (items is! List) return const [];
    return items
        .map((item) => BusGps.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<BusGps> save(BusGps route) async {
    final editing = route.id != null && route.id!.isNotEmpty;
    final response =
        await (editing
                ? http.put(
                    _uri('/api/bus-gps/${Uri.encodeComponent(route.id!)}'),
                    headers: _headers,
                    body: jsonEncode(route.toJson()),
                  )
                : http.post(
                    _uri('/api/bus-gps'),
                    headers: _headers,
                    body: jsonEncode(route.toJson()),
                  ))
            .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response));
    }
    return BusGps.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<void> delete(String id) async {
    final response = await http
        .delete(_uri('/api/bus-gps/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  Future<BusGps> updateGpsStatus(String id, String gpsStatus) async {
    final response = await http
        .patch(
          _uri('/api/bus-gps/${Uri.encodeComponent(id)}/gps-status'),
          headers: _headers,
          body: jsonEncode({'gpsStatus': gpsStatus}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception(_message(response));
    return BusGps.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  String _message(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return 'Bus route request failed (${response.statusCode}).';
  }
}
