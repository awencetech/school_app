import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/news_item.dart';
import '../models/school_info.dart';
import '../models/staff_member.dart';
import '../models/student_achievement.dart';

/// Loads dummy JSON from assets so it can be replaced by API responses later.
class DummyDataService {
  DummyDataService._();

  static const List<StaffMember> fallbackLeadership = [
    StaffMember(
      name: 'Founder',
      designation: '(Founder)',
      heading: 'Vision And Mission of our Founder',
      description:
          'School App is designed to provide effective communication and information to parents and students. Our vision is to create an environment that motivates every learner to achieve excellence with discipline and values.',
      image: '',
      imageOnLeft: true,
    ),
    StaffMember(
      name: 'Chairman',
      designation: '(Chairman)',
      heading: 'Leadership Message',
      description:
          'We believe in holistic education that balances academics, sports, arts, and life skills. The school focuses on character building, leadership, and responsibility through continuous guidance and supportive mentorship.',
      image: '',
      imageOnLeft: true,
    ),
    StaffMember(
      name: 'Secretary',
      designation: '(Secretary)',
      heading: 'Warm Welcome',
      description:
          'We are delighted that you are considering our school for your child’s future. We encourage a learning culture that is caring, structured, and academically strong.',
      image: '',
      imageOnLeft: false,
    ),
    StaffMember(
      name: 'Principal',
      designation: '(Principal)',
      heading: 'Principal’s Note',
      description:
          'Our goal is to provide a balanced learning experience that develops knowledge, discipline, creativity, and empathy. We encourage students to participate in sports, arts, and community activities.',
      image: '',
      imageOnLeft: false,
    ),
  ];

  static const List<StudentAchievement> fallbackGradeX = [
    StudentAchievement(name: 'Student A', marks: '495/500'),
    StudentAchievement(name: 'Student B', marks: '489/500'),
    StudentAchievement(name: 'Student C', marks: '487/500'),
  ];

  static const List<StudentAchievement> fallbackGradeXII = [
    StudentAchievement(name: 'Student D', marks: '1180/1200'),
    StudentAchievement(name: 'Student E', marks: '1165/1200'),
    StudentAchievement(name: 'Student F', marks: '1158/1200'),
  ];

  static Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<SchoolInfo> getSchoolInfo() async {
    try {
      final json = await _loadJson('assets/data/school.json');
      return SchoolInfo.fromJson(json);
    } catch (_) {
      return const SchoolInfo(
        name: 'SCHOOL NAME',
        since: '1987',
        motto: 'Knowledge, Discipline, Excellence',
        quote:
            'Every student has the potential to achieve greatness through dedication, discipline, and continuous learning.',
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
      return staff.isEmpty ? fallbackLeadership : staff;
    } catch (_) {
      return fallbackLeadership;
    }
  }

  static Future<List<StudentAchievement>> getGradeX() async {
    try {
      final json = await _loadJson('assets/data/achievements.json');
      final items = (json['gradeX'] as List<dynamic>? ?? const []);
      final gradeX = items
          .map((e) => StudentAchievement.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return gradeX.isEmpty ? fallbackGradeX : gradeX;
    } catch (_) {
      return fallbackGradeX;
    }
  }

  static Future<List<StudentAchievement>> getGradeXII() async {
    try {
      final json = await _loadJson('assets/data/achievements.json');
      final items = (json['gradeXII'] as List<dynamic>? ?? const []);
      final gradeXII = items
          .map((e) => StudentAchievement.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return gradeXII.isEmpty ? fallbackGradeXII : gradeXII;
    } catch (_) {
      return fallbackGradeXII;
    }
  }
}

