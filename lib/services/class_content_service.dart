import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/class_news.dart';
import '../models/class_photo.dart';
import 'auth_headers.dart';

class ClassContentService {
  ClassContentService({String? baseUrl})
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

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  // ===================== PHOTOS =====================

  Future<List<ClassPhoto>> getPhotosForGroup(String groupId) async {
    try {
      final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/photos');
      debugPrint('ClassContentService: Fetching photos from $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('ClassContentService: Photos response status ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          'Unable to load class photos (${response.statusCode}).',
          uri.toString(),
        );
      }

      final payload = jsonDecode(response.body);
      final rawPhotos = switch (payload) {
        List<dynamic> list => list,
        Map<String, dynamic> map when map['photos'] is List =>
          map['photos'] as List<dynamic>,
        Map<String, dynamic> map when map['data'] is List =>
          map['data'] as List<dynamic>,
        _ => <dynamic>[],
      };

      debugPrint('ClassContentService: Parsed ${rawPhotos.length} photos');
      return rawPhotos.map((item) {
        if (item is! Map) {
          throw const FormatException('Photo response item is invalid.');
        }
        return ClassPhoto.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } catch (e) {
      debugPrint('Error fetching photos: $e');
      rethrow;
    }
  }

  Future<ClassPhoto> uploadPhoto(String groupId, String fileName, List<int> bytes, {String caption = '', String uploadedBy = ''}) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        _uri('/api/groups/${Uri.encodeComponent(groupId)}/photos'),
      );
      request.headers.addAll(await AuthHeaders.bearer());
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      request.fields['caption'] = caption;
      if (uploadedBy.isNotEmpty) request.fields['uploadedBy'] = uploadedBy;

      final response = await request.send().timeout(const Duration(seconds: 30));
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(body),
          'POST /api/groups/$groupId/photos',
        );
      }

      return ClassPhoto.fromJson(Map<String, dynamic>.from(jsonDecode(body)));
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }

  Future<ClassPhoto> updatePhotoCaption(String groupId, String photoId, String newCaption) async {
    try {
      final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/photos/${Uri.encodeComponent(photoId)}');
      final response = await http.put(
        uri,
        headers: await AuthHeaders.json(),
        body: jsonEncode({'caption': newCaption}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(response.body),
          uri.toString(),
        );
      }

      return ClassPhoto.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
    } catch (e) {
      debugPrint('Error updating photo caption: $e');
      rethrow;
    }
  }

  Future<void> deletePhoto(String groupId, String photoId) async {
    try {
      final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/photos/${Uri.encodeComponent(photoId)}');
      final response = await http.delete(uri, headers: await AuthHeaders.bearer()).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          response.statusCode,
          'Unable to delete photo.',
          uri.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      rethrow;
    }
  }

  // ===================== NEWS =====================

  Future<List<ClassNews>> getNewsForGroup(String groupId) async {
    try {
      final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/news');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          'Unable to load class news (${response.statusCode}).',
          uri.toString(),
        );
      }

      final payload = jsonDecode(response.body);
      final rawNews = switch (payload) {
        List<dynamic> list => list,
        Map<String, dynamic> map when map['news'] is List =>
          map['news'] as List<dynamic>,
        Map<String, dynamic> map when map['data'] is List =>
          map['data'] as List<dynamic>,
        _ => <dynamic>[],
      };

      return rawNews.map((item) {
        if (item is! Map) {
          throw const FormatException('News response item is invalid.');
        }
        return ClassNews.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } catch (e) {
      debugPrint('Error fetching news: $e');
      rethrow;
    }
  }

  Future<ClassNews> createNews(String groupId, ClassNews news, {String publishedBy = ''}) async {
    try {
      final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/news');
      final response = await http.post(
        uri,
        headers: await AuthHeaders.json(),
        body: jsonEncode({...news.toJson(), if (publishedBy.isNotEmpty) 'publishedBy': publishedBy}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(response.body),
          uri.toString(),
        );
      }

      return ClassNews.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
    } catch (e) {
      debugPrint('Error creating news: $e');
      rethrow;
    }
  }

  Future<ClassNews> updateNews(String groupId, ClassNews news) async {
    try {
      final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/news/${Uri.encodeComponent(news.id)}');
      final response = await http.put(
        uri,
        headers: await AuthHeaders.json(),
        body: jsonEncode(news.toJson()),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(response.body),
          uri.toString(),
        );
      }

      return ClassNews.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
    } catch (e) {
      debugPrint('Error updating news: $e');
      rethrow;
    }
  }

  Future<void> deleteNews(String groupId, String newsId) async {
    try {
      final uri = _uri('/api/groups/${Uri.encodeComponent(groupId)}/news/${Uri.encodeComponent(newsId)}');
      final response = await http.delete(uri, headers: await AuthHeaders.bearer()).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          response.statusCode,
          'Unable to delete news.',
          uri.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error deleting news: $e');
      rethrow;
    }
  }

  Future<String> uploadNewsImage(String fileName, List<int> bytes) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/api/upload/attachment'));
      request.headers.addAll(await AuthHeaders.bearer());
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final response = await request.send().timeout(const Duration(seconds: 30));
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          _extractErrorMessage(body),
          'POST /api/upload/attachment',
        );
      }

      final url = (jsonDecode(body) as Map<String, dynamic>)['url']?.toString();
      if (url == null || url.isEmpty) {
        throw const FormatException('The uploaded image URL was missing.');
      }
      return url
          .replaceAll('http://localhost:3001', _productionBaseUrl)
          .replaceAll('http://10.0.2.2:3001', _productionBaseUrl);
    } catch (e) {
      debugPrint('Error uploading news image: $e');
      rethrow;
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic> && payload['message'] is String) {
        final message = (payload['message'] as String).trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {}
    return body.trim().isEmpty ? 'Unable to complete the request.' : body.trim();
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message, this.url);

  final int statusCode;
  final String message;
  final String url;

  @override
  String toString() => 'ApiException($statusCode): $message at $url';
}
