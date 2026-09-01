/// Model for class news/announcements.
class ClassNews {
  const ClassNews({
    required this.id,
    required this.groupId,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.publishedAt,
    this.publishedBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String groupId;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime? publishedAt;
  final String publishedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClassNews.fromJson(Map<String, dynamic> json) {
    return ClassNews(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String? ?? '',
      publishedAt: _parseDate(json['publishedAt'] ?? json['createdAt']),
      publishedBy: json['publishedBy'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
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
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      'publishedBy': publishedBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  ClassNews copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? publishedAt,
    String? publishedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassNews(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
