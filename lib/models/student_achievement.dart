/// Student achievement model used in Grade X / Grade XII sections.
class StudentAchievement {
  const StudentAchievement({
    required this.name,
    required this.marks,
    this.imageUrl,
  });

  final String name;
  final String marks;
  final String? imageUrl;

  factory StudentAchievement.fromJson(Map<String, dynamic> json) {
    return StudentAchievement(
      name: json['name'] as String? ?? '',
      marks: json['marks'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

