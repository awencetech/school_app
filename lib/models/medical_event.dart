class MedicalEvent {
  const MedicalEvent({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.description,
    required this.symptomReported,
    this.specialNeedsKnown = '',
    this.reportImage = '',
    required this.reportedBy,
    required this.lastModifiedBy,
    this.createdAt,
    this.updatedAt,
    this.lastModifiedAt,
  });

  final String? id;
  final String studentId;
  final String studentName;
  final String className;
  final String description;
  final String symptomReported;
  final String specialNeedsKnown;
  final String reportImage;
  final Map<String, dynamic> reportedBy;
  final Map<String, dynamic> lastModifiedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastModifiedAt;

  factory MedicalEvent.fromJson(Map<String, dynamic> json) {
    final observations = Map<String, dynamic>.from(json['firstObservations'] as Map? ?? {});
    return MedicalEvent(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      symptomReported: (observations['symptomReported'] ?? json['symptomReported'] ?? '').toString(),
      specialNeedsKnown: (observations['specialNeedsKnown'] ?? json['specialNeedsKnown'] ?? '').toString(),
      reportImage: json['reportImage']?.toString() ?? '',
      reportedBy: Map<String, dynamic>.from(json['reportedBy'] as Map? ?? {}),
      lastModifiedBy: Map<String, dynamic>.from(json['lastModifiedBy'] as Map? ?? {}),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      lastModifiedAt: _date(json['lastModifiedAt']),
    );
  }

  static DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'description': description,
        'firstObservations': {
          'symptomReported': symptomReported,
          'specialNeedsKnown': specialNeedsKnown,
        },
        'reportImage': reportImage,
        'reportedBy': reportedBy,
        'lastModifiedBy': lastModifiedBy,
      };

  String identity(Map<String, dynamic> value) {
    final name = value['name']?.toString().trim() ?? '';
    final userId = value['userId']?.toString().trim() ?? '';
    if (name.isNotEmpty && userId.isNotEmpty) return '$name ($userId)';
    return name.isNotEmpty ? name : userId;
  }

  String get reportedByLabel => identity(reportedBy);
  String get lastModifiedByLabel => identity(lastModifiedBy);
}
