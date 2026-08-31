class NewsletterSection {
  const NewsletterSection({
    this.subHeading = '',
    this.content = '',
  });

  final String subHeading;
  final String content;

  factory NewsletterSection.fromJson(Map<String, dynamic> json) {
    return NewsletterSection(
      subHeading: (json['subHeading'] ?? json['heading'] ?? '').toString().trim(),
      content: (json['content'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'subHeading': subHeading,
    'content': content,
  };
}

class Newsletter {
  Newsletter({
    this.id,
    this.schoolId = 'default-school',
    required this.heading,
    this.imageUrl = '',
    required this.introduction,
    List<NewsletterSection>? sections,
    this.createdAt,
    this.updatedAt,
  }) : sections = sections ?? const <NewsletterSection>[];

  final String? id;
  final String schoolId;
  final String heading;
  final String imageUrl;
  final String introduction;
  final List<NewsletterSection> sections;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Newsletter.fromJson(Map<String, dynamic> json) {
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

    final sectionList = (json['sections'] is List)
        ? (json['sections'] as List)
            .whereType<Map>()
            .map((item) => NewsletterSection.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <NewsletterSection>[];

    return Newsletter(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      schoolId: json['schoolId']?.toString() ?? 'default-school',
      heading: (json['heading'] ?? '').toString().trim(),
      imageUrl: (json['imageUrl'] ?? '').toString().trim(),
      introduction: (json['introduction'] ?? '').toString().trim(),
      sections: sectionList,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'heading': heading,
    'imageUrl': imageUrl,
    'introduction': introduction,
    'sections': sections.map((section) => section.toJson()).toList(),
  };
}
