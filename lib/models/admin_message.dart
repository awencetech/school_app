class AdminMessage {
  const AdminMessage({
    required this.id,
    required this.subject,
    required this.message,
    required this.messageType,
    required this.senderName,
    required this.createdAt,
    this.groupName = 'All Groups',
    this.recipientTypes = const [],
    this.targetType = 'all',
    this.targetClassId,
  });

  final String id;
  final String subject;
  final String message;
  final String messageType;
  final String senderName;
  final DateTime? createdAt;
  final String groupName;
  final List<String> recipientTypes;
  final String targetType;
  final String? targetClassId;

  factory AdminMessage.fromJson(Map<String, dynamic> json) {
    return AdminMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      subject: (json['subject'] ?? json['title'] ?? '').toString(),
      message: (json['message'] ?? json['content'] ?? '').toString(),
      messageType: (json['messageType'] ?? json['category'] ?? 'General')
          .toString(),
      senderName: (json['senderName'] ?? 'Admin').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      groupName: (json['groupName'] ?? 'All Groups').toString(),
      recipientTypes: (json['recipientTypes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      targetType: (json['targetType'] ?? 'all').toString(),
      targetClassId: json['targetClassId']?.toString(),
    );
  }
}
