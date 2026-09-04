class StaffResource {
  const StaffResource({
    this.id,
    required this.staffId,
    required this.staffName,
    required this.description,
    required this.link,
    required this.slipReportImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String staffId;
  final String staffName;
  final String description;
  final String link;
  final String slipReportImageUrl;
  final String? createdAt;
  final String? updatedAt;

  factory StaffResource.fromJson(Map<String, dynamic> json) => StaffResource(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        staffId: json['staffId']?.toString() ?? '',
        staffName: json['staffName']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        link: json['link']?.toString() ?? '',
        slipReportImageUrl: json['slipReportImageUrl']?.toString() ?? '',
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'staffId': staffId,
        'description': description,
        'link': link,
        'slipReportImageUrl': slipReportImageUrl,
      };
}
