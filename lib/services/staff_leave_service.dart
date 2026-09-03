import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/staff_leave.dart';

class StaffLeaveService {
  StaffLeaveService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();
  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';
  static String _resolveBaseUrl() { const override = String.fromEnvironment('API_BASE_URL', defaultValue: ''); if (override.isNotEmpty) return override; if (kReleaseMode || kIsWeb) return _productionBaseUrl; if (Platform.isAndroid) return 'http://10.0.2.2:3001'; return 'http://localhost:3001'; }
  Uri _uri(String path) => Uri.parse('$_baseUrl$path');
  Future<List<StaffLeaveRequest>> requests(String staffId) async { final response = await http.get(_uri('/api/staff-leave/${Uri.encodeComponent(staffId)}')).timeout(const Duration(seconds: 20)); if (response.statusCode != 200) throw Exception(_message(response)); return _list(response).map(StaffLeaveRequest.fromJson).toList(); }
  Future<List<StaffLeaveEntitlement>> entitlements(String staffId, int year) async { final response = await http.get(_uri('/api/staff-leave/${Uri.encodeComponent(staffId)}/entitlements?year=$year')).timeout(const Duration(seconds: 20)); if (response.statusCode != 200) throw Exception(_message(response)); return _list(response).map(StaffLeaveEntitlement.fromJson).toList(); }
  Future<void> submit(Map<String, dynamic> payload) async { final response = await http.post(_uri('/api/staff-leave'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload)).timeout(const Duration(seconds: 20)); if (response.statusCode != 201) throw Exception(_message(response)); }
  Future<void> adjust(Map<String, dynamic> payload) async { final response = await http.post(_uri('/api/staff-leave/adjust'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload)).timeout(const Duration(seconds: 20)); if (response.statusCode != 200) throw Exception(_message(response)); }
  Future<void> cancel(String id) async { final response = await http.put(_uri('/api/staff-leave/${Uri.encodeComponent(id)}/cancel')).timeout(const Duration(seconds: 20)); if (response.statusCode != 200) throw Exception(_message(response)); }
  List<Map<String, dynamic>> _list(http.Response response) { final decoded = jsonDecode(response.body); final value = decoded is Map ? decoded['data'] : decoded; return value is List ? value.map((item) => Map<String, dynamic>.from(item as Map)).toList() : const []; }
  String _message(http.Response response) { try { final value = jsonDecode(response.body); if (value is Map && value['message'] != null) return value['message'].toString(); } catch (_) {} return 'Leave request failed (${response.statusCode}).'; }
}
