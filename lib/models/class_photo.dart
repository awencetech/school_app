/// Model for a class photo in the gallery.
class ClassPhoto {
  const ClassPhoto({
    required this.id,
    required this.groupId,
    required this.imageUrl,
    this.caption = '',
    this.uploadedAt,
    this.uploadedBy = '',
  });

  final String id;
  final String groupId;
  final String imageUrl;
  final String caption;
  final DateTime? uploadedAt;
  final String uploadedBy;

  factory ClassPhoto.fromJson(Map<String, dynamic> json) {
    return ClassPhoto(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      uploadedAt: _parseDate(json['uploadedAt'] ?? json['createdAt']),
      uploadedBy: json['uploadedBy'] as String? ?? '',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'imageUrl': imageUrl,
      'caption': caption,
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
      'uploadedBy': uploadedBy,
    };
  }

  ClassPhoto copyWith({
    String? id,
    String? groupId,
    String? imageUrl,
    String? caption,
    DateTime? uploadedAt,
    String? uploadedBy,
  }) {
    return ClassPhoto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }
}
