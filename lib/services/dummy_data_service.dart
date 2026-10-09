import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/news_item.dart';
import '../models/school_info.dart';
import '../models/staff_member.dart';
import '../models/student_achievement.dart';

/// Loads optional school content from bundled JSON assets.
class DummyDataService {
  DummyDataService._();

  static Future<SchoolInfo>? _schoolInfoFuture;

  static Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<SchoolInfo> getSchoolInfo() async {
    return _schoolInfoFuture ??= _loadSchoolInfo();
  }

  static Future<SchoolInfo> _loadSchoolInfo() async {
    try {
      final json = await _loadJson('assets/data/school.json');
      return SchoolInfo.fromJson(json);
    } catch (error) {
      debugPrint('Unable to load school information: $error');
      return const SchoolInfo(
        name: '',
        since: '',
        motto: '',
        quote: '',
        websiteUrl: '',
      );
    }
  }

  static Future<List<NewsItem>> getNews() async {
    try {
      final json = await _loadJson('assets/data/news.json');
      final items = (json['items'] as List<dynamic>? ?? const []);
      return items
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<StaffMember>> getLeadership() async {
    try {
      final json = await _loadJson('assets/data/staff.json');
      final items = (json['leadership'] as List<dynamic>? ?? const []);
      final staff = items
          .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return staff;
    } catch (error) {
      debugPrint('Unable to load school leadership: $error');
      return const [];
    }
  }

  static Future<List<StudentAchievement>> getGradeX() async {
    try {
      final json = await _loadJson('assets/data/achievements.json');
      final items = (json['gradeX'] as List<dynamic>? ?? const []);
      final gradeX = items
          .map((e) => StudentAchievement.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return gradeX;
    } catch (error) {
      debugPrint('Unable to load Grade X achievements: $error');
      return const [];
    }
  }

  static Future<List<StudentAchievement>> getGradeXII() async {
    try {
      final json = await _loadJson('assets/data/achievements.json');
      final items = (json['gradeXII'] as List<dynamic>? ?? const []);
      final gradeXII = items
          .map((e) => StudentAchievement.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return gradeXII;
    } catch (error) {
      debugPrint('Unable to load Grade XII achievements: $error');
      return const [];
    }
  }
}
