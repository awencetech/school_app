class StudentCampaign {
  const StudentCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.className,
    required this.startDate,
    required this.endDate,
    required this.instructions,
    required this.imageUrl,
    required this.status,
    required this.createdBy,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String className;
  final DateTime? startDate;
  final DateTime? endDate;
  final String instructions;
  final String imageUrl;
  final String status;
  final String createdBy;

  factory StudentCampaign.fromJson(Map<String, dynamic> json) => StudentCampaign(
    id: (json['id'] ?? json['_id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    type: (json['type'] ?? 'Campaign').toString(),
    className: (json['className'] ?? json['classSection'] ?? '').toString(),
    startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
    endDate: DateTime.tryParse((json['endDate'] ?? '').toString()),
    instructions: (json['instructions'] ?? '').toString(),
    imageUrl: (json['imageUrl'] ?? '').toString(),
    status: (json['status'] ?? 'Active').toString(),
    createdBy: (json['createdBy'] ?? '').toString(),
  );
}
