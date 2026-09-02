class GroupMessageComment {
  GroupMessageComment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.text,
    required this.createdAt,
    this.messageId = '',
    this.groupId = '',
    this.studentProfileImage,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String text;
  final DateTime createdAt;
  final String messageId;
  final String groupId;
  final String? studentProfileImage;

  static GroupMessageComment fromJson(Map<String, dynamic> json) {
    return GroupMessageComment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentId: (json['studentId'] ?? json['userId'] ?? '').toString(),
      studentName: (json['studentName'] ?? json['name'] ?? 'Student').toString(),
      text: (json['text'] ?? json['comment'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      messageId: (json['messageId'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      studentProfileImage: (json['studentProfileImage'] ?? json['profileImage'] ?? json['imageUrl'] ?? json['photoUrl'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'messageId': messageId,
    'groupId': groupId,
    'studentId': studentId,
    'studentName': studentName,
    'studentProfileImage': studentProfileImage,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

class GroupMessage {
  GroupMessage({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorRole,
    required this.senderName,
    this.senderEmail = '',
    required this.category,
    required this.approved,
    this.messageType = '',
    this.priority = 'Normal',
    this.audience = const [],
    this.approvedById = '',
    required this.createdAt,
    this.target = '',
    this.imageUrl,
    this.expiryDate,
    this.createdBy = '',
    this.commentsAllowed = true,
    this.likedBy = const [],
    this.comments = const [],
  });

  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final String content;
  final String authorId;
  final String authorRole;
  final String senderName;
  final String senderEmail;
  final String category;
  final bool approved;
  final String messageType;
  final String priority;
  final List<String> audience;
  final String approvedById;
  final DateTime createdAt;
  final String target;
  final String? imageUrl;
  final String? expiryDate;
  final String createdBy;
  final bool commentsAllowed;
  final List<String> likedBy;
  final List<GroupMessageComment> comments;

  GroupMessage copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? title,
    String? content,
    String? authorId,
    String? authorRole,
    String? senderName,
    String? senderEmail,
    String? category,
    bool? approved,
    String? messageType,
    String? priority,
    List<String>? audience,
    String? approvedById,
    DateTime? createdAt,
    String? target,
    String? imageUrl,
    String? expiryDate,
    String? createdBy,
    bool? commentsAllowed,
    List<String>? likedBy,
    List<GroupMessageComment>? comments,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorRole: authorRole ?? this.authorRole,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      category: category ?? this.category,
      approved: approved ?? this.approved,
      messageType: messageType ?? this.messageType,
      priority: priority ?? this.priority,
      audience: audience ?? this.audience,
      approvedById: approvedById ?? this.approvedById,
      createdAt: createdAt ?? this.createdAt,
      target: target ?? this.target,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      createdBy: createdBy ?? this.createdBy,
      commentsAllowed: commentsAllowed ?? this.commentsAllowed,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
    );
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    final commentsJson = json['comments'];
    final likedBy = json['likedBy'] is List
        ? (json['likedBy'] as List).map((x) => x.toString()).toList()
        : const <String>[];

    return GroupMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      groupName: (json['groupName'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      authorId: (json['authorId'] ?? '').toString(),
      authorRole: (json['authorRole'] ?? '').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      senderEmail: (json['senderEmail'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      messageType: (json['messageType'] ?? json['category'] ?? '').toString(),
      priority: (json['priority'] ?? 'Normal').toString(),
      audience: json['audience'] is List
          ? List<String>.from((json['audience'] as List).map((x) => x.toString()))
          : [],
      approved: json['approved'] == true,
      approvedById: (json['approvedById'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      target: (json['target'] ?? '').toString(),
      imageUrl: json['imageUrl'] as String?,
      expiryDate: (json['expiryDate'] ?? json['expiry'] ?? '').toString().isEmpty ? null : (json['expiryDate'] ?? json['expiry'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? json['authorId'] ?? '').toString(),
      commentsAllowed: json['commentsAllowed'] != false && json['allowComments'] != false,
      likedBy: likedBy,
      comments: commentsJson is List
          ? List<GroupMessageComment>.from(
              commentsJson.map((item) => GroupMessageComment.fromJson(Map<String, dynamic>.from(item as Map))),
            )
          : const <GroupMessageComment>[],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupId': groupId,
    'groupName': groupName,
    'title': title,
    'content': content,
    'message': content,
    'authorId': authorId,
    'authorRole': authorRole,
    'senderName': senderName,
    'senderEmail': senderEmail,
    'category': category,
    'messageType': messageType,
    'priority': priority,
    'audience': audience,
    'approved': approved,
    'approvedById': approvedById,
    'createdAt': createdAt.toIso8601String(),
    'target': target,
    'imageUrl': imageUrl,
    'expiryDate': expiryDate,
    'createdBy': createdBy,
    'commentsAllowed': commentsAllowed,
    'likedBy': likedBy,
    'comments': comments.map((comment) => comment.toJson()).toList(),
  };
}

