/// Sports achievement item used in the School Content Management System.
class SportsAchievementEntry {
  SportsAchievementEntry({
    required this.imageBase64,
    required this.studentName,
    required this.achievementTitle,
    required this.description,
  });

  final String imageBase64;
  final String studentName;
  final String achievementTitle;
  final String description;

  factory SportsAchievementEntry.fromJson(Map<String, dynamic> json) {
    return SportsAchievementEntry(
      imageBase64: json['imageBase64'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      achievementTitle: json['achievementTitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
      'studentName': studentName,
      'achievementTitle': achievementTitle,
      'description': description,
    };
  }
}
