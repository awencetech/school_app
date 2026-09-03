class SchoolResource {
  const SchoolResource({
    this.id,
    required this.heading,
    required this.date,
    required this.resourceName,
    this.imageUrl = '',
    this.groupId = '',
    this.resourceType = '',
    this.fileName = '',
    this.fileSize,
    this.mimeType = '',
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String heading;
  final String date;
  final String resourceName;
  final String imageUrl;
  final String groupId;
  final String resourceType;
  final String fileName;
  final int? fileSize;
  final String mimeType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SchoolResource.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      final raw = value.toString();
      try {
        return DateTime.parse(raw);
      } catch (_) {
        try {
          return DateTime.parse(raw.replaceAll('/', '-'));
        } catch (_) {
          return null;
        }
      }
    }

    return SchoolResource(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      heading: (json['heading'] ?? '').toString().trim(),
      date: (json['date'] ?? '').toString().trim(),
      resourceName: (json['resourceName'] ?? '').toString().trim(),
      imageUrl: (json['imageUrl'] ?? '').toString().trim(),
      groupId: (json['groupId'] ?? '').toString().trim(),
      resourceType: (json['resourceType'] ?? '').toString().trim(),
      fileName: (json['fileName'] ?? '').toString().trim(),
      fileSize: int.tryParse((json['fileSize'] ?? '').toString()),
      mimeType: (json['mimeType'] ?? '').toString().trim(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'heading': heading,
    'date': date,
    'resourceName': resourceName,
    'imageUrl': imageUrl,
    'groupId': groupId,
    'resourceType': resourceType,
    'fileName': fileName,
    'fileSize': fileSize,
    'mimeType': mimeType,
  };
}
