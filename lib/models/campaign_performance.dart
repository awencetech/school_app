class CampaignPerformance {
  const CampaignPerformance({
    required this.totalStudents,
    required this.achievedStudents,
    required this.achievementPercentage,
    required this.classTestToppers,
    required this.monthlyTestToppers,
  });

  final int totalStudents;
  final int achievedStudents;
  final double achievementPercentage;
  final List<StudentPerformance> classTestToppers;
  final List<StudentPerformance> monthlyTestToppers;

  factory CampaignPerformance.fromJson(Map<String, dynamic> json) {
    List<StudentPerformance> readList(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) => StudentPerformance.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return CampaignPerformance(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      achievedStudents: (json['achievedStudents'] as num?)?.toInt() ?? 0,
      achievementPercentage: (json['achievementPercentage'] as num?)?.toDouble() ?? 0,
      classTestToppers: readList('classTestToppers'),
      monthlyTestToppers: readList('monthlyTestToppers'),
    );
  }
}

class StudentPerformance {
  const StudentPerformance({
    required this.name,
    required this.className,
    required this.photoUrl,
    required this.testName,
    required this.mark,
    required this.totalMark,
    required this.rank,
  });

  final String name;
  final String className;
  final String photoUrl;
  final String testName;
  final double mark;
  final double totalMark;
  final int rank;

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    return StudentPerformance(
      name: (json['name'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString(),
      testName: (json['testName'] ?? '').toString(),
      mark: (json['mark'] as num?)?.toDouble() ?? 0,
      totalMark: (json['totalMark'] as num?)?.toDouble() ?? 100,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
    );
  }
}
