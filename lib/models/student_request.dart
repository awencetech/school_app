class StudentRequest {
  const StudentRequest({
    required this.id,
    required this.studentUsername,
    required this.studentId,
    required this.studentName,
    required this.requestType,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String studentUsername;
  final String studentId;
  final String studentName;
  final String requestType;
  final String title;
  final String description;
  final DateTime? createdAt;
  final String status;

  factory StudentRequest.fromJson(Map<String, dynamic> json) {
    return StudentRequest(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentUsername: (json['studentUsername'] ?? json['username'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      requestType: (json['requestType'] ?? json['type'] ?? 'Other Student Request').toString(),
      title: (json['title'] ?? json['subject'] ?? '').toString(),
      description: (json['description'] ?? json['details'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      status: (json['status'] ?? 'Pending').toString(),
    );
  }
}