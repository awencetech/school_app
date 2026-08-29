import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/group_message.dart';
import 'group_service.dart';

class GroupMessageService {
  GroupMessageService({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;
  static const _productionBaseUrl = 'https://school-app-1uep.onrender.com';

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb || kReleaseMode) return _productionBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<List<GroupMessage>> getMessages(String groupId) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to load messages.', uri.toString());
    }
    final payload = jsonDecode(response.body);
    final items = payload is List
        ? payload
        : payload is Map && payload['data'] is List
            ? payload['data'] as List
            : const <dynamic>[];
    return items
        .map((item) => GroupMessage.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<GroupMessage> createMessage({
    required String groupId,
    required String groupName,
    required String messageType,
    required String message,
    required String senderId,
    required String senderName,
    required String senderRole,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'groupId': groupId,
        'groupName': groupName,
        'category': messageType,
        'title': messageType,
        'content': message,
        'message': message,
        'authorId': senderId,
        'senderId': senderId,
        'authorRole': senderRole,
        'senderRole': senderRole,
        'senderName': senderName,
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _errorMessage(response.body), uri.toString());
    }
    return GroupMessage.fromJson(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
  }

  Future<Map<String, dynamic>> toggleLike({
    required String groupId,
    required String messageId,
    required String userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages/${Uri.encodeComponent(messageId)}/like');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to update like.', uri.toString());
    }
    final payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    throw ApiException(response.statusCode, 'Invalid like response.', uri.toString());
  }

  Future<List<GroupMessageComment>> getComments({
    required String groupId,
    required String messageId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages/${Uri.encodeComponent(messageId)}/comments');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Unable to load comments.', uri.toString());
    }
    final payload = jsonDecode(response.body);
    final items = payload is List
        ? payload
        : payload is Map && payload['data'] is List
            ? payload['data'] as List
            : const <dynamic>[];
    return items
        .map((item) => GroupMessageComment.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<GroupMessageComment> addComment({
    required String groupId,
    required String messageId,
    required String userId,
    required String userRole,
    required String studentName,
    required String comment,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages/${Uri.encodeComponent(messageId)}/comments');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'userRole': userRole,
        'studentId': userId,
        'studentName': studentName,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _errorMessage(response.body), uri.toString());
    }
    final payload = jsonDecode(response.body);
    if (payload is Map) return GroupMessageComment.fromJson(Map<String, dynamic>.from(payload));
    throw ApiException(response.statusCode, 'Invalid comment response.', uri.toString());
  }

  Future<GroupMessageComment> updateComment({
    required String groupId,
    required String messageId,
    required String commentId,
    required String userId,
    required String userRole,
    required String comment,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages/${Uri.encodeComponent(messageId)}/comments/${Uri.encodeComponent(commentId)}');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'userRole': userRole,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _errorMessage(response.body), uri.toString());
    }
    final payload = jsonDecode(response.body);
    if (payload is Map) return GroupMessageComment.fromJson(Map<String, dynamic>.from(payload));
    throw ApiException(response.statusCode, 'Invalid comment response.', uri.toString());
  }

  Future<void> deleteComment({
    required String groupId,
    required String messageId,
    required String commentId,
    required String userId,
    required String userRole,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages/${Uri.encodeComponent(messageId)}/comments/${Uri.encodeComponent(commentId)}');
    final response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'userRole': userRole}),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Unable to delete comment.', uri.toString());
    }
  }

  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/groups/${Uri.encodeComponent(groupId)}/messages/${Uri.encodeComponent(messageId)}');
    final response = await http.delete(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Unable to delete message.', uri.toString());
    }
  }

  String _errorMessage(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map && payload['message'] is String) return payload['message'] as String;
    } catch (_) {}
    return 'Unable to save message.';
  }
}
