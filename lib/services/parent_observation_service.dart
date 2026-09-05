import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/parent_observation.dart';
import 'auth_headers.dart';
import 'group_service.dart';

class ParentObservationService {
  ParentObservationService({String? baseUrl})
    : _baseUrl = baseUrl ?? _resolveBaseUrl();

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

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<List<ParentObservation>> getForGroupDate({
    required String groupId,
    required String date,
  }) async {
    final uri = _uri('/api/diary', {'groupId': groupId, 'date': date});
    final response = await http
        .get(uri, headers: await AuthHeaders.bearer())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = jsonDecode(response.body);
    final list = payload is Map && payload['data'] is List
        ? payload['data'] as List
        : payload is List
        ? payload
        : const <dynamic>[];
    return list
        .whereType<Map>()
        .map(
          (item) => ParentObservation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<ParentObservation?> getForContext({
    required String studentId,
    required String groupId,
    required String date,
  }) async {
    final records = await getForGroupDate(groupId: groupId, date: date);
    for (final record in records) {
      if (record.studentId == studentId) return record;
    }
    return null;
  }

  Future<ParentObservation?> getForStudentDate({required String date}) async {
    final uri = _uri('/api/diary/student', {'date': date});
    final response = await http
        .get(uri, headers: await AuthHeaders.bearer())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = jsonDecode(response.body);
    final records = payload is Map && payload['data'] is List
        ? payload['data'] as List
        : const <dynamic>[];
    if (records.isEmpty) return null;
    return ParentObservation.fromJson(
      Map<String, dynamic>.from(records.first as Map),
    );
  }

  Future<ParentObservation> getById(String id) async {
    final uri = _uri('/api/diary/${Uri.encodeComponent(id)}');
    final response = await http
        .get(uri, headers: await AuthHeaders.bearer())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return ParentObservation.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<ParentObservation> save(ParentObservation observation) async {
    final uri = _uri('/api/diary');
    final body = {
      'studentId': observation.studentId,
      'studentName': observation.studentName,
      'groupId': observation.groupId,
      'classId': observation.groupId,
      'date': observation.date,
      'diaryDate': observation.date,
      'diaryId': observation.diaryId,
      'parentObservation': {
        'wentToBedAt': observation.wentToBedAt,
        'gotUpAt': observation.gotUpAt,
        'brushedTeeth': observation.brushedTeeth,
        'didYoga': observation.didYoga,
        'breakfast': observation.breakfast,
        'homework': observation.homework,
        'assignmentCompletion': observation.assignmentCompletion,
        'helpfulAtHome': observation.helpfulAtHome,
        'respectfulToElders': observation.respectfulToElders,
        'parentsRemark': observation.parentsRemark,
      },
    };
    final response = await http
        .post(uri, headers: await AuthHeaders.json(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return ParentObservation.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<ParentObservation> saveStudentObservation({
    required String studentId,
    required String studentName,
    required String diaryId,
    required String classId,
    required String groupId,
    required String date,
    required String mood,
  }) async {
    final uri = _uri('/api/diary/student-observation');
    final response = await http
        .post(
          uri,
          headers: await AuthHeaders.json(),
          body: jsonEncode({
            'studentId': studentId,
            'studentName': studentName,
            'diaryId': diaryId,
            'classId': classId,
            'groupId': groupId,
            'date': date,
            'mood': mood,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return ParentObservation.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<ParentObservation> updateDiarySections({
    required String studentId,
    required String studentName,
    required String groupId,
    required String date,
    Map<String, dynamic>? teacherObservation,
    Map<String, dynamic>? subjectFeedback,
    String? gkScore,
    String? area,
    String? status,
    String? diaryDetails,
  }) async {
    final uri = _uri('/api/diary');
    final body = <String, dynamic>{
      'studentId': studentId,
      'studentName': studentName,
      'groupId': groupId,
      'date': date,
      if (teacherObservation != null) 'teacherObservation': teacherObservation,
      if (subjectFeedback != null) 'subjectFeedback': subjectFeedback,
      if (gkScore != null) 'gkScore': gkScore,
      if (area != null) 'area': area,
      if (status != null) 'status': status,
      if (diaryDetails != null) 'diaryDetails': diaryDetails,
    };
    final response = await http
        .post(uri, headers: await AuthHeaders.json(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return ParentObservation.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<ParentObservation> saveCompleteDiary({
    required String studentId,
    required String studentName,
    required String groupId,
    required String date,
    required String area,
    required String status,
    required String diaryDetails,
    required String wentToBedAt,
    required String gotUpAt,
    required Map<String, String> parentValues,
    required String parentsRemark,
    required String mood,
    required Map<String, dynamic> teacherObservation,
    required Map<String, dynamic> subjectFeedback,
    required String gkScore,
  }) async {
    final uri = _uri('/api/diary');
    final body = {
      'studentId': studentId,
      'studentName': studentName,
      'groupId': groupId,
      'classId': groupId,
      'date': date,
      'diaryDate': date,
      'area': area,
      'status': status,
      'diaryDetails': diaryDetails,
      'parentObservation': {
        'wentToBedAt': wentToBedAt,
        'gotUpAt': gotUpAt,
        ...parentValues,
        'parentsRemark': parentsRemark,
      },
      'studentObservation': {'mood': mood},
      'teacherObservation': teacherObservation,
      'subjectFeedback': subjectFeedback,
      'gkScore': gkScore,
    };
    final response = await http
        .post(uri, headers: await AuthHeaders.json(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return ParentObservation.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<ParentObservation> getStudentObservationById(String id) async {
    final uri = _uri(
      '/api/diary/student-observation/${Uri.encodeComponent(id)}',
    );
    final response = await http
        .get(uri, headers: await AuthHeaders.bearer())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        _message(response.body),
        uri.toString(),
      );
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return ParentObservation.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  String _message(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] is String) {
        return payload['message'] as String;
      }
    } catch (_) {}
    return 'Unable to load parent observations.';
  }
}
