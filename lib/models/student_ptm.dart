class StudentPtm {
  const StudentPtm({
    required this.id,
    required this.title,
    required this.message,
    required this.className,
    required this.section,
    required this.date,
    required this.time,
    required this.venue,
    required this.instructions,
    required this.imageUrl,
    required this.status,
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String className;
  final String section;
  final String date;
  final String time;
  final String venue;
  final String instructions;
  final String imageUrl;
  final String status;
  final String createdBy;
  final DateTime? createdAt;

  String get classSection => [className, section]
      .where((value) => value.trim().isNotEmpty)
      .join('-');

  factory StudentPtm.fromJson(Map<String, dynamic> json) => StudentPtm(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? json['description'] ?? '').toString(),
        className: (json['className'] ?? '').toString(),
        section: (json['section'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        time: (json['time'] ?? '').toString(),
        venue: (json['venue'] ?? '').toString(),
        instructions: (json['instructions'] ?? '').toString(),
        imageUrl: (json['imageUrl'] ?? '').toString(),
        status: (json['status'] ?? 'Active').toString(),
        createdBy: (json['createdBy'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      );
}
