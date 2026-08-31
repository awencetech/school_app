class HandbookSubSection {
  HandbookSubSection({
    this.id,
    required this.subHeading,
    required this.content,
    this.order = 0,
  });
  String? id;
  String subHeading;
  String content;
  int order;

  factory HandbookSubSection.fromJson(Map<String, dynamic> json) =>
      HandbookSubSection(
        id: json['id']?.toString(),
        subHeading: (json['subHeading'] ?? json['title'] ?? '').toString(),
        content: (json['content'] ?? '').toString(),
        order: int.tryParse('${json['order'] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'subHeading': subHeading,
    'content': content,
    'order': order,
  };
}

class HandbookSection {
  HandbookSection({
    this.id,
    required this.heading,
    this.imageUrl = '',
    required this.subSections,
    this.order = 0,
  });
  String? id;
  String heading;
  String imageUrl;
  List<HandbookSubSection> subSections;
  int order;

  factory HandbookSection.fromJson(Map<String, dynamic> json) {
    final nested = json['subSections'];
    final children = nested is List
        ? nested
              .map(
                (item) => HandbookSubSection.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : [
            HandbookSubSection(
              subHeading: (json['title'] ?? '').toString(),
              content: (json['content'] ?? '').toString(),
              order: 1,
            ),
          ];
    return HandbookSection(
      id: json['id']?.toString(),
      heading: (json['heading'] ?? json['title'] ?? '').toString(),
      imageUrl: _imageUrl(json['imageUrl']),
      subSections: children,
      order: int.tryParse('${json['order'] ?? 0}') ?? 0,
    );
  }

  static String _imageUrl(dynamic value) {
    final url = value?.toString().trim() ?? '';
    return url.startsWith('http://') || url.startsWith('https://') ? url : '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'heading': heading,
    'imageUrl': imageUrl,
    'subSections': subSections.map((item) => item.toJson()).toList(),
    'order': order,
  };
}

class StaffHandbook {
  StaffHandbook({
    this.id,
    required this.schoolId,
    required this.sections,
    this.updatedAt,
  });
  String? id;
  String schoolId;
  List<HandbookSection> sections;
  String? updatedAt;

  factory StaffHandbook.fromJson(Map<String, dynamic> json) => StaffHandbook(
    id: json['id']?.toString() ?? json['_id']?.toString(),
    schoolId: json['schoolId']?.toString() ?? 'default-school',
    sections: (json['sections'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              HandbookSection.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    updatedAt: json['updatedAt']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'sections': sections.map((item) => item.toJson()).toList(),
  };
}
