import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/campaign_performance.dart';
import 'auth_headers.dart';

class CampaignPerformanceService {
  CampaignPerformanceService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Future<CampaignPerformance> getPerformance() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/campaign-performance'),
          headers: await AuthHeaders.bearer(),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Unable to load class performance.');
    }
    final payload = jsonDecode(response.body);
    final data = payload is Map ? payload['data'] : payload;
    if (data is! Map) throw Exception('Invalid performance response.');
    return CampaignPerformance.fromJson(Map<String, dynamic>.from(data));
  }
}
