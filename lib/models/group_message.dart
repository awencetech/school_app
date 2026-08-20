class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorRole,
    required this.category,
    required this.approved,
    this.approvedById = '',
    required this.createdAt,
    this.target = '',
    this.senderName = '',
    this.groupName = '',
  });

  final String id;
  final String groupId;
  final String title;
  final String content;
  final String authorId;
  final String authorRole;
  final String category;
  final bool approved;
  final String approvedById;
  final DateTime createdAt;
  final String target;
  final String senderName;
  final String groupName;

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      authorId: (json['authorId'] ?? '').toString(),
      authorRole: (json['authorRole'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      approved: json['approved'] == true,
      approvedById: (json['approvedById'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      target: (json['target'] ?? '').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      groupName: (json['groupName'] ?? '').toString(),
    );
  }
}
